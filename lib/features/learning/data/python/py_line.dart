/// Tek bir Python kaynak satırı: girinti seviyesi ve yorum/boşluk
/// temizlenmiş içeriği ile birlikte.
class PyLine {
  PyLine({
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

/// Kaynak kodu satırlara ayırır; boş satırları atlar, yorumları temizler
/// ve girinti seviyesini hesaplar.
class PyLexer {
  const PyLexer._();

  static List<PyLine> prepare(String code) {
    return code
        .split('\n')
        .asMap()
        .entries
        .map(
          (e) => PyLine(
            number: e.key + 1,
            raw: e.value,
            indent: _countIndent(e.value),
            content: _stripComment(e.value).trim(),
          ),
        )
        .where((l) => l.content.isNotEmpty)
        .toList();
  }

  static int _countIndent(String s) {
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

  static String _stripComment(String s) {
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
}
