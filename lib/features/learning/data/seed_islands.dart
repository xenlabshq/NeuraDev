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
      emoji: '🚀',
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
          starterCode: '# Kodunu buraya yaz\n',
          solution: 'print("Merhaba Dünya")',
          expectedOutput: 'Merhaba Dünya',
          points: 50,
          emoji: '👋',
          order: 1,
          hints: [
            'Ekrana yazı yazdırmak için print() fonksiyonunu kullan.',
            'Yazdırmak istediğin metni çift tırnak içine al: print("...")',
            'Şöyle yaz: print("Merhaba Dünya") — tırnaklar ve büyük/küçük harfler aynen böyle olmalı.',
          ],
        ),
        LearningNode(
          id: 'n_intro_2',
          title: 'Yorum Satırları',
          description: 'Yorumlar kodun açıklamasıdır, çalıştırılmaz.',
          tutorial:
              '# Yorum satırları # ile başlar.\n# Python yorumları görmezden gelir, sadece insanlar içindir.\n\n# Bu bir yorum\nprint("Yorumun altındaki kod çalışır")',
          starterCode:
              '# Buraya bir yorum satırı ekle, sonra alt satıra\n# ekrana "Bu çalışır" yazdıran bir print() yaz\n',
          solution: '# Bu satır bir yorum\nprint("Bu çalışır")',
          expectedOutput: 'Bu çalışır',
          points: 60,
          emoji: '💬',
          order: 2,
          hints: [
            '# ile başlayan satırlar Python tarafından çalıştırılmaz, sadece açıklama içindir.',
            'Yorum satırının altındaki print() satırı normal şekilde çalışmaya devam eder.',
            'Kod zaten doğru — Çalıştır\'a basman yeterli, yorum satırı çıktıyı etkilemez.',
          ],
        ),
        LearningNode(
          id: 'n_intro_3',
          title: 'Çoklu Print',
          description: 'Birden fazla satır yazdır.',
          tutorial:
              '# Her print() yeni satıra geçer.\n# Birden fazla print alt alta yazılabilir.\n\nprint("Satır 1")\nprint("Satır 2")\nprint("Satır 3")',
          starterCode:
              '# Üç ayrı print() ile İsim, Yaş ve Şehir bilgini yazdır\n',
          solution:
              'print("İsim: Ali")\nprint("Yaş: 25")\nprint("Şehir: İstanbul")',
          expectedOutput: 'İsim: Ali\nYaş: 25\nŞehir: İstanbul',
          points: 70,
          emoji: '📝',
          order: 3,
          hints: [
            'Her print() çağrısı çıktıda yeni bir satır başlatır.',
            'Üç ayrı bilgiyi göstermek için üç ayrı print() satırı kullan.',
            'Kod zaten üç print() içeriyor — her biri kendi satırına yazdırır, sırayla çalıştırılır.',
          ],
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
      emoji: '🧩',
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
          starterCode:
              '# "isim" adında bir değişken oluştur ve "Ali" değerini ata\n# sonra print() ile yazdır\n',
          solution: 'isim = "Ali"\nprint(isim)',
          expectedOutput: 'Ali',
          points: 80,
          emoji: '📦',
          order: 1,
          hints: [
            'Bir değişkene değer atamak için = işaretini kullan: isim = değer',
            'String (metin) değerler tırnak içine yazılır: isim = "Ali"',
            'isim = "Ali" satırından sonra print(isim) ile değişkenin içeriğini yazdır.',
          ],
        ),
        LearningNode(
          id: 'n_var_2',
          title: 'Sayı Değişkenler',
          description: 'Tam sayı ve ondalık sayılar.',
          tutorial:
              "# Python'da sayılar tırnaksız yazılır.\n# int = tam sayı, float = ondalık sayı\n\nyas = 20\nboy = 1.75\nprint(yas)\nprint(boy)",
          starterCode:
              '# sayi = 42 ve ondalik = 3.14 değişkenlerini oluştur\n# sonra ikisini de print() ile yazdır\n',
          solution: 'sayi = 42\nondalik = 3.14\nprint(sayi)\nprint(ondalik)',
          expectedOutput: '42\n3.14',
          points: 90,
          emoji: '🔢',
          order: 2,
          hints: [
            'Sayılar tırnak İÇİNDE değil, doğrudan yazılır: yas = 20',
            'Nokta içeren sayılar ondalık (float) sayılardır: boy = 1.75',
            'İki değişkeni de tanımladıktan sonra her birini ayrı print() ile yazdır.',
          ],
        ),
        LearningNode(
          id: 'n_var_3',
          title: 'Boolean (Doğru/Yanlış)',
          description: 'True ve False değerleri.',
          tutorial:
              "# bool tipi sadece iki değer alır: True veya False.\n# Python'da True/False büyük harfle başlar.\n\nogrenci = True\nmezun = False\nprint(ogrenci)\nprint(mezun)",
          starterCode:
              '# aktif = True ve silindi = False değişkenlerini oluştur\n# sonra ikisini de print() ile yazdır\n',
          solution:
              'aktif = True\nsilindi = False\nprint(aktif)\nprint(silindi)',
          expectedOutput: 'True\nFalse',
          points: 100,
          emoji: '✓',
          order: 3,
          hints: [
            "Python'da mantıksal değerler sadece True veya False olabilir.",
            "True ve False'un ilk harfi HER ZAMAN büyük yazılır, tırnak kullanılmaz.",
            'aktif = True ve silindi = False satırlarını yaz, sonra ikisini de print() ile yazdır.',
          ],
        ),
        LearningNode(
          id: 'n_var_4',
          title: 'Değişken Birleştirme',
          description: 'f-string ile metin ve değişken birleştir.',
          tutorial:
              '# f-string (f"...") içinde {{değişken}} kullanarak birleştirme yapılır.\n# Modern ve en kolay yöntem.\n\nisim = "Zeynep"\nprint(f"Merhaba {isim}!")',
          starterCode:
              'isim = "Mehmet"\nyas = 30\n# f-string kullanarak "Mehmet, 30 yaşında" yazdır\n',
          solution:
              'isim = "Mehmet"\nyas = 30\nprint(f"{isim}, {yas} yaşında")',
          expectedOutput: 'Mehmet, 30 yaşında',
          points: 120,
          emoji: '🔗',
          order: 4,
          hints: [
            'f-string, metnin başına f harfi koyarak oluşturulur: f"..."',
            'Süslü parantez {} içine değişken adını yazarsan değeri metne gömülür: f"{isim}"',
            'print(f"{isim}, {yas} yaşında") gibi bir f-string kullan.',
          ],
        ),
      ],
    ),

    // ADA 3: Operatörler
    LearningIsland(
      id: 'island_operators',
      title: 'Operatörler Adası',
      subtitle: 'Matematik ve karşılaştırma',
      description: 'Sayılarla işlem yap, karşılaştırmalar yap.',
      emoji: '➗',
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
          starterCode: '# print(15 + 7) ve print(100 - 45) satırlarını yaz\n',
          solution: 'print(15 + 7)\nprint(100 - 45)',
          expectedOutput: '22\n55',
          points: 100,
          emoji: '➕',
          order: 1,
          hints: [
            '+ işareti toplama, - işareti çıkarma yapar.',
            'İşlemi doğrudan print() içine yazabilirsin: print(15 + 7)',
            'print(15 + 7) ve print(100 - 45) satırlarını yaz.',
          ],
        ),
        LearningNode(
          id: 'n_op_2',
          title: 'Çarpma ve Bölme',
          description: '* ve / operatörleri.',
          tutorial:
              "# * çarpma, / bölme yapar.\n# Python'da bölme her zaman ondalık verir (float).\n\nprint(6 * 4)\nprint(20 / 5)",
          starterCode: '# print(7 * 8) ve print(81 / 9) satırlarını yaz\n',
          solution: 'print(7 * 8)\nprint(81 / 9)',
          expectedOutput: '56\n9.0',
          points: 110,
          emoji: '✖',
          order: 2,
          hints: [
            '* çarpma, / bölme işareti.',
            "Python'da / işlemi SONUCU HER ZAMAN ondalık (float) döner, tam sayı bile olsa .0 eklenir.",
            'print(7 * 8) ve print(81 / 9) yaz — ikinci sonuç 9.0 olacak, 9 değil.',
          ],
        ),
        LearningNode(
          id: 'n_op_3',
          title: 'Karşılaştırma',
          description: '<, >, == operatörleri.',
          tutorial:
              '# Karşılaştırma True veya False döner.\n# == eşittir, != eşit değildir.\n\nprint(5 > 3)\nprint(10 == 10)\nprint(7 < 4)',
          starterCode:
              '# print(15 > 20), print(8 == 8) ve print(3 != 3) satırlarını yaz\n',
          solution: 'print(15 > 20)\nprint(8 == 8)\nprint(3 != 3)',
          expectedOutput: 'False\nTrue\nFalse',
          points: 130,
          emoji: '⚖',
          order: 3,
          hints: [
            'Karşılaştırma operatörleri (>, <, ==) her zaman True veya False döner.',
            '== eşitliği kontrol eder (tek eşittir = atama içindir, karıştırma).',
            'print(15 > 20), print(8 == 8), print(3 != 3) satırlarını sırayla yaz.',
          ],
        ),
      ],
    ),

    // ADA 4: Koşullar
    LearningIsland(
      id: 'island_conditionals',
      title: 'Koşullar Adası',
      subtitle: 'Karar vermeyi öğren',
      description: 'if/else ile koşullara göre farklı işlemler yap.',
      emoji: '🚦',
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
          starterCode:
              'sayi = 10\n# sayi 5\'ten büyükse "Büyük" yazdıran bir if yaz\n',
          solution: 'sayi = 10\nif sayi > 5:\n    print("Büyük")',
          expectedOutput: 'Büyük',
          points: 140,
          emoji: '🔀',
          order: 1,
          hints: [
            'if koşul: yapısından sonraki satır MUTLAKA 4 boşluk girintili olmalı.',
            'Koşul True ise girintili blok çalışır, False ise atlanır.',
            'if sayi > 5:\n    print("Büyük") — girintiye dikkat et.',
          ],
        ),
        LearningNode(
          id: 'n_if_2',
          title: 'if-else',
          description: 'Koşul yanlışsa başka bir şey yap.',
          tutorial:
              '# else: koşul False olduğunda çalışır.\n\nnot_ = 45\nif not_ >= 50:\n    print("Geçti")\nelse:\n    print("Kaldı")',
          starterCode:
              'sayi = 3\n# sayi 5\'ten büyükse "Büyük", değilse "Küçük veya eşit" yazdır\n',
          solution:
              'sayi = 3\nif sayi > 5:\n    print("Büyük")\nelse:\n    print("Küçük veya eşit")',
          expectedOutput: 'Küçük veya eşit',
          points: 150,
          emoji: '↔',
          order: 2,
          hints: [
            'else: bloğu, if koşulu False olduğunda devreye girer.',
            'else kendi başına bir koşul almaz, sadece else: yazılır.',
            'if sayi > 5:\n    print("Büyük")\nelse:\n    print("Küçük veya eşit")',
          ],
        ),
        LearningNode(
          id: 'n_if_3',
          title: 'elif Zinciri',
          description: 'Birden fazla koşul kontrol et.',
          tutorial:
              '# elif = "else if", önceki koşul False ise yeni koşulu kontrol eder.\n\npuan = 85\nif puan >= 90:\n    print("AA")\nelif puan >= 80:\n    print("BB")\nelif puan >= 70:\n    print("CC")\nelse:\n    print("FF")',
          starterCode:
              'sayi = 0\n# sayi pozitifse "Pozitif", negatifse "Negatif", sıfırsa "Sıfır" yazdır\n',
          solution:
              'sayi = 0\nif sayi > 0:\n    print("Pozitif")\nelif sayi < 0:\n    print("Negatif")\nelse:\n    print("Sıfır")',
          expectedOutput: 'Sıfır',
          points: 170,
          emoji: '🔗',
          order: 3,
          hints: [
            "elif, 'else if' demektir — önceki koşullar False olduğunda yeni bir koşulu dener.",
            'Zincir yukarıdan aşağı kontrol edilir, ilk True olan koşulun bloğu çalışır ve zincir orada durur.',
            'if sayi > 0: ... elif sayi < 0: ... else: print("Sıfır") — sayi 0 olduğu için son else çalışır.',
          ],
        ),
      ],
    ),

    // ADA 5: Döngüler
    LearningIsland(
      id: 'island_loops',
      title: 'Döngüler Adası',
      subtitle: 'Tekrar eden işler',
      description: 'for ve while ile tekrarlayan işlemleri otomatikleştir.',
      emoji: '🔄',
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
          starterCode:
              "# range() kullanarak 1'den 3'e kadar say ve her sayıyı yazdır\n",
          solution: 'for i in range(1, 4):\n    print(i)',
          expectedOutput: '1\n2\n3',
          points: 160,
          emoji: '🔁',
          order: 1,
          hints: [
            "for i in range(a, b): döngüsü a'dan b-1'e kadar sayar (b dahil değildir).",
            "1'den 3'e kadar saymak için range(1, 4) yazmalısın (4 dahil değil, 3'te durur).",
            'for i in range(1, 4):\n    print(i) — çıktı 1, 2, 3 olur.',
          ],
        ),
        LearningNode(
          id: 'n_loop_2',
          title: 'for ile Liste',
          description: 'Liste üzerinde döngü.',
          tutorial:
              '# for eleman in liste: her eleman için kod çalışır.\n\nmeyveler = ["elma", "armut", "muz"]\nfor meyve in meyveler:\n    print(meyve)',
          starterCode:
              'renkler = ["kırmızı", "mavi", "yeşil"]\n# Listedeki her rengi tek tek yazdır\n',
          solution:
              'renkler = ["kırmızı", "mavi", "yeşil"]\nfor renk in renkler:\n    print(renk)',
          expectedOutput: 'kırmızı\nmavi\nyeşil',
          points: 170,
          emoji: '🍎',
          order: 2,
          hints: [
            'for eleman in liste: yapısı listedeki her elemanı sırayla dolaşır.',
            'Döngü değişkeninin adını istediğin gibi seçebilirsin, önemli olan liste ile eşleşmesi.',
            'for renk in renkler:\n    print(renk) — her rengi ayrı satırda yazdırır.',
          ],
        ),
        LearningNode(
          id: 'n_loop_3',
          title: 'while Döngüsü',
          description: 'Koşul doğru olduğu sürece tekrarla.',
          tutorial:
              '# while koşul: koşul True olduğu sürece çalışır.\n# Sayaç ile bir noktada durdurmak ÖNEMLİ.\n\nsayi = 1\nwhile sayi <= 3:\n    print(sayi)\n    sayi = sayi + 1',
          starterCode:
              "sayi = 0\n# sayi 3'ten küçük olduğu sürece sayi'yı yazdır ve bir artır\n",
          solution:
              'sayi = 0\nwhile sayi < 3:\n    print(sayi)\n    sayi = sayi + 1',
          expectedOutput: '0\n1\n2',
          points: 180,
          emoji: '⏳',
          order: 3,
          hints: [
            'while koşul: koşul True olduğu sürece tekrar eder.',
            'Sonsuz döngüye girmemek için döngü içinde sayaç değişkenini güncellemeyi unutma.',
            'while sayi < 3:\n    print(sayi)\n    sayi = sayi + 1 — her turda sayi bir artar.',
          ],
        ),
        LearningNode(
          id: 'n_loop_4',
          title: 'Çarpım Tablosu',
          description: 'İç içe döngü ile çarpım tablosu.',
          tutorial:
              '# İç içe döngü: dış döngü satır, iç döngü sütun.\n\nfor i in range(1, 4):\n    for j in range(1, 4):\n        print(f"{i}x{j}={i*j}")',
          starterCode:
              "# 1'den 2'ye kadar iç içe iki döngü ile çarpım tablosu yazdır\n",
          solution:
              'for i in range(1, 3):\n    for j in range(1, 3):\n        print(f"{i}*{j}={i*j}")',
          expectedOutput: '1*1=1\n1*2=2\n2*1=2\n2*2=4',
          points: 200,
          emoji: '🧮',
          order: 4,
          hints: [
            'İç içe döngüde dış döngünün her adımında, iç döngü baştan sona kadar tam olarak çalışır.',
            'Dış döngü satırı (i), iç döngü sütunu (j) temsil eder — çarpım i*j ile hesaplanır.',
            'for i in range(1, 3):\n    for j in range(1, 3):\n        print(f"{i}*{j}={i*j}")',
          ],
        ),
      ],
    ),

    // ADA 6: Listeler
    LearningIsland(
      id: 'island_lists',
      title: 'Listeler Adası',
      subtitle: 'Veri koleksiyonları',
      description: 'Birden fazla veriyi tek yerde tut: listeler.',
      emoji: '🗂️',
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
              'meyveler = ["elma", "armut", "muz"]\n# İlk elemanı ve üçüncü elemanı yazdır\n',
          solution:
              'meyveler = ["elma", "armut", "muz"]\nprint(meyveler[0])\nprint(meyveler[2])',
          expectedOutput: 'elma\nmuz',
          points: 150,
          emoji: '📋',
          order: 1,
          hints: [
            'Liste köşeli parantez [] içinde, virgülle ayrılmış elemanlarla oluşturulur.',
            "İndeksler 0'dan başlar — liste[0] ilk elemandır, liste[-1] son elemandır.",
            "meyveler[0] ilk elemanı ('elma'), meyveler[2] üçüncü elemanı ('muz') verir.",
          ],
        ),
        LearningNode(
          id: 'n_list_2',
          title: 'append ile Ekleme',
          description: 'Listeye yeni eleman ekle.',
          tutorial:
              '# liste.append(yeni_eleman) sona ekler.\n\notolar = [1, 2, 3]\notolar.append(4)\nprint(otolar)',
          starterCode:
              'sayilar = [10, 20]\n# Listeye 30 ekle, sonra listeyi yazdır\n',
          solution: 'sayilar = [10, 20]\nsayilar.append(30)\nprint(sayilar)',
          expectedOutput: '[10, 20, 30]',
          points: 160,
          emoji: '➕',
          order: 2,
          hints: [
            'liste.append(değer) listenin SONUNA yeni bir eleman ekler.',
            'append her zaman en sona ekler, listenin ortasına veya başına eklemez.',
            'sayilar.append(30) satırından sonra print(sayilar) ile [10, 20, 30] görmelisin.',
          ],
        ),
        LearningNode(
          id: 'n_list_3',
          title: 'len() ile Uzunluk',
          description: 'Listenin kaç elemanı var?',
          tutorial:
              '# len(liste) listenin uzunluğunu verir.\n\nmeyveler = ["elma", "armut", "muz", "üzüm"]\nprint(len(meyveler))',
          starterCode:
              'sayilar = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]\n# len() ile listenin uzunluğunu yazdır\n',
          solution:
              'sayilar = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]\nprint(len(sayilar))',
          expectedOutput: '10',
          points: 150,
          emoji: '📏',
          order: 3,
          hints: [
            'len(liste) fonksiyonu listedeki eleman sayısını döner.',
            'len() bir fonksiyondur, liste.len() değil len(liste) şeklinde çağrılır.',
            'print(len(sayilar)) — 10 elemanlı listede sonuç 10 olur.',
          ],
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
      emoji: '🛠️',
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
          starterCode:
              '# "Selam!" yazdıran bir selam() fonksiyonu tanımla ve çağır\n',
          solution: 'def selam():\n    print("Selam!")\n\nselam()',
          expectedOutput: 'Selam!',
          points: 180,
          emoji: '⚙',
          order: 1,
          hints: [
            'def fonksiyon_adi(): ile yeni bir fonksiyon tanımlanır, gövdesi girintili yazılır.',
            'Bir fonksiyonu tanımlamak onu ÇALIŞTIRMAZ — çalıştırmak için fonksiyon_adi() ile ÇAĞIRMAN gerekir.',
            'def selam():\n    print("Selam!")\n\nselam() — son satır fonksiyonu çağırır.',
          ],
        ),
        LearningNode(
          id: 'n_fn_2',
          title: 'Parametreli Fonksiyon',
          description: 'Fonksiyona değer gönder.',
          tutorial:
              '# def selam(isim): parametre alır.\n\ndef selam(isim):\n    print(f"Merhaba {isim}!")\n\nselam("Ali")\nselam("Ayşe")',
          starterCode:
              '# sayi parametresi alan ve karesini yazdıran bir kare() fonksiyonu yaz\n# sonra kare(5) ve kare(7) ile çağır\n',
          solution:
              'def kare(sayi):\n    print(sayi * sayi)\n\nkare(5)\nkare(7)',
          expectedOutput: '25\n49',
          points: 190,
          emoji: '📨',
          order: 2,
          hints: [
            'Parantez içine bir isim yazarsan fonksiyon bir parametre alır: def kare(sayi):',
            'Fonksiyonu çağırırken parantez içine gerçek bir değer verirsin: kare(5)',
            'def kare(sayi):\n    print(sayi * sayi)\n\nkare(5)\nkare(7) — sırasıyla 25 ve 49 yazdırır.',
          ],
        ),
        LearningNode(
          id: 'n_fn_3',
          title: 'return ile Değer Döndür',
          description: 'Fonksiyon sonuç olarak değer versin.',
          tutorial:
              '# return değer döndürür, sonuç değişkene atanabilir.\n\ndef toplam(a, b):\n    return a + b\n\nsonuc = toplam(3, 5)\nprint(sonuc)',
          starterCode:
              '# sayının karesini return eden bir kare() fonksiyonu yaz\n# sonra print(kare(4)) ve print(kare(9)) ile yazdır\n',
          solution:
              'def kare(sayi):\n    return sayi * sayi\n\nprint(kare(4))\nprint(kare(9))',
          expectedOutput: '16\n81',
          points: 200,
          emoji: '↩',
          order: 3,
          hints: [
            'return, fonksiyonun bir sonucu geri GÖNDERMESİNİ sağlar — print() ile karıştırma, ikisi farklı.',
            'return ile dönen değeri bir değişkene atayabilir ya da doğrudan print() içine koyabilirsin.',
            'def kare(sayi):\n    return sayi * sayi\n\nprint(kare(4)) — 16 yazdırır.',
          ],
        ),
      ],
    ),

    // ADA 8: String
    LearningIsland(
      id: 'island_strings',
      title: 'String Adası',
      subtitle: 'Metinlerle çalış',
      description: 'String metotları: büyük harf, küçük harf, parçalama.',
      emoji: '🔠',
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
              'kelime = "Merhaba"\n# Büyük harfli ve küçük harfli hallerini yazdır\n',
          solution:
              'kelime = "Merhaba"\nprint(kelime.upper())\nprint(kelime.lower())',
          expectedOutput: 'MERHABA\nmerhaba',
          points: 160,
          emoji: '🔤',
          order: 1,
          hints: [
            'metin.upper() tüm harfleri büyük harfe çevirir.',
            'metin.lower() tüm harfleri küçük harfe çevirir — orijinal değişkeni değiştirmez, yeni bir sonuç döner.',
            'print(kelime.upper()) ve print(kelime.lower()) satırlarını yaz.',
          ],
        ),
        LearningNode(
          id: 'n_str_2',
          title: 'len() String',
          description: 'String uzunluğu bul.',
          tutorial:
              '# len(metin) string\'in karakter sayısını verir.\n\nisim = "Python"\nprint(len(isim))',
          starterCode:
              'cumle = "Merhaba Dünya"\n# len() ile cümlenin uzunluğunu yazdır\n',
          solution: 'cumle = "Merhaba Dünya"\nprint(len(cumle))',
          expectedOutput: '13',
          points: 150,
          emoji: '📐',
          order: 2,
          hints: [
            "len() fonksiyonu listelerde olduğu gibi string'lerde de çalışır.",
            'len(metin) metindeki karakter sayısını (boşluklar dahil) verir.',
            "print(len(cumle)) — 'Merhaba Dünya' 13 karakter (boşluk dahil).",
          ],
        ),
        LearningNode(
          id: 'n_str_3',
          title: 'replace() Değiştir',
          description: 'String içinde bir kısmı değiştir.',
          tutorial:
              '# metin.replace(eski, yeni) ilk argümanı ikincisiyle değiştirir.\n\ncumle = "Ben Java severim"\nyeni = cumle.replace("Java", "Python")\nprint(yeni)',
          starterCode:
              'metin = "Köpek koşuyor"\n# "Köpek" kelimesini "Kedi" ile değiştirip yazdır\n',
          solution:
              'metin = "Köpek koşuyor"\nyeni = metin.replace("Köpek", "Kedi")\nprint(yeni)',
          expectedOutput: 'Kedi koşuyor',
          points: 170,
          emoji: '🔄',
          order: 3,
          hints: [
            'metin.replace(eski, yeni) metindeki eski kelimeyi yeni kelimeyle değiştirir.',
            "replace() orijinal string'i DEĞİŞTİRMEZ, değiştirilmiş YENİ bir string döner — bir değişkene atamalısın.",
            'yeni = metin.replace("Köpek", "Kedi")\nprint(yeni)',
          ],
        ),
      ],
    ),

    // ADA 9: Sözlükler
    LearningIsland(
      id: 'island_dicts',
      title: 'Sözlükler Adası',
      subtitle: 'Anahtar-değer çiftleri',
      description: 'Sözlükler: her veriye bir anahtarla ulaş.',
      emoji: '🗝️',
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
              'araba = {"marka": "BMW", "yil": 2020}\n# "marka" ve "yil" değerlerini yazdır\n',
          solution:
              'araba = {"marka": "BMW", "yil": 2020}\nprint(araba["marka"])\nprint(araba["yil"])',
          expectedOutput: 'BMW\n2020',
          points: 180,
          emoji: '📖',
          order: 1,
          hints: [
            'Sözlük süslü parantez {} içinde "anahtar": değer çiftleriyle oluşturulur.',
            'Bir değere erişmek için köşeli parantez ve anahtarını kullanırsın: sozluk["anahtar"]',
            'araba["marka"] ve araba["yil"] değerlerini ayrı ayrı print() ile yazdır.',
          ],
        ),
        LearningNode(
          id: 'n_dict_2',
          title: 'Sözlüğe Ekleme',
          description: 'Yeni anahtar-değer ekle.',
          tutorial:
              '# sozluk["yeni_anahtar"] = değer\n\nkisi = {"isim": "Ali"}\nkisi["sehir"] = "İstanbul"\nprint(kisi)',
          starterCode:
              'urun = {"ad": "Telefon"}\n# "fiyat" anahtarına 5000 değerini ekle, sonra sözlüğü yazdır\n',
          solution:
              'urun = {"ad": "Telefon"}\nurun["fiyat"] = 5000\nprint(urun)',
          expectedOutput: "{'ad': 'Telefon', 'fiyat': 5000}",
          points: 190,
          emoji: '➕',
          order: 2,
          hints: [
            'Var olmayan bir anahtara değer atarsan, sözlüğe YENİ bir anahtar-değer çifti eklenmiş olur.',
            'Sözlük["yeni_anahtar"] = değer şeklinde yaz — dict.append() diye bir şey yoktur.',
            'urun["fiyat"] = 5000 satırından sonra print(urun) ile güncellenmiş sözlüğü gör.',
          ],
        ),
      ],
    ),

    // ADA 10: Dosyalar
    LearningIsland(
      id: 'island_files',
      title: 'Dosyalar Adası',
      subtitle: 'Veriyi kalıcı kıl',
      description: 'Dosya okuma/yazma: veriyi diske kaydet, sonra geri yükle.',
      emoji: '🗄️',
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
              '# "test.txt" dosyasını yazma modunda aç, "Merhaba Python!" yaz, kapat\n# sonra "Dosya yazıldı" yazdır\n',
          solution:
              'f = open("test.txt", "w")\nf.write("Merhaba Python!")\nf.close()\nprint("Dosya yazıldı")',
          expectedOutput: 'Dosya yazıldı',
          points: 200,
          emoji: '💾',
          order: 1,
          hints: [
            'open(dosya_adi, "w") dosyayı YAZMA modunda açar (yoksa oluşturur, varsa üzerine yazar).',
            'dosya.write(metin) ile içeriği dosyaya yazarsın, sonunda dosya.close() ile kapatmayı unutma.',
            'f = open("test.txt", "w")\nf.write("Merhaba Python!")\nf.close()',
          ],
        ),
        LearningNode(
          id: 'n_file_2',
          title: 'Dosyadan Okuma',
          description: 'read() ile dosya içeriğini oku.',
          tutorial:
              '# open(dosya, "r") ile okuma modunda aç.\n# read() tüm içeriği string olarak verir.\n\ndosya = open("notlarim.txt", "r")\nicerik = dosya.read()\ndosya.close()\nprint(icerik)',
          starterCode:
              'f = open("test.txt", "w")\nf.write("Satır 1\\nSatır 2")\nf.close()\n\n# Şimdi dosyayı okuma modunda aç, içeriğini oku ve yazdır\n',
          solution:
              'f = open("test.txt", "w")\nf.write("Satır 1\\nSatır 2")\nf.close()\n\nf = open("test.txt", "r")\nicerik = f.read()\nf.close()\nprint(icerik)',
          expectedOutput: 'Satır 1\nSatır 2',
          points: 220,
          emoji: '📂',
          order: 2,
          hints: [
            'open(dosya_adi, "r") dosyayı OKUMA modunda açar.',
            'dosya.read() dosyanın TÜM içeriğini tek bir string olarak döner.',
            'icerik = dosya.read()\nprint(icerik) — dosyaya yazdığın metni ekrana getirir.',
          ],
        ),
      ],
    ),

    // ADA 11: Algoritmalar (ileri seviye)
    LearningIsland(
      id: 'island_algorithms',
      title: 'Algoritmalar Adası',
      subtitle: "Döngülerle gerçek problemler çöz",
      description:
          'Hazır fonksiyonlara güvenmeden döngülerle en büyüğü bul, ortalama al, say — gerçek algoritmik düşünmeyi öğren.',
      emoji: '🧠',
      color: const Color(0xFF3B82F6),
      gradient: const [Color(0xFF3B82F6), Color(0xFF1E40AF)],
      order: 11,
      nodes: const [
        LearningNode(
          id: 'n_algo_1',
          title: 'En Büyüğü Bul',
          description: "max() kullanmadan bir listenin en büyük elemanını bul.",
          tutorial:
              "# max() fonksiyonu olmadan en büyüğü bulmak için: önce ilk elemanı 'şimdilik en büyük' kabul et, sonra listeyi gezip daha büyüğünü bulunca güncelle.\n\nsayilar = [3, 8, 1, 6]\nen_buyuk = sayilar[0]\nfor sayi in sayilar:\n    if sayi > en_buyuk:\n        en_buyuk = sayi\nprint(en_buyuk)",
          starterCode:
              'sayilar = [4, 9, 2, 7, 5]\n# max() kullanmadan listenin en büyük elemanını bul ve yazdır\n',
          solution:
              'sayilar = [4, 9, 2, 7, 5]\nen_buyuk = sayilar[0]\nfor sayi in sayilar:\n    if sayi > en_buyuk:\n        en_buyuk = sayi\nprint(en_buyuk)',
          expectedOutput: '9',
          points: 230,
          emoji: '🔍',
          order: 1,
          hints: [
            "max() gibi hazır bir fonksiyon yok — en büyüğü BULMAK için kendi mantığını kurman gerekiyor.",
            "İlk elemanı 'şimdilik en büyük' olarak kabul et, sonra listenin geri kalanını gezerken ondan büyük bir sayı bulunca güncelle.",
            'en_buyuk = sayilar[0]\nfor sayi in sayilar:\n    if sayi > en_buyuk:\n        en_buyuk = sayi',
          ],
        ),
        LearningNode(
          id: 'n_algo_2',
          title: 'Toplam ve Ortalama',
          description: 'Bir listenin toplamını ve ortalamasını hesapla.',
          tutorial:
              '# Toplamı bulmak için bir sayaç değişkeni sıfırdan başlat, listeyi gezip her elemanı ekle. Ortalama = toplam / eleman sayısı.\n\npuanlar = [70, 80, 90]\ntoplam = 0\nfor p in puanlar:\n    toplam = toplam + p\nortalama = toplam / len(puanlar)\nprint(toplam)\nprint(ortalama)',
          starterCode:
              'notlar = [80, 90, 70, 100]\n# Listenin toplamını ve ortalamasını hesaplayıp yazdır\n',
          solution:
              'notlar = [80, 90, 70, 100]\ntoplam = 0\nfor n in notlar:\n    toplam = toplam + n\nortalama = toplam / len(notlar)\nprint(toplam)\nprint(ortalama)',
          expectedOutput: '340\n85.0',
          points: 240,
          emoji: '📊',
          order: 2,
          hints: [
            'Toplamı bulmak için sıfırdan başlayan bir değişkeni döngü içinde her elemanla topla: toplam = toplam + eleman',
            "Ortalama, toplamın eleman sayısına bölünmesiyle bulunur — len() ile eleman sayısını al.",
            'toplam = toplam + n şeklinde döngüde biriktir, sonra ortalama = toplam / len(notlar) hesapla.',
          ],
        ),
        LearningNode(
          id: 'n_algo_3',
          title: 'Eşleşmeleri Say',
          description: 'Bir listede belirli bir değerden kaç tane olduğunu say.',
          tutorial:
              '# Bir sayaç değişkeni sıfırdan başlat, listeyi gezip aradığın değere eşit her elemanda sayaç bir artsın.\n\nharfler = ["a", "b", "a", "c"]\nsayac = 0\nfor h in harfler:\n    if h == "a":\n        sayac = sayac + 1\nprint(sayac)',
          starterCode:
              'kelimeler = ["kedi", "kopek", "kedi", "kus", "kedi"]\n# Listede kaç tane "kedi" olduğunu say ve yazdır\n',
          solution:
              'kelimeler = ["kedi", "kopek", "kedi", "kus", "kedi"]\nsayac = 0\nfor k in kelimeler:\n    if k == "kedi":\n        sayac = sayac + 1\nprint(sayac)',
          expectedOutput: '3',
          points: 250,
          emoji: '🔢',
          order: 3,
          hints: [
            'Bir sayacı sıfırdan başlat, aradığın değere her rastladığında sayacı bir artır.',
            'Karşılaştırma için == operatörünü kullan: if eleman == "aranan":',
            'sayac = sayac + 1 satırını if bloğunun İÇİNE, girintili şekilde yaz.',
          ],
        ),
      ],
    ),

    // ADA 12: Mini Projeler (ileri seviye)
    LearningIsland(
      id: 'island_projects',
      title: 'Mini Projeler Adası',
      subtitle: 'Bildiklerini birleştir',
      description:
          'Fonksiyonlar, listeler ve sözlükleri bir araya getirerek gerçek küçük programlar yaz.',
      emoji: '🏆',
      color: const Color(0xFFF43F5E),
      gradient: const [Color(0xFFF43F5E), Color(0xFFBE123C)],
      order: 12,
      nodes: const [
        LearningNode(
          id: 'n_proj_1',
          title: 'Not Hesaplayıcı',
          description: 'Bir fonksiyon yaz: puanı harf notuna çevirsin.',
          tutorial:
              '# Bir fonksiyon if/elif/else zinciriyle farklı sonuçlar döndürebilir.\n\ndef harf_notu(puan):\n    if puan >= 90:\n        return "AA"\n    elif puan >= 70:\n        return "BB"\n    else:\n        return "FF"\n\nprint(harf_notu(95))',
          starterCode:
              '# Puanı harf notuna çeviren bir harf_notu() fonksiyonu yaz\n# 90+ ise "AA", 70+ ise "BB", değilse "FF" dönsün\n# sonra harf_notu(95), harf_notu(75), harf_notu(40) ile yazdır\n',
          solution:
              'def harf_notu(puan):\n    if puan >= 90:\n        return "AA"\n    elif puan >= 70:\n        return "BB"\n    else:\n        return "FF"\n\nprint(harf_notu(95))\nprint(harf_notu(75))\nprint(harf_notu(40))',
          expectedOutput: 'AA\nBB\nFF',
          points: 260,
          emoji: '🎓',
          order: 1,
          hints: [
            'Fonksiyon içinde if/elif/else zinciri kurup her koşulda farklı bir return kullanabilirsin.',
            'Fonksiyonu üç farklı puanla üç kez çağırıp her sonucu ayrı print() ile yazdır.',
            'if puan >= 90: return "AA" ... elif puan >= 70: return "BB" ... else: return "FF"',
          ],
        ),
        LearningNode(
          id: 'n_proj_2',
          title: 'Paralel Listelerle Rapor',
          description: 'İki listeyi aynı anda, index ile birlikte gez.',
          tutorial:
              '# Aynı sırada duran iki liste varsa (isimler ve puanlar gibi), range() ile index üzerinden ikisine de aynı anda erişebilirsin.\n\nisimler = ["Ali", "Ayşe"]\npuanlar = [70, 95]\nfor i in range(2):\n    print(f"{isimler[i]}: {puanlar[i]}")',
          starterCode:
              'isimler = ["Ali", "Ayşe", "Can"]\npuanlar = [85, 92, 78]\n# İki listeyi aynı index ile gezip "İsim: Puan" formatında yazdır\n',
          solution:
              'isimler = ["Ali", "Ayşe", "Can"]\npuanlar = [85, 92, 78]\nfor i in range(3):\n    print(f"{isimler[i]}: {puanlar[i]}")',
          expectedOutput: 'Ali: 85\nAyşe: 92\nCan: 78',
          points: 270,
          emoji: '📋',
          order: 2,
          hints: [
            'İki liste aynı sırada duruyorsa, aynı index (i) ile ikisine de erişebilirsin: isimler[i] ve puanlar[i]',
            "for i in range(3): ile 0'dan 2'ye kadar say, listelerin uzunluğu kadar dön.",
            'for i in range(3):\n    print(f"{isimler[i]}: {puanlar[i]}")',
          ],
        ),
        LearningNode(
          id: 'n_proj_3',
          title: 'Skor Takibi',
          description:
              'Fonksiyon ve sözlüğü birlikte kullanarak bir skor tablosu güncelle.',
          tutorial:
              '# Bir fonksiyonun döndürdüğü değeri doğrudan sözlüğe geri yazabilirsin.\n\ndef puan_ekle(mevcut, eklenen):\n    return mevcut + eklenen\n\ntablo = {"Ali": 0}\ntablo["Ali"] = puan_ekle(tablo["Ali"], 10)\nprint(tablo["Ali"])',
          starterCode:
              'tablo = {"Ali": 0, "Ayşe": 0}\n# mevcut ve eklenen alan bir puan_ekle() fonksiyonu yaz\n# Ali\'ye 10 sonra 5, Ayşe\'ye 8 puan ekle, ikisini de yazdır\n',
          solution:
              'def puan_ekle(mevcut, eklenen):\n    return mevcut + eklenen\n\ntablo = {"Ali": 0, "Ayşe": 0}\ntablo["Ali"] = puan_ekle(tablo["Ali"], 10)\ntablo["Ali"] = puan_ekle(tablo["Ali"], 5)\ntablo["Ayşe"] = puan_ekle(tablo["Ayşe"], 8)\nprint(tablo["Ali"])\nprint(tablo["Ayşe"])',
          expectedOutput: '15\n8',
          points: 280,
          emoji: '🏅',
          order: 3,
          hints: [
            'Bir fonksiyonun return ettiği değeri doğrudan bir sözlük anahtarına geri yazabilirsin: tablo["Ali"] = fonksiyon(...)',
            'Mevcut değeri okuyup fonksiyona gönder, dönen sonucu aynı anahtara geri ata: tablo["Ali"] = puan_ekle(tablo["Ali"], 10)',
            'def puan_ekle(mevcut, eklenen):\n    return mevcut + eklenen — sonra bu fonksiyonu sözlük güncellerken çağır.',
          ],
        ),
      ],
    ),
  ];
}
