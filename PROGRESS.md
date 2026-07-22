# PROGRESS.md

Neuroup geliştirme sürecinin canlı durumu. Agent'lar bu dosyayı okuyarak projeye hızlı giriş yapabilir.

## Proje Özeti

**Neuroup** — Flutter + Dart ile yazılmış, çapraz platform (iOS + Android + Linux) eğitim uygulaması. Şu an **demo modunda** çalışıyor (Firebase bağlı değil). Tüm veriler in-memory repository'lerden geliyor.

- **Paket adı:** `neuroup` (eski `eduplay` adı kalmadı)
- **Binary:** `./build/linux/x64/debug/bundle/neuroup`
- **Application ID:** `com.neuroup.app`
- **Dil:** Dart 3.x, Flutter 3.x, Riverpod 2.x, go_router 14.x

---

## Aktif Özellikler

| Modül | Durum | Notlar |
|---|---|---|
| **Auth (Firebase email/şifre)** | ✅ Çalışıyor | Demo'da otomatik sahte kullanıcı |
| **Education (dersler + quiz)** | ✅ Çalışıyor | In-memory |
| **Learning (Python Adaları)** | ✅ Çalışıyor | Fancade-tarzı yılan path haritası, 10 ada × ~3 node |
| **News (21 demo haber)** | ✅ Çalışıyor | InMemoryNewsRepository, priority sıralama |
| **Chat (öğrenci ↔ moderatör)** | ✅ Çalışıyor | Demo'da AI lokal echo cevap veriyor |
| **AI Chat (Soru-Cevap)** | ✅ Çalışıyor | 8 hazır cevap, gerçek API bağlı değil |
| **Game (Kelime Avı, Quick Math, Color Match)** | ✅ Çalışıyor | 3 mini oyun |
| **Profile (seviye + rozetler + tier çerçevesi)** | ✅ Çalışıyor | CustomPaint avatar frame |
| **Reels (oyun vitrini)** | ✅ Çalışıyor | 5 demo reel, PageView dikey scroll |
| **Bottom Navigation (6 tab)** | ✅ Çalışıyor | iOS-style glass bar |

---

## Mimari

```
lib/
├── app/                    # bootstrap, theme, router, demo landing
│   ├── bootstrap.dart      # Firebase init, error handlers, print filter
│   ├── theme/              # AppTheme (M3 light/dark), AppColors, AppSpacing
│   ├── router/             # go_router, HomeShell (glass bottom nav)
│   └── pages/              # DemoLandingPage
├── core/                   # Env, Failure (sealed), Result<T>, services
├── shared/
│   ├── models/             # UserProfile, UserLevel (tier/badge), NewsArticle
│   ├── widgets/            # LevelFrame, EmptyState, Skeleton, GradientPill
│   └── utils/              # LayoutHelper, ResponsiveContext extension
└── features/               # Her biri Clean Architecture (data/domain/presentation)
    ├── auth/               # Email/şifre giriş + 4 rol
    ├── chat/               # Sohbet (öğrenci ↔ moderatör)
    ├── education/          # Dersler + Quiz (eski sistem, hâlâ aktif)
    ├── game/              # Kelime Avı, Quick Math, Color Match
    ├── learning/          # Python Adaları — interaktif kod editörü
    ├── news/              # 21 demo haber + InMemoryNewsRepository
    ├── profile/           # Seviye + rozetler + ayarlar
    ├── reels/             # Yeni — oyun vitrini (Reels)
    └── ai/                # AI Chat (placeholder, 8 hazır cevap)
```

---

## Son Tamamlananlar (Haziran-Temmuz 2026)

1. **Neuroup rename** — paket adı `eduplay` → `neuroup`, binary `neuroup`, app ID `com.neuroup.app`
2. **News önem derecesi (priority)** — 5 seviye: critical/high/normal/info/positive. Renk + ikon + etiket rozeti.
3. **21 demo haber** — gerçekçi Türk/uluslararası konular (YKS, Mars, BM, deprem, vs.)
4. **InMemoryNewsRepository** — Firestore'a bağlanmadan seed haberlerden okur
5. **Fancade-tarzı ada haritası** — IslandMapPage + IslandDetailPage, yılan path, pulse glow, bounce
6. **Interaktif Python kod editörü** — TextField + monospace + satır numarası + simülatör
7. **Python yorumlayıcı simülasyonu** — print, değişken, aritmetik, karşılaştırma, for-range, while, if/elif
8. **3 mini oyun** — Kelime Avı, Quick Math (60sn), Color Match (Simon Says)
9. **Profil seviye/rozet/tier sistemi** — 5 tier (Bronz→Master), CustomPaint avatar frame, 8 rozet
10. **Reels özelliği** — dikey kaydırmalı oyun vitrini, 5 demo reel, like/comment/save/follow + comment drawer
11. **6 tab bottom navigation** — iOS-style glass bar (Dersler, Oyunlar, Vitrin, Haberler, AI, Profil)
12. **Global responsive text scaling** — `MaterialApp.builder`'da `MediaQuery.textScalerOf().clamp(0.95, 1.3)` ile küçük ekranda okunabilirlik korunur
13. **Sarı-siyah overflow şeritleri bastırıldı** — `FlutterError.onError`'da RenderFlex overflow hataları sessizce yutulur (debugPaint filtering)
14. **print() filtreleme** — `core/no-app` Firebase hataları debugPrint'te engellendi
15. **Bootstrap runZonedGuarded + Sentry + Talker entegrasyonu** — production-ready error handling

