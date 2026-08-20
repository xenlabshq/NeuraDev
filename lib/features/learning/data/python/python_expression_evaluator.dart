/// `open()` ile döndürülen sahte dosya tanıtıcısı — gerçek bir dosya
/// açmaz, sadece `PyStatementExecutor`'ın sanal dosya deposundaki
/// (`files`) yolu ve modu takip eder.
class PyFileHandle {
  const PyFileHandle(this.path, this.mode);
  final String path;
  final String mode;
}

/// Python benzeri ifadeleri değerlendirir.
///
/// Desteklenen:
/// - sayılar (int, float)
/// - string ("...", '...') + .upper()/.lower()/.replace()
/// - değişkenler
/// - aritmetik: + - * /
/// - karşılaştırma: == != < > <= >=
/// - liste literal: [...] + indeksleme + .append() (atama tarafında)
/// - dict literal: {...} + indeksleme
/// - f-string: f"..."
/// - kullanıcı tanımlı fonksiyon çağrıları (enjekte edilen callback ile)
class PyExpressionEvaluator {
  PyExpressionEvaluator({
    required Map<String, dynamic> variables,
    required List<String> errors,
    required Map<String, String> files,
    dynamic Function(String name, List<String> argExprs)? callUserFunction,
  }) : _variables = variables,
       _errors = errors,
       _files = files,
       _callUserFunction = callUserFunction;

  final Map<String, dynamic> _variables;
  final List<String> _errors;
  final Map<String, String> _files;
  final dynamic Function(String name, List<String> argExprs)? _callUserFunction;

  dynamic eval(String expr) {
    expr = expr.trim();

    // f-string
    if (expr.startsWith('f"') || expr.startsWith("f'")) {
      return _evalFString(expr);
    }

    // String literal
    if ((expr.startsWith('"') && expr.endsWith('"')) ||
        (expr.startsWith("'") && expr.endsWith("'"))) {
      return expr
          .substring(1, expr.length - 1)
          .replaceAll(r'\\n', '\n')
          .replaceAll(r'\\t', '\t')
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\t', '\t');
    }

    // Liste literal
    if (expr.startsWith('[') && expr.endsWith(']')) {
      final inner = expr.substring(1, expr.length - 1).trim();
      if (inner.isEmpty) return <dynamic>[];
      return splitArgs(inner).map((e) => eval(e.trim())).toList();
    }

    // Dict literal: {"anahtar": deger, ...}
    if (expr.startsWith('{') && expr.endsWith('}')) {
      final inner = expr.substring(1, expr.length - 1).trim();
      final result = <dynamic, dynamic>{};
      if (inner.isEmpty) return result;
      for (final pair in splitArgs(inner)) {
        final colonIdx = _findTopLevelColon(pair);
        if (colonIdx < 0) continue;
        final key = eval(pair.substring(0, colonIdx).trim());
        final value = eval(pair.substring(colonIdx + 1).trim());
        result[key] = value;
      }
      return result;
    }

    // Boolean / None
    if (expr == 'True') return true;
    if (expr == 'False') return false;
    if (expr == 'None') return null;

    // Sayı
    final asInt = int.tryParse(expr);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(expr);
    if (asDouble != null) return asDouble;

    // Değişken
    if (_variables.containsKey(expr)) return _variables[expr];

    // İndeksleme: base[index] — liste veya dict.
    final indexMatch = _matchPattern(expr, RegExp(r'^(\w+)\[(.+)\]$'));
    if (indexMatch != null) {
      return _evalIndex(indexMatch.group(1)!, indexMatch.group(2)!);
    }

    // Karşılaştırma operatörü içeriyor mu?
    for (final op in ['==', '!=', '<=', '>=', '<', '>']) {
      final idx = _findTopLevelOp(expr, op);
      if (idx > 0) {
        final left = eval(expr.substring(0, idx));
        final right = eval(expr.substring(idx + op.length));
        return _compare(left, op, right);
      }
    }

    // Aritmetik
    for (final op in ['+', '-', '*', '/']) {
      final idx = _findTopLevelOp(expr, op);
      if (idx <= 0) continue;
      final left = eval(expr.substring(0, idx));
      final right = eval(expr.substring(idx + op.length));
      if (op == '+' && (left is String || right is String)) {
        return stringify(left) + stringify(right);
      }
      return _arith(left, op, right);
    }

    // base.method(args) çağrısı — string/dosya metotları.
    final methodMatch = _matchPattern(
      expr,
      RegExp(r'^(\w+)\.(\w+)\s*\(\s*(.*)\s*\)$'),
    );
    if (methodMatch != null) {
      return _evalMethodCall(
        methodMatch.group(1)!,
        methodMatch.group(2)!,
        methodMatch.group(3)!,
      );
    }

    // func(...) çağrısı
    final callMatch = _matchPattern(expr, RegExp(r'^(\w+)\s*\(\s*(.*)\s*\)$'));
    if (callMatch != null) {
      final fname = callMatch.group(1)!;
      final argsStr = callMatch.group(2)!;
      if (fname == 'len') {
        final args = splitArgs(argsStr);
        if (args.isNotEmpty) {
          final v = eval(args[0].trim());
          if (v is List) return v.length;
          if (v is String) return v.length;
        }
      }
      if (fname == 'print') {
        // print expression olarak kullanılırsa
        final args = splitArgs(argsStr);
        final parts = args.map((a) => stringify(eval(a.trim()))).toList();
        return parts.join(' ');
      }
      if (fname == 'range') {
        // range handled in for, return empty here
        return <dynamic>[];
      }
      if (fname == 'open') {
        final args = splitArgs(argsStr).map((a) => eval(a.trim())).toList();
        final path = args.isNotEmpty ? stringify(args[0]) : '';
        final mode = args.length > 1 ? stringify(args[1]) : 'r';
        if (mode.contains('w')) {
          // "w" modu dosyayı hemen (write çağrılmadan) sıfırlar —
          // gerçek Python'daki gibi.
          _files[path] = '';
        }
        return PyFileHandle(path, mode);
      }
      if (fname == 'input' || fname == 'str' || fname == 'int') {
        return null;
      }
      // Kullanıcı tanımlı fonksiyon.
      if (_callUserFunction != null) {
        final args = argsStr.trim().isEmpty
            ? const <String>[]
            : splitArgs(argsStr);
        return _callUserFunction(fname, args);
      }
    }

    // Bilinmeyen
    return null;
  }

