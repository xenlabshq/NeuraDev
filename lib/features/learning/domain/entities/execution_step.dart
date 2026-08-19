import 'package:equatable/equatable.dart';

/// Kodun tek bir satırı çalıştırıldıktan SONRAKİ anlık durumu.
///
/// `PythonSimulator.run()` her satır yürütüldükçe bir `ExecutionStep`
/// biriktirir; öğrenme editöründeki "canlı değişken izleyici" paneli
/// bunları adım adım oynatarak değişkenlerin nasıl değiştiğini gösterir.
class ExecutionStep extends Equatable {
  const ExecutionStep({
    required this.line,
    required this.sourceLine,
    required this.variables,
    this.printedOutput,
  });

  /// 1-indeksli kaynak satır numarası.
  final int line;

  /// O satırın (yorum/girinti temizlenmiş) içeriği.
  final String sourceLine;

  /// Bu satır çalıştıktan SONRAKİ tüm değişken durumu (anlık kopya —
  /// sonraki adımlarda değişse bile bu adımdaki değerler sabit kalır).
  final Map<String, dynamic> variables;

  /// Bu satır bir `print(...)` ise ürettiği çıktı satırı, değilse null.
  final String? printedOutput;

  @override
  List<Object?> get props => [line, sourceLine, variables, printedOutput];
}
