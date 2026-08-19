import '../../domain/entities/execution_step.dart';
import 'py_line.dart';
import 'python_expression_evaluator.dart';

/// Satır bloklarını (for/while/if dahil kontrol akışı) yürütür.
class PyStatementExecutor {
  PyStatementExecutor({
    required PyExpressionEvaluator evaluator,
    required List<String> output,
    required Map<String, dynamic> variables,
    required List<String> errors,
    required List<ExecutionStep> steps,
    int maxLoopIterations = 200,
    int maxSteps = 300,
  }) : _evaluator = evaluator,
       _output = output,
       _variables = variables,
       _errors = errors,
       _steps = steps,
       _maxLoopIterations = maxLoopIterations,
       _maxSteps = maxSteps;

  final PyExpressionEvaluator _evaluator;
  final List<String> _output;
  final Map<String, dynamic> _variables;
  final List<String> _errors;
  final List<ExecutionStep> _steps;
  final int _maxLoopIterations;
  final int _maxSteps;
  int _loopCount = 0;

  bool get _hasError => _errors.isNotEmpty;

  void executeBlock(
    List<PyLine> lines,
    int startLine,
    int endLine,
    int baseIndent,
  ) {
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

    // open(...) (kullanıcı dosya yazma/okuma simüle ediyoruz)
    if (c.startsWith('open(')) {
      // Basitçe atla, çıktı üretmiyor
      _recordStep(line);
      return;
    }

    // dosya.write(...) / dosya.close() — no-op
    if (RegExp(r'^\w+\.(write|close|read)\(').hasMatch(c)) {
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
