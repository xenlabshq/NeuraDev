import 'package:equatable/equatable.dart';

/// Python hatasının kategorize edilmiş hâli.
/// Öğretmen sistemi hata tipine göre bağlamsal ipucu verir.
enum ErrorKind {
  syntax,      // Yazım hatası (parantez, iki nokta, tırnak)
  name,        // Tanımsız değişken/fonksiyon
  type,        // Tip uyuşmazlığı (int + str)
  outOfBounds, // Liste sınırı dışı
  logic,       // Çıktı yanlış (kod çalışıyor ama expectedOutput eşleşmiyor)
  timeout,     // Sonsuz döngü / çok yavaş
  zeroDivision,// Sıfıra bölme
  empty,       // Boş kod
  unknown,
}

extension ErrorKindX on ErrorKind {
  String get emoji => switch (this) {
        ErrorKind.syntax => '🔴',
        ErrorKind.name => '🟠',
        ErrorKind.type => '🟣',
        ErrorKind.outOfBounds => '🟤',
        ErrorKind.logic => '🟡',
        ErrorKind.timeout => '⏱️',
        ErrorKind.zeroDivision => '➗',
        ErrorKind.empty => '📝',
        ErrorKind.unknown => '❓',
      };

  String get label => switch (this) {
        ErrorKind.syntax => 'Sözdizimi Hatası',
        ErrorKind.name => 'Tanımsız İsim',
        ErrorKind.type => 'Tip Hatası',
        ErrorKind.outOfBounds => 'Dizin Hatası',
        ErrorKind.logic => 'Mantık Hatası',
        ErrorKind.timeout => 'Zaman Aşımı',
        ErrorKind.zeroDivision => 'Sıfıra Bölme',
        ErrorKind.empty => 'Boş Kod',
        ErrorKind.unknown => 'Bilinmeyen Hata',
      };
}

/// Bir hata için öğretmen ipucu paketi.
class ErrorHint extends Equatable {
  const ErrorHint({
    required this.kind,
    required this.title,
    required this.message,
    this.lineHint,
    this.example,
    this.docLink,
  });

  final ErrorKind kind;
  final String title;
  final String message;

  /// Hangi satırda/karakter civarında hata olabilir.
  final int? lineHint;

  /// Örnek doğru kullanım.
  final String? example;

  /// Dokümantasyon referansı (ileride web linki olabilir).
  final String? docLink;

  @override
  List<Object?> get props => [kind, title, message, lineHint, example];
}

/// PythonSimulatorResult'tan hata kategorisini çıkaran yardımcı.
class ErrorAnalyzer {
  ErrorAnalyzer._();

