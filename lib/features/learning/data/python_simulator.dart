import '../domain/entities/error_hint.dart';

/// Basit Python yorumlayıcı simülasyonu.
/// Gerçek Python çalıştırmaz — öğretici senaryoları karşılayacak kadar
/// yeterli, güvenli ve tahmin edilebilir davranış sağlar.
class PythonSimulator {
  final List<String> _output = [];
  final Map<String, dynamic> _variables = {};
  final List<String> _errors = [];
  int _loopCount = 0;
  static const int _maxLoopIterations = 200;
  static const int _maxOutputLines = 100;

  List<String> get output => List.unmodifiable(_output);
  List<String> get errors => List.unmodifiable(_errors);
  bool get hasError => _errors.isNotEmpty;

  /// Python kodunu çalıştırır, çıktıyı ve hataları döner.
  PythonSimulatorResult run(String code, {String? expectedOutput}) {
    _output.clear();
    _errors.clear();
    _variables.clear();
    _loopCount = 0;

    try {
      _execute(code);
    } catch (e) {
      _errors.add(e.toString());
    }

    // Hata varsa veya çıktı beklenenle eşleşmiyorsa akıllı ipucu üret.
    ErrorHint? hint;
    if (hasError ||
        (expectedOutput != null &&
            expectedOutput.isNotEmpty &&
            _output.join('\n').trim() != expectedOutput.trim())) {
      hint = ErrorAnalyzer.analyze(
        errors: _errors,
        output: _output,
        expectedOutput: expectedOutput,
        sourceCode: code,
      );
    }

    if (_output.length > _maxOutputLines) {
      final truncated = _output.sublist(0, _maxOutputLines);
      truncated.add('... (çıktı kırpıldı)');
      return PythonSimulatorResult(
        output: truncated,
        errors: List.from(_errors),
        success: !hasError,
        hint: hint,
      );
    }

    return PythonSimulatorResult(
      output: List.from(_output),
      errors: List.from(_errors),
      success: !hasError,
      hint: hint,
    );
  }

  void _execute(String code) {
    final lines = _prepareLines(code);
    _executeBlock(lines, 0, lines.length, 0);
  }

  /// Yorum satırlarını ve boş satırları atlar.
  List<_PyLine> _prepareLines(String code) {
    return code
        .split('\n')
        .asMap()
        .entries
        .map((e) => _PyLine(
              number: e.key + 1,
              raw: e.value,
              indent: _countIndent(e.value),
              content: _stripComment(e.value).trim(),
            ))
        .where((l) => l.content.isNotEmpty)
        .toList();
  }

  int _countIndent(String s) {
    var n = 0;
    for (final c in s.split('')) {
      if (c == ' ') {
        n++;
      } else if (c == '\t') {
        n += 4;
      } else {
        break;
      }
    }
    return n;
  }

