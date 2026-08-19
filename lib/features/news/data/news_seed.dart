import 'package:neuroup/features/news/domain/entities/news_article.dart';

/// Tüm demo haberlerin kaynağı — hem Firestore hem InMemory repo kullanır.
class NewsSeed {
  NewsSeed._();

  static List<NewsArticle> all() => _defaultNews();

  static List<NewsArticle> _defaultNews() {
    final now = DateTime.now();
    DateTime ago(Duration d) => now.subtract(d);
    return [
      // SON DAKİKA — KIRMIZI
      NewsArticle(
        id: 'n_ai_education',
        title: 'Yapay Zekâ Eğitimde Devrim Yaratıyor',
        summary:
            'Okullar kişiselleştirilmiş öğrenme için AI araçlarını benimsiyor. '
            'Pilot uygulamada başarı %30 arttı.',
        body:
            'Son yıllarda eğitim kurumları, öğrencilerin bireysel öğrenme hızına '
            'göre içerik sunan yapay zekâ destekli platformlara yöneliyor. '
            "Araştırmalar, AI destekli öğrenmenin öğrenci başarısını %30'a kadar "
            "artırabileceğini gösteriyor.\n\nÖğretmenler ise AI'ın kendilerini "
            'değil, tekrarlayan görevleri üstlenmesinden memnun. '
            "Türkiye'den 12 üniversite de programa katıldı.",
        source: 'Eğitim Teknolojileri',
        sourceUrl: 'https://example.com/ai-education',
        category: NewsCategory.education,
        publishedAt: ago(const Duration(minutes: 30)),
        isBreaking: true,
        priority: NewsPriority.critical,
      ),
      // ÖNEMLİ — TURUNCU
      NewsArticle(
        id: 'n_quantum_breakthrough',
        title: 'Kuantum Bilgisayarlarda Yeni Rekor',
        summary:
            'Araştırmacılar 1000 kübitlik stabil bir sistem duyurdu. '
            'Klasik süper bilgisayarları 100 kat aşıyor.',
        body:
            'Bilim insanları, kuantum hesaplamada yeni bir dönüm noktasına '
            'ulaştıklarını açıkladı. Yeni sistem, belirli hesaplama görevlerinde '
            'geleneksel süper bilgisayarları 100 kat aşıyor. '
            'IBM ve Google ortak çalışması sonucu elde edilen başarı, '
            'ilaç geliştirme ve kriptografi alanlarında devrim yaratabilir.',
        source: 'Bilim Günlüğü',
        sourceUrl: 'https://example.com/quantum',
        category: NewsCategory.science,
        publishedAt: ago(const Duration(hours: 2)),
        priority: NewsPriority.high,
      ),
      // STANDART — MAVİ
      NewsArticle(
        id: 'n_flutter_4',
        title: 'Flutter 4.0 Duyuruldu',
        summary:
            'Yeni sürümde performans iyileştirmeleri ve yeni widgetlar var.',
        body:
            "Google, Flutter 4.0'ı duyurdu. Yeni sürümde Material 3 iyileştirmeleri, "
            'daha hızlı render motoru ve gelişmiş erişilebilirlik destekleri yer '
            'alıyor. Impeller motoru artık tüm platformlarda varsayılan. '
            'Yeni "Universal" widget ailesi tüm platformlarda tutarlı görünüm sağlıyor.',
        source: 'Tech News',
        sourceUrl: 'https://example.com/flutter-4',
        category: NewsCategory.technology,
        publishedAt: ago(const Duration(hours: 5)),
      ),
      // BİLGİ — GRİ
      NewsArticle(
        id: 'n_space_mission',
        title: 'Mars Görevi Başarıyla Başladı',
        summary:
            'Yeni Mars keşif aracı yola çıktı. 7 ay sonra kızıl gezegene varacak.',
        body:
            'Uluslararası uzay ajansı, yeni nesil Mars keşif aracını başarıyla '
            'fırlattı. Araç, Mars yüzeyinde su izleri arayacak ve olası yaşam '
            "belirtilerini inceleyecek. 2030 yılında Dünya'ya örneklerle "
            'dönmesi planlanıyor.',
        source: 'Uzay Ajansı',
        sourceUrl: 'https://example.com/mars',
        category: NewsCategory.science,
        publishedAt: ago(const Duration(hours: 8)),
        priority: NewsPriority.info,
      ),
      // İLHAM — YEŞİL
      NewsArticle(
        id: 'n_olympics',
        title: 'Olimpiyat Hazırlıkları Tam Gaz',
        summary:
            'Ev sahibi şehir, açılış töreni için son hazırlıklarını yapıyor. '
            '200+ ülke katılıyor.',
        body:
            'Olimpiyat komitesi, açılış töreninin teknoloji ve kültürü '
            "buluşturacağını açıkladı. 200'den fazla ülke katılım için kayıt "
            "yaptırdı. Türkiye'den 54 sporcu yarışacak. Açılışta 5000 drone "
            'gösterisi planlanıyor.',
        source: 'Spor Haber',
        sourceUrl: 'https://example.com/olympics',
        category: NewsCategory.sports,
        publishedAt: ago(const Duration(days: 1)),
        priority: NewsPriority.positive,
      ),
      // ÖNEMLİ — TURUNCU
      NewsArticle(
        id: 'n_climate_summit',
        title: 'İklim Zirvesi Tarihi Kararlar Aldı',
        summary:
            'Dünya liderleri karbon emisyonu hedeflerini sıkılaştırdı. '
            "2030'a kadar %50 azalma sözü.",
        body:
            "İklim zirvesinde 50'den fazla ülke, 2030 yılına kadar karbon "
            'emisyonlarını yarıya indirme taahhüdünde bulundu. Uzmanlar, '
            'taahhütlerin uygulanması için daha somut adımlar gerektiğini '
            'söylüyor. Türkiye, 2053 için net sıfır hedefi koydu.',
        source: 'Dünya Haber',
        sourceUrl: 'https://example.com/climate',
        category: NewsCategory.world,
        publishedAt: ago(const Duration(days: 2)),
        priority: NewsPriority.high,
      ),
      // BİLGİ
      NewsArticle(
        id: 'n_tech_breakthrough',
        title: 'Yeni Pil Teknolojisi 10 Dakikada Şarj Oluyor',
        summary:
            'Araştırmacılar katı hal pillerinde devrim niteliğinde bir adım attı.',
        body:
            'MIT araştırmacıları, yeni nesil katı hal pil teknolojisiyle 10 '
            "dakikalık şarjda %80 kapasiteye ulaştı. Teknoloji 2027'de "
            'ticarileşecek. Elektrikli araçlar için çığır açan gelişme olarak '
            'değerlendiriliyor.',
        source: 'Tech Review',
        sourceUrl: 'https://example.com/solid-state-battery',
        category: NewsCategory.technology,
        publishedAt: ago(const Duration(hours: 12)),
        priority: NewsPriority.info,
      ),
      // STANDART
      NewsArticle(
        id: 'n_education_grants',
        title: 'STEM Eğitimi İçin Yeni Burs Programı',
        summary:
            'Hükümet 50.000 öğrenciye STEM bursu verecek. Başvurular başladı.',
        body:
            'Millî Eğitim Bakanlığı, lise düzeyindeki 50.000 öğrenciye STEM '
            'alanında burs vereceğini açıkladı. Program kapsamında robotik, '
            'kodlama ve yapay zekâ eğitimleri ücretsiz sunulacak. '
            "Başvurular 1 Aralık'a kadar devam edecek.",
        source: 'MEB',
        sourceUrl: 'https://example.com/stem-grants',
        category: NewsCategory.education,
        publishedAt: ago(const Duration(days: 1, hours: 6)),
      ),
      // İLHAM
      NewsArticle(
        id: 'n_young_coder',
        title: '14 Yaşındaki Türk Gencinden Dünya Birinciliği',
        summary:
            "Ankara'lı Zeynep, uluslararası kodlama yarışmasında altın madalya kazandı.",
        body:
            '14 yaşındaki Zeynep Demir, uluslararası genç yazılımcılar yarışmasında '
            'yapay zekâ kategorisinde birincilik elde etti. Python ile geliştirdiği '
            'erişilebilirlik uygulaması 30 ülkeden 5000 proje arasından seçildi. '
            'Zeynep: "Türk gençleri olarak dünya sahnesinde yer almak gurur verici."',
        source: 'Anadolu Ajansı',
        sourceUrl: 'https://example.com/young-coder',
        category: NewsCategory.education,
        publishedAt: ago(const Duration(days: 2, hours: 4)),
        priority: NewsPriority.positive,
      ),
      // BİLGİ
      NewsArticle(
        id: 'n_health_discovery',
        title: 'Yeni Antibiyotik Keşfedildi',
        summary:
            'Bilim insanları ilaç dirençli bakterilere karşı yeni bir antibiyotik buldu.',
        body:
            'Harvard Tıp Fakültesi araştırmacıları, ilaç dirençli bakterilere '
            'karşı etkili yeni bir antibiyotik molekülü keşfetti. "Halicin" adı '
            'verilen bileşik, 50 yıldır ilk kez keşfedilen yeni sınıf antibiyotik. '
            "Klinik denemeler 2026'da başlayacak.",
        source: 'Tıp Dünyası',
        sourceUrl: 'https://example.com/halicin',
        category: NewsCategory.science,
        publishedAt: ago(const Duration(days: 3)),
        priority: NewsPriority.info,
      ),
      // STANDART
      NewsArticle(
        id: 'n_football_derby',
        title: 'Derbi Heyecanı: Galatasaray-Fenerbahçe',
        summary: 'Bu akşam oynanacak derbide iki takım sahaya çıkıyor.',
        body:
            "Süper Lig'in en heyecanlı karşılaşması bu akşam saat 19:00'da. "
            'İki takım da galibiyet serisi yakalamak istiyor. Tribünler '
            '%100 dolu. Karşılaşmayı 50 ülkeden 200 milyon kişi izleyecek.',
        source: 'Fanatik',
        sourceUrl: 'https://example.com/derby',
        category: NewsCategory.sports,
        publishedAt: ago(const Duration(hours: 4)),
      ),
      // SON DAKİKA
      NewsArticle(
        id: 'n_earthquake_warning',
        title: 'Marmara İçin Yeni Deprem Uyarısı',
        summary:
            "Uzmanlar, Marmara Denizi'nde 7+ büyüklüğünde deprem riskinin arttığını açıkladı.",
        body:
            'Boğaziçi Üniversitesi Kandilli Rasathanesi, son verilerin Marmara '
            "Denizi'nde 7.0-7.5 büyüklüğünde bir deprem olasılığını yükselttiğini "
            'açıkladı. AFAD, hazırlık çalışmalarını hızlandırdı. Vatandaşlara '
            'deprem çantası hazırlamaları çağrısı yapıldı.',
        source: 'AFAD',
        sourceUrl: 'https://example.com/earthquake',
        category: NewsCategory.world,
        publishedAt: ago(const Duration(minutes: 15)),
        isBreaking: true,
        priority: NewsPriority.critical,
      ),
      // DEMO: TEKNOLOJİ
      NewsArticle(
        id: 'n_apple_vision',
        title: 'Apple Vision Pro 2 Tanıtıldı',
        summary:
            'Yeni nesil karma gerçeklik gözlüğü daha hafif, daha ucuz ve göz yorgunluğunu azaltıyor.',
        body:
            "Apple, dün gerçekleştirdiği etkinlikte Vision Pro 2'yi tanıttı. "
            'Yeni model önceki nesle göre %40 daha hafif, %30 daha ucuz ve '
            'göz yorgunluğunu %50 azaltan yeni Micro-OLED ekrana sahip. '
            "Türkiye'de satışa çıkış tarihi 2026 sonbaharı olarak açıklandı.",
        source: 'TechCrunch',
        sourceUrl: 'https://example.com/vision-pro-2',
        category: NewsCategory.technology,
        publishedAt: ago(const Duration(hours: 6)),
        priority: NewsPriority.high,
      ),
      // DEMO: EĞİTİM
      NewsArticle(
        id: 'n_ai_tutor',
        title: 'Yapay Zekâ Öğretmenler Sınıflarda',
        summary:
            'Millî Eğitim Bakanlığı 1000 okulda AI destekli öğretmen asistanı pilot uygulamasını başlattı.',
        body:
            'Millî Eğitim Bakanlığı, 1000 ilkokul ve ortaokulda yapay zekâ destekli '
            'öğretmen asistanı uygulamasını başlattığını duyurdu. Sistem öğrencilerin '
            'öğrenme hızını analiz ederek kişiselleştirilmiş ödev ve alıştırma öneriyor. '
            'Pilot uygulama 3 ay sürecek, başarılı olursa ülke geneline yayılacak.',
        source: 'MEB',
        sourceUrl: 'https://example.com/ai-tutor',
        category: NewsCategory.education,
        publishedAt: ago(const Duration(hours: 10)),
      ),
      // DEMO: SPOR
      NewsArticle(
        id: 'n_basketball_final',
        title: 'Basketbol Süper Kupa Finalinde Sürpriz',
        summary: "Darüşşafaka, Anadolu Efes'i 78-76 yenerek kupayı kazandı.",
        body:
            'Basketbol Süper Kupa finalinde sürpriz sonuç. Normal sezonda orta sıralarda '
            "yer alan Darüşşafaka, son çeyrekteki muhteşem geri dönüşle Anadolu Efes'i 78-76 "
            "mağlup etti. Karşılaşmanın MVP'si 24 sayı atan genç oyuncu oldu. "
            "Kupa töreni önümüzdeki hafta İstanbul'da yapılacak.",
        source: 'Sporx',
        sourceUrl: 'https://example.com/basketball-final',
        category: NewsCategory.sports,
        publishedAt: ago(const Duration(hours: 14)),
        priority: NewsPriority.positive,
      ),
      // DEMO: TEKNOLOJİ - Türk Startup
      NewsArticle(
        id: 'n_turkish_ai_startup',
        title: r"Türk Yapay Zekâ Startup'ı 50M$ Yatırım Aldı",
        summary:
            "İstanbul merkezli Neuroup, ABD ve Avrupa'dan yatırımcılardan 50 milyon dolar fon topladı.",
        body:
            "Türkiye'nin önde gelen yapay zekâ eğitim platformlarından Neuroup, "
            'Seri B yatırım turunu 50 milyon dolarla kapattığını duyurdu. Yatırımcılar arasında '
            "ABD'li Andreessen Horowitz ve Avrupa'lı Index Ventures yer alıyor. "
            'Şirket, fonu yeni pazarlara açılmak ve ekibini büyütmek için kullanacak. '
            'CEO Mehmet Yılmaz: "Türkiye\'den dünyaya yapay zekâ ihraç ediyoruz."',
        source: 'Webrazzi',
        sourceUrl: 'https://example.com/neuroup-funding',
        category: NewsCategory.technology,
        publishedAt: ago(const Duration(hours: 3)),
        priority: NewsPriority.positive,
      ),
      // DEMO: DÜNYA
      NewsArticle(
        id: 'n_un_summit',
        title: 'BM İklim Zirvesi Sonuçlandı',
        summary:
            "50 ülke 2030 karbon hedeflerini sıkılaştırdı. Türkiye 'yeşil mutabakat' imzaladı.",
        body:
            "Birleşmiş Milletler İklim Zirvesi dün sona erdi. 50'den fazla ülke, "
            '2030 yılına kadar karbon emisyonlarını yarıya indirme taahhüdünde bulundu. '
            "Türkiye, AB ile 'Yeşil Mutabakat' anlaşmasını imzalayarak Avrupa pazarına "
            'çevreci ürünlerle entegre olma yolunda önemli bir adım attı. Anlaşma kapsamında '
            "Türkiye 2053'e kadar net sıfır emisyon hedefi koydu.",
        source: 'Anadolu Ajansı',
        sourceUrl: 'https://example.com/un-climate',
        category: NewsCategory.world,
        publishedAt: ago(const Duration(hours: 18)),
        priority: NewsPriority.info,
      ),
      // DEMO: EĞİTİM - YKS sonuçları
      NewsArticle(
        id: 'n_yks_results',
        title: 'YKS Sonuçları Açıklandı',
        summary:
            "2.5 milyon adayın ter döktüğü YKS'de sayısal puan türünde birinciliği İstanbul Fen Lisesi öğrencisi kazandı.",
        body:
            'Ölçme, Seçme ve Yerleştirme Merkezi (ÖSYM), Yükseköğretim Kurumları Sınavı '
            'sonuçlarını açıkladı. Bu yıl 2.5 milyon aday başvurdu. Sayısal puan türünde '
            'birinci İstanbul Fen Lisesi öğrencisi oldu. EA puan türünde birinciliği ise '
            "Ankara'da bir özel okul öğrencisi kazandı. Tıp fakülteleri için taban puanı "
            '530.42, mühendislik için 489.15 olarak belirlendi. Sonuçlara göre 1.2 milyon '
            'aday tercih yapabilecek.',
        source: 'ÖSYM',
        sourceUrl: 'https://example.com/yks-results',
        category: NewsCategory.education,
        publishedAt: ago(const Duration(hours: 4)),
        priority: NewsPriority.high,
      ),
      // DEMO: TEKNOLOJİ - Yapay zeka haber
      NewsArticle(
        id: 'n_ai_health_diagnosis',
        title: 'Yapay Zekâ Kanser Teşhisinde Doktorlardan Daha Başarılı',
        summary:
            "Google DeepMind'ın yeni AI modeli meme kanseri teşhisinde radyologlardan %11.5 daha başarılı.",
        body:
            'Google DeepMind ve Imperial College London ortaklığıyla geliştirilen '
            'yapay zekâ modeli, meme kanseri teşhisinde deneyimli radyologlardan daha '
            'başarılı sonuç verdi. 28 bin kadın mamografisi üzerinde eğitilen model, '
            'yanlış pozitif oranını %5.7 ve yanlış negatif oranını %9.4 azalttı. '
            'Araştırmacılar yapay zekanın radyologların yerini almayacağını, '
            'tam tersine onlara yardımcı olacağını söyledi.',
        source: 'Nature',
        sourceUrl: 'https://example.com/ai-cancer',
        category: NewsCategory.technology,
        publishedAt: ago(const Duration(hours: 7)),
      ),
      // DEMO: BİLİM - Mars bulgusu
      NewsArticle(
        id: 'n_mars_water',
        title: "Mars'ta Yeraltı Gölleri Keşfedildi",
        summary:
            "Avrupa Uzay Ajansı'nın Mars Express aracı, kızıl gezegenin güney kutbunda sıvı su bulunduğuna dair yeni kanıtlar elde etti.",
        body:
            "Avrupa Uzay Ajansı ESA'nın Mars Express misyonu, Mars'ın güney kutbu "
            'bölgesinde yeraltında birkaç küçük tuzlu su gölü keşfettiğini duyurdu. '
            'MARSIS radarı ile elde edilen veriler, 1.5 km derinlikte sıvı su olduğunu gösteriyor. '
            "Bu keşif, Mars'ta mikrobik yaşam olabileceğine dair en güçlü kanıt olarak "
            "değerlendiriliyor. NASA'nın 2030'daki Mars Sample Return misyonu bu bölgeden "
            'numune toplamayı hedefliyor.',
        source: 'ESA',
        sourceUrl: 'https://example.com/mars-water',
        category: NewsCategory.science,
        publishedAt: ago(const Duration(hours: 11)),
        priority: NewsPriority.positive,
      ),
      // DEMO: SPOR - Süper Lig
      NewsArticle(
        id: 'n_super_derby',
        title: "Süper Lig'de Dev Derbi Yarın",
        summary:
            "Galatasaray ve Fenerbahçe yarın akşam saat 19:00'da karşı karşıya geliyor. Tribünler tamamen dolu.",
        body:
            "Süper Lig'in en heyecanlı karşılaşması yarın akşam RAMS Park'ta oynanacak. "
            'İki takım da sezonun ilk yarısını galibiyetle kapatmak istiyor. '
            "Galatasaray'da sakatlığı bulunan yıldız oyuncunun durumu maç saatinde belli "
            'olacak. Fenerbahçe ise son 5 maçta 4 galibiyet aldı. Karşılaşmayı 60 ülkeden '
            'yaklaşık 250 milyon kişinin izlemesi bekleniyor. Biletler karaborsada 5 katına '
            'kadar satıldı.',
        source: 'Bein Sports',
        sourceUrl: 'https://example.com/super-derby',
        category: NewsCategory.sports,
        publishedAt: ago(const Duration(minutes: 45)),
        priority: NewsPriority.high,
      ),
    ];
  }
}