  /// Verilen hata metni + çıktı + beklenen çıktı → ErrorHint üret.
  static ErrorHint analyze({
    required List<String> errors,
    required List<String> output,
    required String? expectedOutput,
    required String sourceCode,
  }) {
    final raw = errors.join('\n').toLowerCase();
    final combined = output.join('\n').trim();

    // 1) Boş kod
    if (sourceCode.trim().isEmpty) {
      return const ErrorHint(
        kind: ErrorKind.empty,
        title: 'Henüz kod yok',
        message: 'Kod editörü boş. Bir şeyler yazmayı dene.',
        example: 'print("Merhaba Dünya")',
      );
    }

    // 2) Syntax hatası — parantez/iki nokta/tırnak
    final lineHint = _findLineHint(sourceCode, errors);
    if (raw.contains('syntax') ||
        raw.contains('parse') ||
        raw.contains('unexpected') ||
        raw.contains('eof') ||
        _hasUnbalancedBrackets(sourceCode)) {
      final example = _detectMissingChar(sourceCode);
      return ErrorHint(
        kind: ErrorKind.syntax,
        title: 'Sözdizimi (syntax) hatası',
        message: 'Kodunda küçük bir yazım hatası var. '
            'Python bu kodu anlayamadı.',
        lineHint: lineHint,
        example: example != null
            ? 'Örnek: $example'
            : 'Parantez, iki nokta (:) ve tırnak işaretlerini kontrol et.',
      );
    }

    // 3) Tanımsız isim
    final nameMatch = _extractUndefinedName(errors);
    if (raw.contains('nameerror') ||
        raw.contains('is not defined') ||
        nameMatch != null) {
      return ErrorHint(
        kind: ErrorKind.name,
        title: 'Tanımsız isim',
        message: nameMatch != null
            ? '‘$nameMatch’ adında bir değişken veya fonksiyon tanımlamadın. '
                'Önce onu tanımla, sonra kullan.'
            : 'Kullanmaya çalıştığın bir değişken/fonksiyon tanımsız. '
                'Tanımladığından emin ol.',
        lineHint: lineHint,
        example: 'isim = "Ali"\nprint(isim)',
      );
    }

    // 4) Tip hatası
    if (raw.contains('typeerror') ||
        raw.contains('can only concatenate') ||
        raw.contains('unsupported operand')) {
      return ErrorHint(
        kind: ErrorKind.type,
        title: 'Tip uyuşmazlığı',
        message: 'Bir string ile sayıyı toplamaya veya karıştırmaya çalıştın. '
            'Python’da tip dönüşümü gerekir.',
        example: 'yas = 25\nprint("Yaş: " + str(yas))',
      );
    }

    // 5) Dizin hatası
    if (raw.contains('indexerror') || raw.contains('out of range')) {
      return ErrorHint(
        kind: ErrorKind.outOfBounds,
        title: 'Liste sınırı dışı',
        message: 'Listede olmayan bir indekse erişmeye çalıştın. '
            'İndeksler 0’dan başlar ve son elemanda liste.length-1 olur.',
        example: 'meyveler = ["elma", "armut"]\nprint(meyveler[0])  # ilk',
      );
    }

    // 6) Sıfıra bölme
    if (raw.contains('zerodivision') || raw.contains('division by zero')) {
      return const ErrorHint(
        kind: ErrorKind.zeroDivision,
        title: 'Sıfıra bölme',
        message: 'Bir sayıyı 0’a bölmeye çalıştın. Bu matematikte tanımsızdır.',
        example: 'if bolen != 0:\n    print(sayi / bolen)',
      );
    }

    // 7) Zaman aşımı
    if (raw.contains('timeout') || raw.contains('too many iterations')) {
      return const ErrorHint(
        kind: ErrorKind.timeout,
        title: 'Çok uzun sürdü',
        message: 'Döngün muhtemelen sonsuz. Koşulun hep True kalıyor. '
            'Sayaç değişkenini artırmayı unutmuş olabilirsin.',
        example: 'i = 0\nwhile i < 5:\n    print(i)\n    i += 1',
      );
    }

    // 8) Logic hatası — kod çalışıyor ama çıktı beklenenden farklı
    if (expectedOutput != null && expectedOutput.isNotEmpty) {
      final exp = expectedOutput.trim();
      if (combined.isEmpty) {
        return const ErrorHint(
          kind: ErrorKind.logic,
          title: 'Çıktı yok',
          message: 'Kodun hata vermedi ama hiçbir şey yazdırmadın. '
              'print() kullandığından emin ol.',
          example: 'print("Merhaba")',
        );
      }
      if (combined != exp) {
        return ErrorHint(
          kind: ErrorKind.logic,
          title: 'Mantık hatası',
          message: 'Kodun çalıştı ama çıktı beklenenden farklı. '
              'Beklenen: "${_truncate(exp, 60)}"\n'
              'Senin çıktın: "${_truncate(combined, 60)}"',
          example: 'Büyük/küçük harf, boşluk veya noktalama fark etmiş olabilir.',
        );
      }
    }

    return ErrorHint(
      kind: ErrorKind.unknown,
      title: 'Beklenmeyen hata',
      message: errors.isEmpty
          ? 'Bir şeyler ters gitti.'
          : errors.join('\n'),
    );
  }

  static String? _extractUndefinedName(List<String> errors) {
    if (errors.isEmpty) return null;
    final first = errors.first;
    // "name 'foo' is not defined" patterni
    final regex = RegExp(r"name '([^']+)' is not defined");
    final match = regex.firstMatch(first);
    return match?.group(1);
  }

  static bool _hasUnbalancedBrackets(String code) {
    // Basit kontrol: parantez/ayraç/bracket sayma
    int p = 0, b = 0, s = 0;
    bool inStr = false;
    String? strDelim;
    for (var i = 0; i < code.length; i++) {
      final c = code[i];
      if (inStr) {
        if (c == strDelim && (i == 0 || code[i - 1] != '\\')) inStr = false;
        continue;
      }
      if (c == '"' || c == "'") {
        inStr = true;
        strDelim = c;
        continue;
      }
      if (c == '(') p++;
      if (c == ')') p--;
      if (c == '[') b++;
      if (c == ']') b--;
      if (c == '{') s++;
      if (c == '}') s--;
    }
    return p != 0 || b != 0 || s != 0;
  }

  static String? _detectMissingChar(String code) {
    if (_hasUnbalancedBrackets(code)) {
      return 'print("Merhaba")  # parantezleri kapatmayı unutma';
    }
    final lines = code.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      // if/for/while/def satırı sonunda : eksik mi?
      if (RegExp(r'^\s*(if|for|while|def|elif|else|class)\b.*[^:]\s*$')
          .hasMatch(l)) {
        return 'if x > 0:  # satır sonuna : eklemeyi unutma';
      }
    }
    return null;
  }

  static int? _findLineHint(String code, List<String> errors) {
    if (errors.isEmpty) return null;
    // "line 5" patterni
    final regex = RegExp(r'line\s+(\d+)');
    final m = regex.firstMatch(errors.first);
    return m != null ? int.tryParse(m.group(1)!) : null;
  }

  static String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';
}