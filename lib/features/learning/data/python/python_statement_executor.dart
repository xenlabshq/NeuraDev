import '../../domain/entities/execution_step.dart';
import 'py_line.dart';
import 'python_expression_evaluator.dart';

/// Kullanıcı tanımlı bir fonksiyonun (def) kayıtlı hâli — parametreleri
/// ve gövdesinin `lines` içindeki satır aralığını tutar.
class _PyFunction {
  _PyFunction({
    required this.params,
    required this.bodyStart,
    required this.bodyEnd,
    required this.bodyIndent,
  });
  final List<String> params;
  final int bodyStart;
  final int bodyEnd;
  final int bodyIndent;
}

/// Satır bloklarını (for/while/if/def dahil kontrol akışı) yürütür.
class PyStatementExecutor {
  PyStatementExecutor({
    required PyExpressionEvaluator evaluator,
    required List<String> output,
    required Map<String, dynamic> variables,
    required List<String> errors,
    required List<ExecutionStep> steps,
    required Map<String, String> files,
    int maxLoopIterations = 200,
    int maxSteps = 300,
  }) : _evaluator = evaluator,
       _output = output,
       _variables = variables,
       _errors = errors,
       _steps = steps,
       _files = files,
       _maxLoopIterations = maxLoopIterations,
       _maxSteps = maxSteps;

  final PyExpressionEvaluator _evaluator;
  final List<String> _output;
  final Map<String, dynamic> _variables;
  final List<String> _errors;
  final List<ExecutionStep> _steps;
  final Map<String, String> _files;
  final int _maxLoopIterations;
  final int _maxSteps;
  int _loopCount = 0;

  final Map<String, _PyFunction> _functions = {};
  List<PyLine>? _lines;
  bool _hasReturned = false;
  dynamic _returnValue;

  bool get _hasError => _errors.isNotEmpty;

  void executeBlock(
    List<PyLine> lines,
    int startLine,
    int endLine,
    int baseIndent,
  ) {
    _lines = lines;
    var i = startLine;
    while (i < endLine) {
      if (_hasReturned) return;
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
      if (c.startsWith('for ')) {
        i = _handleFor(lines, i, endLine, baseIndent);
        continue;
      }
      // while
      if (c.startsWith('while ')) {
        i = _handleWhile(lines, i, endLine, baseIndent);
        continue;
      }
      // if
      if (c.startsWith('if ') || c.startsWith('if(')) {
        i = _handleIf(lines, i, endLine, baseIndent);
        continue;
      }
      // def
      if (c.startsWith('def ')) {
        i = _handleDef(lines, i, endLine, baseIndent);
        continue;
      }

      // Tek satırlık ifade
      _evalLine(line);
      i++;
    }
  }

  void _recordStep(PyLine line, {String? printedOutput}) {
    if (_steps.length >= _maxSteps) return;
    _steps.add(
      ExecutionStep(
        line: line.number,
        sourceLine: line.content,
        variables: Map<String, dynamic>.of(_variables),
        printedOutput: printedOutput,
      ),
    );
  }

  /// Bir blok gövdesini (for/while/if içeriği) yürütür.
  /// `baseIndent` gövdenin KENDİ girinti seviyesi olmalı (üst
  /// for/while/if satırının girintisi değil) — aksi halde
  /// [executeBlock]'taki `relIndent` hesaplaması her satırı
  /// "beklenmeyen girinti" sayıp atlar.
  void _executeBody(List<PyLine> lines, int bodyStart, int bodyEnd) {
    if (bodyStart >= bodyEnd) return;
    executeBlock(lines, bodyStart, bodyEnd, lines[bodyStart].indent);
  }

  int _handleDef(
    List<PyLine> lines,
    int startIdx,
    int endLine,
    int baseIndent,
  ) {
    final line = lines[startIdx];
    final c = line.content;
    final match = _matchPattern(
      c,
      RegExp(r'def\s+(\w+)\s*\(\s*(.*)\s*\)\s*:'),
    );
    if (match == null) {
      _errors.add(
        'SyntaxError: Geçersiz fonksiyon tanımı (satır ${line.number})',
      );
      return startIdx + 1;
    }
    final name = match.group(1)!;
    final paramsStr = match.group(2)!.trim();
    final params = paramsStr.isEmpty
        ? const <String>[]
        : paramsStr.split(',').map((p) => p.trim()).toList();
    final bodyStart = startIdx + 1;
    final bodyEnd = _findBlockEnd(lines, bodyStart, endLine, line.indent);
    _functions[name] = _PyFunction(
      params: params,
      bodyStart: bodyStart,
      bodyEnd: bodyEnd,
      bodyIndent: bodyStart < bodyEnd ? lines[bodyStart].indent : line.indent,
    );
    return bodyEnd;
  }