  String _stripComment(String s) {
    final hashIdx = s.indexOf('#');
    if (hashIdx < 0) return s;
    // Tırnak içindeki # karakterlerini yoksay
    var inStr = false;
    var q = '';
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (i == hashIdx && !inStr) return s.substring(0, i);
      if (c == '"' || c == "'") {
        if (!inStr) {
          inStr = true;
          q = c;
        } else if (c == q) {
          inStr = false;
        }
      }
    }
    return s;
  }

  void _executeBlock(
      List<_PyLine> lines, int startLine, int endLine, int baseIndent) {
    var i = startLine;
    while (i < endLine) {
      final line = lines[i];
      final relIndent = line.indent - baseIndent;

      if (relIndent < 0) {
        // Bloğun sonu, geri dön
        return;
      }
      if (relIndent > 0) {
        // Beklenmeyen girinti, atla
        i++;
        continue;
      }

      final c = line.content;

      // for
      if (_startsWith(c, 'for ')) {
        i = _handleFor(lines, i, endLine, baseIndent);
        continue;
      }
      // while
      if (_startsWith(c, 'while ')) {
        i = _handleWhile(lines, i, endLine, baseIndent);
        continue;
      }
      // if
      if (_startsWith(c, 'if ') || _startsWith(c, 'if(')) {
        i = _handleIf(lines, i, endLine, baseIndent);
        continue;
      }

      // Tek satırlık ifade
      _evalLine(c);
      i++;
    }
  }

  int _handleFor(
      List<_PyLine> lines, int startIdx, int endLine, int baseIndent) {
    final line = lines[startIdx];
    final c = line.content;

    // for i in range(N):  veya  for x in liste:
    final match = _matchPattern(
      c,
      RegExp(r'for\s+(\w+)\s+in\s+range\s*\(\s*([^)]+)\s*\)\s*:'),
    );
    if (match != null) {
      final varName = match.group(1)!;
      final args = match.group(2)!.split(',').map((e) => e.trim()).toList();
      final start = args.length == 1
          ? 0
          : int.tryParse(_evalExpr(args[0]).toString()) ?? 0;
      final end = int.tryParse(_evalExpr(args.length == 1 ? args[0] : args[1]).toString()) ?? 0;

      final bodyStart = startIdx + 1;
      final bodyEnd = _findBlockEnd(lines, bodyStart, endLine, line.indent);
      _loopCount = 0;
      for (var v = start; v < end; v++) {
        if (++_loopCount > _maxLoopIterations) {
          _errors.add('RuntimeError: Çok fazla döngü iterasyonu (limit: $_maxLoopIterations)');
          return bodyEnd;
        }
        _variables[varName] = v;
        _executeBlock(lines, bodyStart, bodyEnd, line.indent);
        if (hasError) return bodyEnd;
      }
      return bodyEnd;
    }

    // for x in liste:
    final listMatch = _matchPattern(
      c,
      RegExp(r'for\s+(\w+)\s+in\s+(.+):'),
    );
    if (listMatch != null) {
      final varName = listMatch.group(1)!;
      final listExpr = listMatch.group(2)!;
      final iterable = _evalIterable(listExpr);
      final bodyStart = startIdx + 1;
      final bodyEnd = _findBlockEnd(lines, bodyStart, endLine, line.indent);
      _loopCount = 0;
      for (final item in iterable) {
        if (++_loopCount > _maxLoopIterations) {
          _errors.add('RuntimeError: Çok fazla döngü iterasyonu');
          return bodyEnd;
        }
        _variables[varName] = item;
        _executeBlock(lines, bodyStart, bodyEnd, line.indent);
        if (hasError) return bodyEnd;
      }
      return bodyEnd;
    }

    _errors.add('SyntaxError: Geçersiz for döngüsü (satır ${line.number})');
    return startIdx + 1;
  }

  int _handleWhile(
      List<_PyLine> lines, int startIdx, int endLine, int baseIndent) {
    final line = lines[startIdx];
    final c = line.content;
    final match = _matchPattern(c, RegExp(r'while\s+(.+):'));
    if (match == null) {
      _errors.add('SyntaxError: Geçersiz while (satır ${line.number})');
      return startIdx + 1;
    }
    final condExpr = match.group(1)!;
    final bodyStart = startIdx + 1;
    final bodyEnd = _findBlockEnd(lines, bodyStart, endLine, line.indent);
    _loopCount = 0;
    while (_isTruthy(_evalExpr(condExpr))) {
      if (++_loopCount > _maxLoopIterations) {
        _errors.add('RuntimeError: Sonsuz döngü tespit edildi');
        return bodyEnd;
      }
      _executeBlock(lines, bodyStart, bodyEnd, line.indent);
      if (hasError) return bodyEnd;
    }
    return bodyEnd;
  }

  int _handleIf(
      List<_PyLine> lines, int startIdx, int endLine, int baseIndent) {
    final line = lines[startIdx];
    final c = line.content;
    final match = _matchPattern(c, RegExp(r'if\s+(.+):'));
    if (match == null) {
      _errors.add('SyntaxError: Geçersiz if (satır ${line.number})');
      return startIdx + 1;
    }
    final condExpr = match.group(1)!;
    final bodyStart = startIdx + 1;
    final bodyEnd = _findBlockEnd(lines, bodyStart, endLine, line.indent);

    if (_isTruthy(_evalExpr(condExpr))) {
      _executeBlock(lines, bodyStart, bodyEnd, line.indent);
      return bodyEnd;
    }

    // elif / else zincirini takip et
    var i = bodyEnd;
    while (i < endLine) {
      final next = lines[i];
      final relIndent = next.indent - baseIndent;
      if (relIndent != 0) break;
      final nc = next.content;
      if (_startsWith(nc, 'elif ')) {
        final em = _matchPattern(nc, RegExp(r'elif\s+(.+):'));
        if (em == null) {
          i++;
          continue;
        }
        final eStart = i + 1;
        final eEnd = _findBlockEnd(lines, eStart, endLine, next.indent);
        if (_isTruthy(_evalExpr(em.group(1)!))) {
          _executeBlock(lines, eStart, eEnd, next.indent);
          return eEnd;
        }
        i = eEnd;
      } else if (_startsWith(nc, 'else:')) {
        final eStart = i + 1;
        final eEnd = _findBlockEnd(lines, eStart, endLine, next.indent);
        _executeBlock(lines, eStart, eEnd, next.indent);
        return eEnd;
      } else {
        break;
      }
    }
    return i;
  }

  int _findBlockEnd(
      List<_PyLine> lines, int start, int endLine, int parentIndent) {
    var i = start;
    while (i < endLine) {
      if (lines[i].indent <= parentIndent) {
        return i;
      }
      i++;
    }
    return endLine;
  }

  void _evalLine(String c) {
    // print(...)
    final printMatch = _matchPattern(c, RegExp(r'^print\s*\(\s*(.*)\s*\)\s*$'));
    if (printMatch != null) {
      final argsStr = printMatch.group(1)!;
      final args = _splitArgs(argsStr);
      final parts = <String>[];
      for (final arg in args) {
        final v = _evalExpr(arg.trim());
        parts.add(_stringify(v));
      }
      _output.add(parts.join(' '));
      return;
    }

    // open(...) (kullanıcı dosya yazma/okuma simüle ediyoruz)
    if (_startsWith(c, 'open(')) {
      // Basitçe atla, çıktı üretmiyor
      return;
    }

    // dosya.write(...) / dosya.close() — no-op
    if (RegExp(r'^\w+\.(write|close|read)\(').hasMatch(c)) {
      return;
    }

    // Atama: x = expr
    final assignMatch = _matchPattern(c, RegExp(r'^(\w+)\s*=\s*(.+)$'));
    if (assignMatch != null) {
      final name = assignMatch.group(1)!;
      final expr = assignMatch.group(2)!;
      _variables[name] = _evalExpr(expr);
      return;
    }

    // Tanımsız
    _errors.add('NameError: tanınmayan ifade: $c');
  }

  /// İfadeyi değerlendir ve sonuç döner.
  /// Desteklenen:
  /// - sayılar (int, float)
  /// - string ("...", '...')
  /// - değişkenler
  /// - aritmetik: + - * /
  /// - karşılaştırma: == != < > <= >=
  /// - liste literal: [...]
  /// - f-string: f"..."
  dynamic _evalExpr(String expr) {
    expr = expr.trim();

    // f-string
    if (_startsWith(expr, 'f"') || _startsWith(expr, "f'")) {
      return _evalFString(expr);
    }

    // String literal
    if ((expr.startsWith('"') && expr.endsWith('"')) ||
        (expr.startsWith("'") && expr.endsWith("'"))) {
      return expr.substring(1, expr.length - 1)
          .replaceAll(r'\\n', '\n')
          .replaceAll(r'\\t', '\t')
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\t', '\t');
    }

    // Liste literal
    if (expr.startsWith('[') && expr.endsWith(']')) {
      final inner = expr.substring(1, expr.length - 1).trim();
      if (inner.isEmpty) return <dynamic>[];
      return _splitArgs(inner).map((e) => _evalExpr(e.trim())).toList();
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

    // Karşılaştırma operatörü içeriyor mu?
    for (final op in ['==', '!=', '<=', '>=', '<', '>']) {
      final idx = _findTopLevelOp(expr, op);
      if (idx > 0) {
        final left = _evalExpr(expr.substring(0, idx));
        final right = _evalExpr(expr.substring(idx + op.length));
        return _compare(left, op, right);
      }
    }

    // Aritmetik
    for (final op in ['+', '-', '*', '/']) {
      final idx = _findTopLevelOp(expr, op);
      if (idx > 0 && !(op == '+' || op == '-')) {
        // - ve unary + hariç
        final left = _evalExpr(expr.substring(0, idx));
        final right = _evalExpr(expr.substring(idx + op.length));
        return _arith(left, op, right);
      }
      if (idx > 0 && op == '+' && _isStringConcat(expr, idx)) {
        final left = _evalExpr(expr.substring(0, idx));
        final right = _evalExpr(expr.substring(idx + 1));
        if (left is String || right is String) {
          return _stringify(left) + _stringify(right);
        }
        return _arith(left, '+', right);
      }
    }

    // func(...) çağrısı
    final callMatch = _matchPattern(expr, RegExp(r'^(\w+)\s*\(\s*(.*)\s*\)$'));
    if (callMatch != null) {
      final fname = callMatch.group(1)!;
      final argsStr = callMatch.group(2)!;
      if (fname == 'len') {
        final args = _splitArgs(argsStr);
        if (args.isNotEmpty) {
          final v = _evalExpr(args[0].trim());
          if (v is List) return v.length;
          if (v is String) return v.length;
        }
      }
      if (fname == 'print') {
        // print expression olarak kullanılırsa
        final args = _splitArgs(argsStr);
        final parts = args.map((a) => _stringify(_evalExpr(a.trim()))).toList();
        return parts.join(' ');
      }
      if (fname == 'range') {
        // range handled in for, return empty here
        return [];
      }
      if (fname == 'open' || fname == 'input' || fname == 'str' || fname == 'int') {
        return null;
      }
    }

    // Bilinmeyen
    return null;
  }

  bool _isStringConcat(String expr, int plusIdx) {
    // +'dan önce veya sonra string var mı?
    final left = expr.substring(0, plusIdx).trim();
    final right = expr.substring(plusIdx + 1).trim();
    if (left.startsWith('"') || left.startsWith("'") || left.startsWith('f"')) {
      return true;
    }
    if (right.startsWith('"') || right.startsWith("'") || right.startsWith('f"')) {
      return true;
    }
    if (_variables.containsKey(left) && _variables[left] is String) return true;
    if (_variables.containsKey(right) && _variables[right] is String) return true;
    return false;
  }

  String _evalFString(String expr) {
    final quote = expr[1]; // f"  veya f'
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
        final v = _evalExpr(varExpr.trim());
        result.write(_stringify(v));
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
      cmp = _stringify(a).compareTo(_stringify(b));
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

  bool _isTruthy(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.isNotEmpty;
    if (v is List) return v.isNotEmpty;
    return true;
  }

  String _stringify(dynamic v) {
    if (v == null) return 'None';
    if (v is bool) return v ? 'True' : 'False';
    if (v is String) return v;
    if (v is double) {
      // Python: tamsayı gibi yazılabilir
      if (v == v.truncate()) return v.toInt().toString();
      return v.toString();
    }
    if (v is List) {
      final items = v.map(_stringify).join(', ');
      return '[$items]';
    }
    if (v is Map) {
      final entries =
          v.entries.map((e) => "'${e.key}': ${_stringify(e.value)}").join(', ');
      return '{$entries}';
    }
    return v.toString();
  }

  List<dynamic> _evalIterable(String expr) {
    final v = _evalExpr(expr);
    if (v is List) return v;
    if (v is String) return v.split('');
    return const [];
  }

  List<String> _splitArgs(String s) {
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

  bool _startsWith(String s, String prefix) {
    if (s.length < prefix.length) return false;
    return s.substring(0, prefix.length) == prefix;
  }

  RegExpMatch? _matchPattern(String s, RegExp re) {
    final m = re.firstMatch(s);
    if (m == null) return null;
    if (m.start != 0) return null;
    return m;
  }
}

class _PyLine {
  _PyLine({
    required this.number,
    required this.raw,
    required this.indent,
    required this.content,
  });
  final int number;
  final String raw;
  final int indent;
  final String content;
}

class PythonSimulatorResult {
  const PythonSimulatorResult({
    required this.output,
    required this.errors,
    required this.success,
    this.hint,
  });
  final List<String> output;
  final List<String> errors;
  final bool success;

  /// Akıllı hata analizi sonucu — kullanıcıya öğretmen gibi ipucu verir.
  final ErrorHint? hint;

  /// Çıktıyı tek string olarak (her satır newline ile).
  String get combinedOutput => output.join('\n');
}