  dynamic _evalIndex(String baseName, String indexExpr) {
    if (!_variables.containsKey(baseName)) return null;
    final base = _variables[baseName];
    final indexVal = eval(indexExpr);
    if (base is List) {
      if (indexVal is! int || indexVal < 0 || indexVal >= base.length) {
        _errors.add('IndexError: liste sınırının dışında');
        return null;
      }
      return base[indexVal];
    }
    if (base is Map) {
      if (!base.containsKey(indexVal)) {
        _errors.add("KeyError: '$indexVal'");
        return null;
      }
      return base[indexVal];
    }
    return null;
  }

  dynamic _evalMethodCall(String baseName, String methodName, String argsStr) {
    final base = _variables[baseName];
    final args = argsStr.trim().isEmpty
        ? const <dynamic>[]
        : splitArgs(argsStr).map((a) => eval(a.trim())).toList();

    if (base is String) {
      switch (methodName) {
        case 'upper':
          return base.toUpperCase();
        case 'lower':
          return base.toLowerCase();
        case 'strip':
          return base.trim();
        case 'replace':
          if (args.length == 2) {
            return base.replaceAll(stringify(args[0]), stringify(args[1]));
          }
      }
    }
    if (base is PyFileHandle) {
      switch (methodName) {
        case 'read':
          return _files[base.path] ?? '';
        case 'close':
          return null;
      }
    }
    return null;
  }

  List<dynamic> evalIterable(String expr) {
    final v = eval(expr);
    if (v is List) return v;
    if (v is String) return v.split('');
    return const [];
  }

  bool isTruthy(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.isNotEmpty;
    if (v is List) return v.isNotEmpty;
    return true;
  }

  /// `print`/`str()` tarzı gösterim — string'ler tırnaksız yazılır.
  String stringify(dynamic v) {
    if (v == null) return 'None';
    if (v is bool) return v ? 'True' : 'False';
    if (v is String) return v;
    if (v is double) return v.toString();
    if (v is List) {
      final items = v.map(_repr).join(', ');
      return '[$items]';
    }
    if (v is Map) {
      final entries = v.entries
          .map((e) => '${_repr(e.key)}: ${_repr(e.value)}')
          .join(', ');
      return '{$entries}';
    }
    return v.toString();
  }