  /// Kullanıcı tanımlı bir fonksiyonu çağırır. `PyExpressionEvaluator`'a
  /// callback olarak enjekte edilir (ifade içinde `kare(4)` gibi
  /// kullanılabilmesi için) ve bağımsız çağrı ifadeleri için de
  /// [_evalLine] tarafından doğrudan kullanılır.
  ///
  /// NOT: Gerçek Python'daki gibi fonksiyon-yerel scope YOK — basit
  /// simülatör tasarımı gereği parametreler global `_variables`'a
  /// yazılır. Bu, öğretici senaryolarımızdaki (parametre isimleri
  /// dışarıdaki değişkenlerle çakışmayan) dersler için yeterlidir.
  dynamic callUserFunction(String name, List<String> argExprs) {
    final fn = _functions[name];
    final lines = _lines;
    if (fn == null || lines == null) return null;

    final argValues = argExprs.map((a) => _evaluator.eval(a.trim())).toList();
    for (var i = 0; i < fn.params.length; i++) {
      _variables[fn.params[i]] = i < argValues.length ? argValues[i] : null;
    }

    final savedReturnValue = _returnValue;
    final savedHasReturned = _hasReturned;
    _returnValue = null;
    _hasReturned = false;

    if (fn.bodyStart < fn.bodyEnd) {
      executeBlock(lines, fn.bodyStart, fn.bodyEnd, fn.bodyIndent);
    }

    final result = _returnValue;
    _returnValue = savedReturnValue;
    _hasReturned = savedHasReturned;
    return result;
  }

  int _handleFor(
    List<PyLine> lines,
    int startIdx,
    int endLine,
    int baseIndent,
  ) {
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
          : int.tryParse(_evaluator.eval(args[0]).toString()) ?? 0;
      final end =
          int.tryParse(
            _evaluator.eval(args.length == 1 ? args[0] : args[1]).toString(),
          ) ??
          0;

      final bodyStart = startIdx + 1;
      final bodyEnd = _findBlockEnd(lines, bodyStart, endLine, line.indent);
      _loopCount = 0;
      for (var v = start; v < end; v++) {
        if (++_loopCount > _maxLoopIterations) {
          _errors.add(
            'RuntimeError: Çok fazla döngü iterasyonu (limit: $_maxLoopIterations)',
          );
          return bodyEnd;
        }
        _variables[varName] = v;
        _executeBody(lines, bodyStart, bodyEnd);
        if (_hasError) return bodyEnd;
      }
      return bodyEnd;
    }

    // for x in liste:
    final listMatch = _matchPattern(c, RegExp(r'for\s+(\w+)\s+in\s+(.+):'));
    if (listMatch != null) {
      final varName = listMatch.group(1)!;
      final listExpr = listMatch.group(2)!;
      final iterable = _evaluator.evalIterable(listExpr);
      final bodyStart = startIdx + 1;
      final bodyEnd = _findBlockEnd(lines, bodyStart, endLine, line.indent);
      _loopCount = 0;
      for (final item in iterable) {
        if (++_loopCount > _maxLoopIterations) {
          _errors.add('RuntimeError: Çok fazla döngü iterasyonu');
          return bodyEnd;
        }
        _variables[varName] = item;
        _executeBody(lines, bodyStart, bodyEnd);
        if (_hasError) return bodyEnd;
      }
      return bodyEnd;
    }

