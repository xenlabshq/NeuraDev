import '../domain/entities/game_reel.dart';

List<GameReel> _seedReels() => [
      GameReel(
        id: 'reel_loop',
        devName: 'PixelKerem',
        devTag: '@pixelkerem',
        title: 'Loop Kaçışı',
        caption:
            'Döngülerle labirentten kaç, her turda zorluk artıyor. Yeni bölüm bugün eklendi.',
        tags: '#döngü #labirent #indiedev',
        accent: ReelAccent.gold,
        symbols: ['{', '}', 'for', '01'],
        hud: 'Bölüm 3 · Skor 240',
        likes: 1240,
        gameUrl: '/lessons',
        comments: const [
          ReelComment(
            user: '@elif.codes',
            text: '3. bölümde gerçekten takıldım, harika zorluk!',
          ),
          ReelComment(
            user: '@mertdev',
            text: 'Grafikler çok temiz olmuş, tebrikler.',
          ),
          ReelComment(
            user: '@zeynepp',
            text: 'Sonraki bölüm ne zaman geliyor?',
          ),
        ],
      ),
      GameReel(
        id: 'reel_function',
        devName: 'NisaBuilds',
        devTag: '@nisabuilds',
        title: 'Fonksiyon Fırtınası',
        caption:
            'Fonksiyon yazarak canavarları yenmen gereken bir kart oyunu. Beta şu an açık.',
        tags: '#fonksiyon #kartoyunu #beta',
        accent: ReelAccent.mint,
        symbols: ['ƒ', '()', 'return', 'λ'],
        hud: 'Beta v0.4 · 12 Kart',
        likes: 860,
        gameUrl: '/lessons',
        comments: const [
          ReelComment(
            user: '@kaanb',
            text: 'Kart tasarımları çok yaratıcı olmuş.',
          ),
          ReelComment(
            user: '@aslicode',
            text: 'return kartını nasıl açıyoruz?',
          ),
        ],
      ),
      GameReel(
        id: 'reel_recursion',
        devName: 'ByteAtelye',
        devTag: '@byteatelye',
        title: 'Recursion Kulesi',
        caption:
            'Her kat bir önceki katın fonksiyonunu çağırıyor. Kaç kata çıkabilirsin?',
        tags: '#recursion #bulmaca',
        accent: ReelAccent.coral,
        symbols: ['f(n)', '∞', 'n-1', 'Σ'],
        hud: 'Kat 7 · Rekor 12',
        likes: 2100,
        gameUrl: '/lessons',
        comments: const [
          ReelComment(
            user: '@devrimm',
            text: 'Kafamı çok karıştırdı ama bağımlılık yaptı.',
          ),
          ReelComment(
            user: '@sudenaz',
            text: '7. katta stack overflow yedim.',
          ),
          ReelComment(
            user: '@onur.k',
            text: 'Müzikleri de çok iyi olmuş.',
          ),
        ],
      ),
      GameReel(
        id: 'reel_variables',
        devName: 'KodcuAyse',
        devTag: '@kodcuayse',
        title: 'Değişken Dedektifi',
        caption:
            'Kodda gizlenen hatalı değişkeni bul, dedektif rozetini kazan. Yeni başlayanlar için ideal.',
        tags: '#başlangıç #dedektif',
        accent: ReelAccent.violet,
        symbols: ['x=', 'bool', 'int', '?'],
        hud: 'Vaka 5 · Rozet 2',
        likes: 530,
        gameUrl: '/lessons',
        comments: const [
          ReelComment(
            user: '@minik.kod',
            text: 'İlk kod oyunum, çok keyifli!',
          ),
          ReelComment(
            user: '@fatihh',
            text: '5. vaka biraz zormuş, ipucu lazım.',
          ),
        ],
      ),
      GameReel(
        id: 'reel_binary',
        devName: 'SigmaLabs',
        devTag: '@sigmalabs',
        title: 'Binary Arena',
        caption:
            'İkili sayı sistemiyle rakiplerini alt et, haftalık turnuva başladı.',
        tags: '#binary #turnuva #pvp',
        accent: ReelAccent.gold,
        symbols: ['0', '1', '<<', '>>'],
        hud: 'Turnuva · 128 Oyuncu',
        likes: 3400,
        gameUrl: '/lessons',
        comments: const [
          ReelComment(
            user: '@turnuvaci',
            text: 'Bu hafta finale kaldım!',
          ),
          ReelComment(
            user: '@ece.dev',
            text: 'PvP dengesi çok iyi ayarlanmış.',
          ),
          ReelComment(
            user: '@baran99',
            text: 'Ödül havuzu ne zaman açıklanıyor?',
          ),
        ],
      ),
    ];

class ReelsSeed {
  ReelsSeed._();
  static List<GameReel> all() => _seedReels();
}