  /// `repr()` tarzı gösterim — liste/dict İÇİNDEKİ elemanlar için;
  /// string'ler Python'daki gibi tek tırnakla gösterilir.
  String _repr(dynamic v) {
    if (v is String) return "'$v'";
    return stringify(v);
  }

  /// Virgülle ayrılmış argümanları (parantez/köşeli parantez ve string
  /// içindekileri yoksayarak) böler.
  List<String> splitArgs(String s) {
    final result = <String>[];
    var depth = 0;
    var inStr = false;
    String? q;
    var start = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (inStr) {
        if (c == q && (i == 0 || s[i - 1] != r'\')) inStr = false;
        continue;
      }
      if (c == '"' || c == "'") {
        inStr = true;
        q = c;
        continue;
      }
      if (c == '(' || c == '[') depth++;
      if (c == ')' || c == ']') depth--;
      if (c == ',' && depth == 0) {
        result.add(s.substring(start, i));
        start = i + 1;
      }
    }
    result.add(s.substring(start));
    return result;
  }

  String _evalFString(String expr) {
    final inner = expr.substring(2, expr.length - 1);
    final result = StringBuffer();
    var i = 0;
    while (i < inner.length) {
      final c = inner[i];
      if (c == '{') {
        final close = inner.indexOf('}', i);
        if (close < 0) {
          result.write(inner.substring(i));
          break;
        }
        final varExpr = inner.substring(i + 1, close);
        final v = eval(varExpr.trim());
        result.write(stringify(v));
        i = close + 1;
      } else {
        result.write(c);
        i++;
      }
    }
    return result.toString();
  }

  int _findTopLevelOp(String expr, String op) {
    var paren = 0;
    var bracket = 0;
    var inStr = false;
    String? strQ;
    for (var i = 0; i < expr.length; i++) {
      final c = expr[i];
      if (inStr) {
        if (c == strQ && (i == 0 || expr[i - 1] != r'\')) inStr = false;
        continue;
      }
      if (c == '"' || c == "'") {
        inStr = true;
        strQ = c;
        continue;
      }
      if (c == '(') paren++;
      if (c == ')') paren--;
      if (c == '[') bracket++;
      if (c == ']') bracket--;
      if (paren == 0 && bracket == 0 && i + op.length <= expr.length) {
        if (expr.substring(i, i + op.length) == op) {
          // Aritmetik için soldaki operand boş veya operatör olmamalı
          if (op == '-' || op == '+') {
            if (i == 0) continue;
            final prev = expr[i - 1];
            if ('+-*/(<[,='.contains(prev)) continue;
          }
          return i;
        }
      }
    }
    return -1;
  }

  int _findTopLevelColon(String s) {
    var inStr = false;
    String? q;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (inStr) {
        if (c == q && (i == 0 || s[i - 1] != r'\')) inStr = false;
        continue;
      }
      if (c == '"' || c == "'") {
        inStr = true;
        q = c;
        continue;
      }
      if (c == ':') return i;
    }
    return -1;
  }

  dynamic _arith(dynamic a, String op, dynamic b) {
    if (a is num && b is num) {
      switch (op) {
        case '+':
          return a + b;
        case '-':
          return a - b;
        case '*':
          return a * b;
        case '/':
          if (b == 0) {
            _errors.add('ZeroDivisionError: sıfıra bölme');
            return null;
          }
          return a / b;
      }
    }
    return null;
  }

  bool _compare(dynamic a, String op, dynamic b) {
    int cmp;
    if (a is num && b is num) {
      cmp = a.compareTo(b);
    } else {
      cmp = stringify(a).compareTo(stringify(b));
    }
    switch (op) {
      case '==':
        return a == b;
      case '!=':
        return a != b;
      case '<':
        return cmp < 0;
      case '>':
        return cmp > 0;
      case '<=':
        return cmp <= 0;
      case '>=':
        return cmp >= 0;
    }
    return false;
  }

  RegExpMatch? _matchPattern(String s, RegExp re) {
    final m = re.firstMatch(s);
    if (m == null) return null;
    if (m.start != 0) return null;
    return m;
  }
}