    _errors.add('SyntaxError: Geçersiz for döngüsü (satır ${line.number})');
    return startIdx + 1;
  }

  int _handleWhile(
    List<PyLine> lines,
    int startIdx,
    int endLine,
    int baseIndent,
  ) {
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
    while (_evaluator.isTruthy(_evaluator.eval(condExpr))) {
      if (++_loopCount > _maxLoopIterations) {
        _errors.add('RuntimeError: Sonsuz döngü tespit edildi');
        return bodyEnd;
      }
      _executeBody(lines, bodyStart, bodyEnd);
      if (_hasError) return bodyEnd;
    }
    return bodyEnd;
  }

  int _handleIf(
    List<PyLine> lines,
    int startIdx,
    int endLine,
    int baseIndent,
  ) {
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

    var matched = _evaluator.isTruthy(_evaluator.eval(condExpr));
    if (matched) {
      _executeBody(lines, bodyStart, bodyEnd);
    }

    // elif / else zincirini TARA — eşleşen bir kol zaten çalıştıysa
    // sonrakileri çalıştırmadan geç, ama zincirin sonuna kadar ilerle ki
    // çağıran taraf doğru satırdan devam etsin (else'i ayrı bir ifade
    // gibi yeniden değerlendirmesin).
    var i = bodyEnd;
    while (i < endLine) {
      final next = lines[i];
      final relIndent = next.indent - baseIndent;
      if (relIndent != 0) break;
      final nc = next.content;
      if (nc.startsWith('elif ')) {
        final em = _matchPattern(nc, RegExp(r'elif\s+(.+):'));
        if (em == null) {
          i++;
          continue;
        }
        final eStart = i + 1;
        final eEnd = _findBlockEnd(lines, eStart, endLine, next.indent);
        if (!matched && _evaluator.isTruthy(_evaluator.eval(em.group(1)!))) {
          _executeBody(lines, eStart, eEnd);
          matched = true;
        }
        i = eEnd;
      } else if (nc.startsWith('else:')) {
        final eStart = i + 1;
        final eEnd = _findBlockEnd(lines, eStart, endLine, next.indent);
        if (!matched) {
          _executeBody(lines, eStart, eEnd);
        }
        i = eEnd;
        break;
      } else {
        break;
      }
    }
    return i;
  }

  int _findBlockEnd(
    List<PyLine> lines,
    int start,
    int endLine,
    int parentIndent,
  ) {
    var i = start;
    while (i < endLine) {
      if (lines[i].indent <= parentIndent) {
        return i;
      }
      i++;
    }
    return endLine;
  }

  void _evalLine(PyLine line) {
    final c = line.content;

    // print(...)
    final printMatch = _matchPattern(
      c,
      RegExp(r'^print\s*\(\s*(.*)\s*\)\s*$'),
    );
    if (printMatch != null) {
      final argsStr = printMatch.group(1)!;
      final args = _evaluator.splitArgs(argsStr);
      final parts = <String>[];
      for (final arg in args) {
        final v = _evaluator.eval(arg.trim());
        parts.add(_evaluator.stringify(v));
      }
      final printed = parts.join(' ');
      _output.add(printed);
      _recordStep(line, printedOutput: printed);
      return;
    }

    // return [expr]
    final returnMatch = _matchPattern(c, RegExp(r'^return(\s+(.+))?$'));
    if (returnMatch != null) {
      final expr = returnMatch.group(2);
      _returnValue = expr != null ? _evaluator.eval(expr) : null;
      _hasReturned = true;
      _recordStep(line);
      return;
    }

    // liste.append(expr)
    final appendMatch = _matchPattern(
      c,
      RegExp(r'^(\w+)\.append\(\s*(.*)\s*\)$'),
    );
    if (appendMatch != null) {
      final name = appendMatch.group(1)!;
      final argExpr = appendMatch.group(2)!;
      final list = _variables[name];
      if (list is List) {
        list.add(_evaluator.eval(argExpr));
      }
      _recordStep(line);
      return;
    }

    // İndeks ataması: base[index] = expr  (liste veya dict)
    final indexAssignMatch = _matchPattern(
      c,
      RegExp(r'^(\w+)\[(.+?)\]\s*=\s*(.+)$'),
    );
    if (indexAssignMatch != null) {
      final name = indexAssignMatch.group(1)!;
      final indexExpr = indexAssignMatch.group(2)!;
      final valueExpr = indexAssignMatch.group(3)!;
      final base = _variables[name];
      final indexVal = _evaluator.eval(indexExpr);
      final value = _evaluator.eval(valueExpr);
      if (base is List && indexVal is int) {
        if (indexVal >= 0 && indexVal < base.length) {
          base[indexVal] = value;
        } else {
          _errors.add('IndexError: liste sınırının dışında');
        }
      } else if (base is Map) {
        base[indexVal] = value;
      }
      _recordStep(line);
      return;
    }

    // dosya.write(expr)
    final writeMatch = _matchPattern(
      c,
      RegExp(r'^(\w+)\.write\(\s*(.+)\s*\)$'),
    );
    if (writeMatch != null) {
      final varName = writeMatch.group(1)!;
      final argExpr = writeMatch.group(2)!;
      final handle = _variables[varName];
      if (handle is PyFileHandle) {
        final text = _evaluator.stringify(_evaluator.eval(argExpr));
        _files[handle.path] = (_files[handle.path] ?? '') + text;
      }
      _recordStep(line);
      return;
    }

    // open(...) / dosya.close() — no-op (open() zaten atama sağında
    // eval() üzerinden ele alınıyor, burada bağımsız satır olarak
    // kullanılırsa sadece atlanır).
    if (c.startsWith('open(') || RegExp(r'^\w+\.close\(').hasMatch(c)) {
      _recordStep(line);
      return;
    }

    // Atama: x = expr
    final assignMatch = _matchPattern(c, RegExp(r'^(\w+)\s*=\s*(.+)$'));
    if (assignMatch != null) {
      final name = assignMatch.group(1)!;
      final expr = assignMatch.group(2)!;
      _variables[name] = _evaluator.eval(expr);
      _recordStep(line);
      return;
    }

    // Bağımsız fonksiyon çağrısı: selam()
    final callMatch = _matchPattern(c, RegExp(r'^(\w+)\s*\(\s*(.*)\s*\)$'));
    if (callMatch != null && _functions.containsKey(callMatch.group(1))) {
      final name = callMatch.group(1)!;
      final argsStr = callMatch.group(2)!;
      final args = argsStr.trim().isEmpty
          ? const <String>[]
          : _evaluator.splitArgs(argsStr);
      callUserFunction(name, args);
      _recordStep(line);
      return;
    }

    // Tanımsız
    _errors.add('NameError: tanınmayan ifade: $c');
  }

  RegExpMatch? _matchPattern(String s, RegExp re) {
    final m = re.firstMatch(s);
    if (m == null) return null;
    if (m.start != 0) return null;
    return m;
  }
}
