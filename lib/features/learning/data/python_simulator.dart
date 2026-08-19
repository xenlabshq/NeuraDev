import '../domain/entities/error_hint.dart';
import '../domain/entities/execution_step.dart';
import 'python/py_line.dart';
import 'python/python_expression_evaluator.dart';
import 'python/python_statement_executor.dart';

/// Basit Python yorumlayıcı simülasyonu.
/// Gerçek Python çalıştırmaz — öğretici senaryoları karşılayacak kadar
/// yeterli, güvenli ve tahmin edilebilir davranış sağlar.
///
/// İç mantık üç parçaya bölünmüştür (bkz. `data/python/`):
/// - [PyLexer]: kaynak kodu satırlara/girintiye ayırır
/// - [PyExpressionEvaluator]: tekil ifadeleri değerlendirir
/// - [PyStatementExecutor]: blokları (for/while/if) yürütür
class PythonSimulator {
  final List<String> _output = [];
  final Map<String, dynamic> _variables = {};
  final List<String> _errors = [];
  final List<ExecutionStep> _steps = [];

  List<String> get output => List.unmodifiable(_output);
  List<String> get errors => List.unmodifiable(_errors);
  bool get hasError => _errors.isNotEmpty;

  static const int _maxOutputLines = 100;

  /// Python kodunu çalıştırır, çıktıyı ve hataları döner.
  PythonSimulatorResult run(String code, {String? expectedOutput}) {
    _output.clear();
    _errors.clear();
    _variables.clear();
    _steps.clear();

    final evaluator = PyExpressionEvaluator(
      variables: _variables,
      errors: _errors,
    );
    final executor = PyStatementExecutor(
      evaluator: evaluator,
      output: _output,
      variables: _variables,
      errors: _errors,
      steps: _steps,
    );

    try {
      final lines = PyLexer.prepare(code);
      executor.executeBlock(lines, 0, lines.length, 0);
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
        steps: List.of(_steps),
      );
    }

    return PythonSimulatorResult(
      output: List.from(_output),
      errors: List.from(_errors),
      success: !hasError,
      hint: hint,
      steps: List.of(_steps),
    );
  }
}

class PythonSimulatorResult {
  const PythonSimulatorResult({
    required this.output,
    required this.errors,
    required this.success,
    required this.steps,
    this.hint,
  });
  final List<String> output;
  final List<String> errors;
  final bool success;

  /// Akıllı hata analizi sonucu — kullanıcıya öğretmen gibi ipucu verir.
  final ErrorHint? hint;

  /// Kod satır satır çalıştırılırken biriken değişken durumu anlık
  /// görüntüleri — "canlı değişken izleyici" panelinde kullanılır.
  final List<ExecutionStep> steps;

  /// Çıktıyı tek string olarak (her satır newline ile).
  String get combinedOutput => output.join('\n');
}
