import 'package:flutter/material.dart';

import 'package:neuroup/features/learning/domain/entities/learning_island.dart';

/// 10 Python adası, her biri farklı bir beceri alanı.
/// Toplam 50+ node, gerçek tutorial + starter code + solution.
class IslandSeed {
  IslandSeed._();

  static List<LearningIsland> all() => _islands;

  static final List<LearningIsland> _islands = [
    // ADA 1: Başlangıç
    LearningIsland(
      id: 'island_intro',
      title: 'Başlangıç Adası',
      subtitle: 'print() ve yorumlar',
      description:
          "Python'un temel yapı taşlarını öğren. Ekranına ilk mesajını yazdır.",
      emoji: '🏝️',
      color: const Color(0xFF06B6D4),
      gradient: const [Color(0xFF06B6D4), Color(0xFF3B82F6)],
      order: 1,
      nodes: const [
        LearningNode(
          id: 'n_intro_1',
          title: 'İlk Merhaba',
          description: 'Ekrana "Merhaba Dünya" yazdır.',
          tutorial:
              '# print() fonksiyonu ekrana metin yazdırır.\n# Tırnak içindeki metin string olarak adlandırılır.\n\nprint("Merhaba Dünya")',
          starterCode: '# Ekrana "Merhaba Dünya" yazdır\n',
          solution: 'print("Merhaba Dünya")',
          expectedOutput: 'Merhaba Dünya',
          points: 50,
          emoji: '👋',
          order: 1,
        ),
        LearningNode(
          id: 'n_intro_2',
          title: 'Yorum Satırları',
          description: 'Yorumlar kodun açıklamasıdır, çalıştırılmaz.',
          tutorial:
              '# Yorum satırları # ile başlar.\n# Python yorumları görmezden gelir, sadece insanlar içindir.\n\n# Bu bir yorum\nprint("Yorumun altındaki kod çalışır")',
          starterCode: '# Bu satır bir yorum\nprint("Bu çalışır")',
          solution: '# Bu satır bir yorum\nprint("Bu çalışır")',
          expectedOutput: 'Bu çalışır',
          points: 60,
          emoji: '💬',
          order: 2,
        ),
        LearningNode(
          id: 'n_intro_3',
          title: 'Çoklu Print',
          description: 'Birden fazla satır yazdır.',
          tutorial:
              '# Her print() yeni satıra geçer.\n# Birden fazla print alt alta yazılabilir.\n\nprint("Satır 1")\nprint("Satır 2")\nprint("Satır 3")',
          starterCode:
              'print("İsim: Ali")\nprint("Yaş: 25")\nprint("Şehir: İstanbul")',
          solution:
              'print("İsim: Ali")\nprint("Yaş: 25")\nprint("Şehir: İstanbul")',
          expectedOutput: 'İsim: Ali\nYaş: 25\nŞehir: İstanbul',
          points: 70,
          emoji: '📝',
          order: 3,
        ),
      ],
    ),

    // ADA 2: Değişkenler
    LearningIsland(
      id: 'island_variables',
      title: 'Değişkenler Adası',
      subtitle: 'Veriyi sakla, isimlendir',
      description:
          'Değişkenler veriyi hafızada tutar. Onlara isim ver, sonra kullan.',
      emoji: '🏝️',
      color: const Color(0xFF8B5CF6),
      gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      order: 2,
      nodes: const [
        LearningNode(
          id: 'n_var_1',
          title: 'İlk Değişken',
          description: 'Bir değişken oluştur ve yazdır.',
          tutorial:
              '# Değişken = eşittir ile değer atanır.\n# isim = "Ali"  →  isim değişkeni "Ali" değerini tutar.\n\nisim = "Ali"\nprint(isim)',
          starterCode: 'isim = "Ali"\nprint(isim)',
          solution: 'isim = "Ali"\nprint(isim)',
          expectedOutput: 'Ali',
          points: 80,
          emoji: '📦',
          order: 1,
        ),
        LearningNode(
          id: 'n_var_2',
          title: 'Sayı Değişkenler',
          description: 'Tam sayı ve ondalık sayılar.',
          tutorial:
              "# Python'da sayılar tırnaksız yazılır.\n# int = tam sayı, float = ondalık sayı\n\nyas = 20\nboy = 1.75\nprint(yas)\nprint(boy)",
          starterCode: 'sayi = 42\nondalik = 3.14\nprint(sayi)\nprint(ondalik)',
          solution: 'sayi = 42\nondalik = 3.14\nprint(sayi)\nprint(ondalik)',
          expectedOutput: '42\n3.14',
          points: 90,
          emoji: '🔢',
          order: 2,
        ),
        LearningNode(
          id: 'n_var_3',
          title: 'Boolean (Doğru/Yanlış)',
          description: 'True ve False değerleri.',
          tutorial:
              "# bool tipi sadece iki değer alır: True veya False.\n# Python'da True/False büyük harfle başlar.\n\nogrenci = True\nmezun = False\nprint(ogrenci)\nprint(mezun)",
          starterCode:
              'aktif = True\nsilindi = False\nprint(aktif)\nprint(silindi)',
          solution:
              'aktif = True\nsilindi = False\nprint(aktif)\nprint(silindi)',
          expectedOutput: 'True\nFalse',
          points: 100,
          emoji: '✓',
          order: 3,
        ),
        LearningNode(
          id: 'n_var_4',
          title: 'Değişken Birleştirme',
          description: 'f-string ile metin ve değişken birleştir.',
          tutorial:
              '# f-string (f"...") içinde {{değişken}} kullanarak birleştirme yapılır.\n# Modern ve en kolay yöntem.\n\nisim = "Zeynep"\nprint(f"Merhaba {isim}!")',
          starterCode:
              'isim = "Mehmet"\nyas = 30\nprint(f"{isim}, {yas} yaşında")',
          solution:
              'isim = "Mehmet"\nyas = 30\nprint(f"{isim}, {yas} yaşında")',
          expectedOutput: 'Mehmet, 30 yaşında',
          points: 120,
          emoji: '🔗',
          order: 4,
        ),
      ],
    ),

    // ADA 3: Operatörler
    LearningIsland(
      id: 'island_operators',
      title: 'Operatörler Adası',
      subtitle: 'Matematik ve karşılaştırma',
      description: 'Sayılarla işlem yap, karşılaştırmalar yap.',
      emoji: '🏝️',
      color: const Color(0xFFF59E0B),
      gradient: const [Color(0xFFFBBF24), Color(0xFFF97316)],
      order: 3,
      nodes: const [
        LearningNode(
          id: 'n_op_1',
          title: 'Toplama ve Çıkarma',
          description: '+ ve - operatörleri.',
          tutorial:
              '# + toplama, - çıkarma yapar.\n# Sonuç doğrudan print edilebilir.\n\nprint(10 + 5)\nprint(20 - 8)',
          starterCode: 'print(15 + 7)\nprint(100 - 45)',
          solution: 'print(15 + 7)\nprint(100 - 45)',
          expectedOutput: '22\n55',
          points: 100,
          emoji: '➕',
          order: 1,
        ),
        LearningNode(
          id: 'n_op_2',
          title: 'Çarpma ve Bölme',
          description: '* ve / operatörleri.',
          tutorial:
              "# * çarpma, / bölme yapar.\n# Python'da bölme her zaman ondalık verir (float).\n\nprint(6 * 4)\nprint(20 / 5)",
          starterCode: 'print(7 * 8)\nprint(81 / 9)',
          solution: 'print(7 * 8)\nprint(81 / 9)',
          expectedOutput: '56\n9.0',
          points: 110,
          emoji: '✖',
          order: 2,
        ),
        LearningNode(
          id: 'n_op_3',
          title: 'Karşılaştırma',
          description: '<, >, == operatörleri.',
          tutorial:
              '# Karşılaştırma True veya False döner.\n# == eşittir, != eşit değildir.\n\nprint(5 > 3)\nprint(10 == 10)\nprint(7 < 4)',
          starterCode: 'print(15 > 20)\nprint(8 == 8)\nprint(3 != 3)',
          solution: 'print(15 > 20)\nprint(8 == 8)\nprint(3 != 3)',
          expectedOutput: 'False\nTrue\nFalse',
          points: 130,
          emoji: '⚖',
          order: 3,
        ),
      ],
    ),

    // ADA 4: Koşullar
    LearningIsland(
      id: 'island_conditionals',
      title: 'Koşullar Adası',
      subtitle: 'Karar vermeyi öğren',
      description: 'if/else ile koşullara göre farklı işlemler yap.',
      emoji: '🏝️',
      color: const Color(0xFFEF4444),
      gradient: const [Color(0xFFEF4444), Color(0xFFFB7185)],
      order: 4,
      nodes: const [
        LearningNode(
          id: 'n_if_1',
          title: 'İlk if',
          description: 'Koşul doğruysa kodu çalıştır.',
          tutorial:
              '# if koşul: yapısı koşul True ise kodu çalıştırır.\n# Girintileme (4 boşluk) çok önemli!\n\nyas = 18\nif yas >= 18:\n    print("Reşitsiniz")',
          starterCode: 'sayi = 10\nif sayi > 5:\n    print("Büyük")',
          solution: 'sayi = 10\nif sayi > 5:\n    print("Büyük")',
          expectedOutput: 'Büyük',
          points: 140,
          emoji: '🔀',
          order: 1,
        ),
        LearningNode(
          id: 'n_if_2',
          title: 'if-else',
          description: 'Koşul yanlışsa başka bir şey yap.',
          tutorial:
              '# else: koşul False olduğunda çalışır.\n\nnot_ = 45\nif not_ >= 50:\n    print("Geçti")\nelse:\n    print("Kaldı")',
          starterCode:
              'sayi = 3\nif sayi > 5:\n    print("Büyük")\nelse:\n    print("Küçük veya eşit")',
          solution:
              'sayi = 3\nif sayi > 5:\n    print("Büyük")\nelse:\n    print("Küçük veya eşit")',
          expectedOutput: 'Küçük veya eşit',
          points: 150,
          emoji: '↔',
          order: 2,
        ),
        LearningNode(
          id: 'n_if_3',
          title: 'elif Zinciri',
          description: 'Birden fazla koşul kontrol et.',
          tutorial:
              '# elif = "else if", önceki koşul False ise yeni koşulu kontrol eder.\n\npuan = 85\nif puan >= 90:\n    print("AA")\nelif puan >= 80:\n    print("BB")\nelif puan >= 70:\n    print("CC")\nelse:\n    print("FF")',
          starterCode:
              'sayi = 0\nif sayi > 0:\n    print("Pozitif")\nelif sayi < 0:\n    print("Negatif")\nelse:\n    print("Sıfır")',
          solution:
              'sayi = 0\nif sayi > 0:\n    print("Pozitif")\nelif sayi < 0:\n    print("Negatif")\nelse:\n    print("Sıfır")',
          expectedOutput: 'Sıfır',
          points: 170,
          emoji: '🔗',
          order: 3,
        ),
      ],
    ),

    // ADA 5: Döngüler
    LearningIsland(
      id: 'island_loops',
      title: 'Döngüler Adası',
      subtitle: 'Tekrar eden işler',
      description: 'for ve while ile tekrarlayan işlemleri otomatikleştir.',
      emoji: '🏝️',
      color: const Color(0xFF10B981),
      gradient: const [Color(0xFF10B981), Color(0xFF14B8A6)],
      order: 5,
      nodes: const [
        LearningNode(
          id: 'n_loop_1',
          title: 'for ile Sayma',
          description: "range() ile 1'den 5'e kadar yazdır.",
          tutorial:
              "# for i in range(5): 0'dan 4'e kadar döner.\n# range(1, 6) ise 1'den 5'e kadar.\n\nfor i in range(1, 6):\n    print(i)",
          starterCode: 'for i in range(1, 4):\n    print(i)',
          solution: 'for i in range(1, 4):\n    print(i)',
          expectedOutput: '1\n2\n3',
          points: 160,
          emoji: '🔁',
          order: 1,
        ),
        LearningNode(
          id: 'n_loop_2',
          title: 'for ile Liste',
          description: 'Liste üzerinde döngü.',
          tutorial:
              '# for eleman in liste: her eleman için kod çalışır.\n\nmeyveler = ["elma", "armut", "muz"]\nfor meyve in meyveler:\n    print(meyve)',
          starterCode:
              'renkler = ["kırmızı", "mavi", "yeşil"]\nfor renk in renkler:\n    print(renk)',
          solution:
              'renkler = ["kırmızı", "mavi", "yeşil"]\nfor renk in renkler:\n    print(renk)',
          expectedOutput: 'kırmızı\nmavi\nyeşil',
          points: 170,
          emoji: '🍎',
          order: 2,
        ),
        LearningNode(
          id: 'n_loop_3',
          title: 'while Döngüsü',
          description: 'Koşul doğru olduğu sürece tekrarla.',
          tutorial:
              '# while koşul: koşul True olduğu sürece çalışır.\n# Sayaç ile bir noktada durdurmak ÖNEMLİ.\n\nsayi = 1\nwhile sayi <= 3:\n    print(sayi)\n    sayi = sayi + 1',
          starterCode:
              'sayi = 0\nwhile sayi < 3:\n    print(sayi)\n    sayi = sayi + 1',
          solution:
              'sayi = 0\nwhile sayi < 3:\n    print(sayi)\n    sayi = sayi + 1',
          expectedOutput: '0\n1\n2',
          points: 180,
          emoji: '⏳',
          order: 3,
        ),
        LearningNode(
          id: 'n_loop_4',
          title: 'Çarpım Tablosu',
          description: 'İç içe döngü ile çarpım tablosu.',
          tutorial:
              '# İç içe döngü: dış döngü satır, iç döngü sütun.\n\nfor i in range(1, 4):\n    for j in range(1, 4):\n        print(f"{i}x{j}={i*j}")',
          starterCode:
              'for i in range(1, 3):\n    for j in range(1, 3):\n        print(f"{i}*{j}={i*j}")',
          solution:
              'for i in range(1, 3):\n    for j in range(1, 3):\n        print(f"{i}*{j}={i*j}")',
          expectedOutput: '1*1=1\n1*2=2\n2*1=2\n2*2=4',
          points: 200,
          emoji: '🧮',
          order: 4,
        ),
      ],
    ),

    // ADA 6: Listeler
    LearningIsland(
      id: 'island_lists',
      title: 'Listeler Adası',
      subtitle: 'Veri koleksiyonları',
      description: 'Birden fazla veriyi tek yerde tut: listeler.',
      emoji: '🏝️',
      color: const Color(0xFFFBBF24),
      gradient: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      order: 6,
      nodes: const [
        LearningNode(
          id: 'n_list_1',
          title: 'Liste Tanımlama',
          description: 'Köşeli parantez ile liste oluştur.',
          tutorial:
              '# liste = [eleman1, eleman2, ...]\n# Liste farklı tipleri bir arada tutabilir.\n\nsayilar = [1, 2, 3, 4, 5]\nprint(sayilar[0])  # İlk eleman (0 indeksi)\nprint(sayilar[-1]) # Son eleman',
          starterCode:
              'meyveler = ["elma", "armut", "muz"]\nprint(meyveler[0])\nprint(meyveler[2])',
          solution:
              'meyveler = ["elma", "armut", "muz"]\nprint(meyveler[0])\nprint(meyveler[2])',
          expectedOutput: 'elma\nmuz',
          points: 150,
          emoji: '📋',
          order: 1,
        ),
        LearningNode(
          id: 'n_list_2',
          title: 'append ile Ekleme',
          description: 'Listeye yeni eleman ekle.',
          tutorial:
              '# liste.append(yeni_eleman) sona ekler.\n\notolar = [1, 2, 3]\notolar.append(4)\nprint(otolar)',
          starterCode: 'sayilar = [10, 20]\nsayilar.append(30)\nprint(sayilar)',
          solution: 'sayilar = [10, 20]\nsayilar.append(30)\nprint(sayilar)',
          expectedOutput: '[10, 20, 30]',
          points: 160,
          emoji: '➕',
          order: 2,
        ),
        LearningNode(
          id: 'n_list_3',
          title: 'len() ile Uzunluk',
          description: 'Listenin kaç elemanı var?',
          tutorial:
              '# len(liste) listenin uzunluğunu verir.\n\nmeyveler = ["elma", "armut", "muz", "üzüm"]\nprint(len(meyveler))',
          starterCode:
              'sayilar = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]\nprint(len(sayilar))',
          solution:
              'sayilar = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]\nprint(len(sayilar))',
          expectedOutput: '10',
          points: 150,
          emoji: '📏',
          order: 3,
        ),
      ],
    ),

    // ADA 7: Fonksiyonlar
    LearningIsland(
      id: 'island_functions',
      title: 'Fonksiyonlar Adası',
      subtitle: 'Kodunu paketle, tekrar kullan',
      description:
          'Fonksiyonlar: tekrar eden kodları bir kere yaz, istediğin yerde çağır.',
      emoji: '🏝️',
      color: const Color(0xFFEC4899),
      gradient: const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
      order: 7,
      nodes: const [
        LearningNode(
          id: 'n_fn_1',
          title: 'İlk Fonksiyon',
          description: 'def ile fonksiyon tanımla.',
          tutorial:
              '# def fonksiyon_adi(): ile tanımlanır.\n# Gövde 4 boşluk girintili olur.\n\ndef selam():\n    print("Merhaba!")\n\nselam()',
          starterCode: 'def selam():\n    print("Selam!")\n\nselam()',
          solution: 'def selam():\n    print("Selam!")\n\nselam()',
          expectedOutput: 'Selam!',
          points: 180,
          emoji: '⚙',
          order: 1,
        ),
        LearningNode(
          id: 'n_fn_2',
          title: 'Parametreli Fonksiyon',
          description: 'Fonksiyona değer gönder.',
          tutorial:
              '# def selam(isim): parametre alır.\n\ndef selam(isim):\n    print(f"Merhaba {isim}!")\n\nselam("Ali")\nselam("Ayşe")',
          starterCode:
              'def kare(sayi):\n    print(sayi * sayi)\n\nkare(5)\nkare(7)',
          solution:
              'def kare(sayi):\n    print(sayi * sayi)\n\nkare(5)\nkare(7)',
          expectedOutput: '25\n49',
          points: 190,
          emoji: '📨',
          order: 2,
        ),
        LearningNode(
          id: 'n_fn_3',
          title: 'return ile Değer Döndür',
          description: 'Fonksiyon sonuç olarak değer versin.',
          tutorial:
              '# return değer döndürür, sonuç değişkene atanabilir.\n\ndef toplam(a, b):\n    return a + b\n\nsonuc = toplam(3, 5)\nprint(sonuc)',
          starterCode:
              'def kare(sayi):\n    return sayi * sayi\n\nprint(kare(4))\nprint(kare(9))',
          solution:
              'def kare(sayi):\n    return sayi * sayi\n\nprint(kare(4))\nprint(kare(9))',
          expectedOutput: '16\n81',
          points: 200,
          emoji: '↩',
          order: 3,
        ),
      ],
    ),

    // ADA 8: String
    LearningIsland(
      id: 'island_strings',
      title: 'String Adası',
      subtitle: 'Metinlerle çalış',
      description: 'String metotları: büyük harf, küçük harf, parçalama.',
      emoji: '🏝️',
      color: const Color(0xFF06B6D4),
      gradient: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
      order: 8,
      nodes: const [
        LearningNode(
          id: 'n_str_1',
          title: 'upper() ve lower()',
          description: 'Büyük/küçük harf dönüşümü.',
          tutorial:
              '# metin.upper() tüm harfleri büyütür.\n# metin.lower() tüm harfleri küçültür.\n\nisim = "Python"\nprint(isim.upper())\nprint(isim.lower())',
          starterCode:
              'kelime = "Merhaba"\nprint(kelime.upper())\nprint(kelime.lower())',
          solution:
              'kelime = "Merhaba"\nprint(kelime.upper())\nprint(kelime.lower())',
          expectedOutput: 'MERHABA\nmerhaba',
          points: 160,
          emoji: '🔤',
          order: 1,
        ),
        LearningNode(
          id: 'n_str_2',
          title: 'len() String',
          description: 'String uzunluğu bul.',
          tutorial:
              '# len(metin) string\'in karakter sayısını verir.\n\nisim = "Python"\nprint(len(isim))',
          starterCode: 'cumle = "Merhaba Dünya"\nprint(len(cumle))',
          solution: 'cumle = "Merhaba Dünya"\nprint(len(cumle))',
          expectedOutput: '13',
          points: 150,
          emoji: '📐',
          order: 2,
        ),
        LearningNode(
          id: 'n_str_3',
          title: 'replace() Değiştir',
          description: 'String içinde bir kısmı değiştir.',
          tutorial:
              '# metin.replace(eski, yeni) ilk argümanı ikincisiyle değiştirir.\n\ncumle = "Ben Java severim"\nyeni = cumle.replace("Java", "Python")\nprint(yeni)',
          starterCode:
              'metin = "Köpek koşuyor"\nyeni = metin.replace("Köpek", "Kedi")\nprint(yeni)',
          solution:
              'metin = "Köpek koşuyor"\nyeni = metin.replace("Köpek", "Kedi")\nprint(yeni)',
          expectedOutput: 'Kedi koşuyor',
          points: 170,
          emoji: '🔄',
          order: 3,
        ),
      ],
    ),

    // ADA 9: Sözlükler
    LearningIsland(
      id: 'island_dicts',
      title: 'Sözlükler Adası',
      subtitle: 'Anahtar-değer çiftleri',
      description: 'Sözlükler: her veriye bir anahtarla ulaş.',
      emoji: '🏝️',
      color: const Color(0xFF6366F1),
      gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      order: 9,
      nodes: const [
        LearningNode(
          id: 'n_dict_1',
          title: 'Sözlük Tanımlama',
          description: 'Süslü parantez ile sözlük oluştur.',
          tutorial:
              '# sozluk = {"anahtar": değer, ...}\n# Değere anahtarla ulaşılır.\n\nkisi = {"isim": "Ali", "yas": 25}\nprint(kisi["isim"])\nprint(kisi["yas"])',
          starterCode:
              'araba = {"marka": "BMW", "yil": 2020}\nprint(araba["marka"])\nprint(araba["yil"])',
          solution:
              'araba = {"marka": "BMW", "yil": 2020}\nprint(araba["marka"])\nprint(araba["yil"])',
          expectedOutput: 'BMW\n2020',
          points: 180,
          emoji: '📖',
          order: 1,
        ),
        LearningNode(
          id: 'n_dict_2',
          title: 'Sözlüğe Ekleme',
          description: 'Yeni anahtar-değer ekle.',
          tutorial:
              '# sozluk["yeni_anahtar"] = değer\n\nkisi = {"isim": "Ali"}\nkisi["sehir"] = "İstanbul"\nprint(kisi)',
          starterCode:
              'urun = {"ad": "Telefon"}\nurun["fiyat"] = 5000\nprint(urun)',
          solution:
              'urun = {"ad": "Telefon"}\nurun["fiyat"] = 5000\nprint(urun)',
          expectedOutput: "{'ad': 'Telefon', 'fiyat': 5000}",
          points: 190,
          emoji: '➕',
          order: 2,
        ),
      ],
    ),

    // ADA 10: Dosyalar
    LearningIsland(
      id: 'island_files',
      title: 'Dosyalar Adası',
      subtitle: 'Veriyi kalıcı kıl',
      description: 'Dosya okuma/yazma: veriyi diske kaydet, sonra geri yükle.',
      emoji: '🏝️',
      color: const Color(0xFF14B8A6),
      gradient: const [Color(0xFF14B8A6), Color(0xFF06B6D4)],
      order: 10,
      nodes: const [
        LearningNode(
          id: 'n_file_1',
          title: 'Dosyaya Yazma',
          description: 'open() ve write() ile dosyaya yaz.',
          tutorial:
              '# open(dosya, mod) dosyayı açar.\n# "w" = yazma, "r" = okuma, "a" = ekleme.\n# write() string yazar.\n\ndosya = open("notlarim.txt", "w")\ndosya.write("İlk notum!")\ndosya.close()\nprint("Yazıldı")',
          starterCode:
              'f = open("test.txt", "w")\nf.write("Merhaba Python!")\nf.close()\nprint("Dosya yazıldı")',
          solution:
              'f = open("test.txt", "w")\nf.write("Merhaba Python!")\nf.close()\nprint("Dosya yazıldı")',
          expectedOutput: 'Dosya yazıldı',
          points: 200,
          emoji: '💾',
          order: 1,
        ),
        LearningNode(
          id: 'n_file_2',
          title: 'Dosyadan Okuma',
          description: 'read() ile dosya içeriğini oku.',
          tutorial:
              '# open(dosya, "r") ile okuma modunda aç.\n# read() tüm içeriği string olarak verir.\n\ndosya = open("notlarim.txt", "r")\nicerik = dosya.read()\ndosya.close()\nprint(icerik)',
          starterCode:
              'f = open("test.txt", "w")\nf.write("Satır 1\\nSatır 2")\nf.close()\n\nf = open("test.txt", "r")\nicerik = f.read()\nf.close()\nprint(icerik)',
          solution:
              'f = open("test.txt", "w")\nf.write("Satır 1\\nSatır 2")\nf.close()\n\nf = open("test.txt", "r")\nicerik = f.read()\nf.close()\nprint(icerik)',
          expectedOutput: 'Satır 1\nSatır 2',
          points: 220,
          emoji: '📂',
          order: 2,
        ),
      ],
    ),
  ];
}