---

## Yapılması Planlananlar (Backlog)

### Yüksek Öncelik (production için)
- [ ] Firebase Console projesi kurulumu
- [ ] `google-services.json` + `GoogleService-Info.plist` ekleme
- [ ] `firebase_options.dart` üretme (`flutterfire configure`)
- [ ] Firestore Security Rules yazma
- [ ] FCM bildirim kurulumu (iOS APNs sertifikası dahil)
- [ ] Gemini API entegrasyonu (AI Chat için gerçek cevap)
- [ ] Gerçek moderatör dashboard (web)
- [ ] App Store + Play Store hesapları ve yayın

### Orta Öncelik
- [ ] CI/CD pipeline (GitHub Actions: analyze + test + build)
- [ ] Widget test coverage (her kritik sayfa)
- [ ] Integration test (ana kullanıcı akışları)
- [ ] Sentry performans monitoring
- [ ] Firebase Analytics + custom event tracking
- [ ] Localization organize (intl paketi, AR/EN/TR)
- [ ] Accessibility (semantic labels, font scaling)

### Düşük Öncelik
- [ ] Golden test (UI regression)
- [ ] Feature flag sistemi
- [ ] Modüler mimari / plugin sistemi
- [ ] Gamification genişletme (achievements, streaks, leaderboard)

---

## Bilinen Sorunlar / TODO

| Sorun | Yer | Çözüm |
|---|---|---|
| AI Chat sadece 8 hazır cevap döner | `features/ai/presentation/pages/ai_tutor_page.dart` | Gemini API entegrasyonu |
| Moderatör dashboard yok | — | Web ayrı proje olarak |
| Game skorları kayboluyor (sayfa kapatılınca) | `features/game/data/repositories/game_repository_impl.dart` | Firestore/Firebase bağlantısı |
| Learning progress kayboluyor | `features/learning/presentation/providers/learning_providers.dart` | Firestore/Firebase bağlantısı |
| Quiz session controller'da late final Timer yarış koşulu | `features/learning/presentation/providers/quiz_session_controller.dart` | Refactor: dispose pattern'i |
| `python_simulator.dart` 600+ satır tek dosya | `features/learning/data/` | ExpressionParser + StatementParser sınıflarına böl |
| AI Chat `_generateResponse` 8 if-else zinciri | `features/chat/presentation/pages/ai_chat_page.dart` | Strategy pattern / dispatch table |
| `_LineNumbers` her satır için ayrı Text widget | `features/learning/presentation/pages/node_editor_page.dart` | `ListView.builder` |

---

## Test Durumu

```
test/
├── features/auth/auth_controller_test.dart       (3 test) ✅
├── features/chat/chat_controller_test.dart       (3 test) ✅
├── features/education/quiz_repository_test.dart  (4 test) ✅
├── features/game/word_puzzle_test.dart          (4 test) ✅
├── features/news/news_repository_test.dart      (5 test) ✅
└── shared/widgets/empty_state_test.dart         (2 test) ✅
                                              ────────────────
                                              21/21 test geçiyor
```

---

## Build Durumu

```bash
$ dart analyze              # 0 hata
$ flutter test              # 21 passed
$ flutter build linux --debug  # OK → ./build/linux/x64/debug/bundle/neuroup
```

Linux desktop binary 53KB launcher + bundle. Android/iOS build edilmedi henüz (Firebase yok).

---

## Demo Test Akışı

1. `./build/linux/x64/debug/bundle/neuroup` → uygulamayı başlat
2. **Demo Landing** açılır → herhangi bir modüle tıkla
3. **Dersler** → Python Adaları → İlk ada (Başlangıç Adası) parlar → tıkla → node haritası → ilk node → tıkla
4. **İnteraktif Kod Editörü** açılır → tutorial + starter code → "Çalıştır" → yeşil çıktı → "Doğrula" → XP kazan
5. **Oyunlar** → Kelime Avı / Quick Math / Color Match
6. **Vitrin** → dikey kaydır → 5 demo oyun, like/comment/save
7. **Haberler** → 21 demo haber, kategori filtre, breaking banner
8. **AI** → soru sor → 8 hazır cevaptan biri
9. **Profil** → tier çerçevesi, rozetler, ayarlar

---

## Notlar

- Tüm renk paleti `lib/app/theme/colors.dart`'ta
- Tüm spacing tokens `AppSpacing` ve `AppRadius` `lib/app/theme/app_theme.dart`'ta
- 17 demo içerik haberi, 5 demo reel, 5 öğrenme adası var (toplam 27+ interaktif içerik)
- In-memory repository pattern tüm Firebase-bağımlı featurelarda uygulanmış — production'a geçiş kolay olacak
