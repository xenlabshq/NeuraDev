# Neuroup

Flutter tabanlı, **Python Adaları (3D snake-path harita)**, **Reels (kısa video)**, **Destek sohbeti** ve **Haberler** içeren eğitim uygulaması. iOS, Android ve Linux masaüstünde çalışır.

> Paket adı: `neuroup` · Binary adı: `neuroup` · Application ID: `com.neuroup.app`

## Mimari

- **State management:** Riverpod 2.6
- **Routing:** go_router 14 (ShellRoute tabanlı)
- **Backend:** Firebase (Auth, Firestore, Storage, Messaging, Analytics) — opsiyonel; `Env.firebaseConfigured=false` iken in-memory fallback çalışır
- **Storage:** SharedPreferences (ayarlar) + Hive (cache)
- **Tasarım sistemi:** Tema-aware token'lar (`AppColors.tokensOf(context)`) — light/dark
- **Mimari pattern:** Feature-first Clean Architecture
  - `lib/core/` — çapraz kesiti (env, failures, services, providers, utils)
  - `lib/shared/` — ortak widget/modeller
  - `lib/features/{auth,learning,news,chat,ai,profile,reels}/` — her feature
    - `data/` — veri kaynakları, modeller, repository implementasyonları + **in-memory fallback**
    - `domain/` — entity, soyut repo, use-case
    - `presentation/` — provider, sayfa, widget

## Features

| Modül | Açıklama |
|---|---|
| **Learning** | 3D izometrik ada haritası, snake-path node bağlantıları, Python editör + simülatör, XP/streak ilerlemesi (Hive cache) |
| **Reels** | Dikey kısa içerik akışı, yorum çekmecesi, like/paylaş |
| **News** | Kategori filtreleri, pinned SliverAppBar, haber detay sayfası |
| **Chat** | Destek sohbeti (öğrenci/moderatör), kanal listesi, gerçek-zamanlı mesajlaşma |
| **AI** | Yerel komut-tabanlı AI asistan (offline demo modda çalışır) |
| **Auth** | Firebase Auth (email/password) + in-memory fallback |
| **Profile** | XP, seviye (Bronze→Master), rozetler, ayarlar (tema/dil/bildirim) |

## Persistence

- **SharedPreferences** — `AppSettings` (tema, dil, bildirim, metin ölçeği)
- **Hive** — `app_settings_box`, `learning_progress_box`, `news_cache_box`

## Başlarken

```bash
git clone https://github.com/xenlabshq/NeuraDev.git
cd NeuraDev
flutter pub get
cp .env.example .env   # isteğe bağlı — Firebase olmadan da çalışır
flutter run -d linux   # veya flutter run -d <device-id>
```

> Firebase olmadan (demo modda) uygulama tüm özellikleri in-memory repo'lar ile çalıştırır. Production için `google-services.json` + `firebase_options.dart` ekleyip `Env.firebaseConfigured = true` yapın.

## Komutlar (Makefile)

```bash
make get           # bağımlılıklar
make analyze       # dart analyze
make test          # unit + widget testleri (34+)
make format        # dart format
make build-apk     # Android release APK
make build-linux   # Linux release bundle
```

## Doğrulama (AGENTS.md)

```bash
dart analyze                     # 0 errors
flutter test                     # 34+ tests pass
flutter build linux --debug      # ./build/linux/x64/debug/bundle/neuroup
flutter build apk --release      # ./build/app/outputs/flutter-apk/app-release.apk
```

## Release v0.2.0 (Mevcut)

- ✅ AppSettings persistence (SharedPreferences)
- ✅ Hive cache (3 kutu, LearningProgress ilerlemesi)
- ✅ LoginUseCase (domain katmanı, validasyon)
- 📦 Android APK (universal) + split-per-abi debug APKs
- 🐧 Linux bundle (extract & run `./neuroup`)

## Yol Haritası

- [x] Proje iskeleti, tema (light/dark tokens), router
- [x] Auth (Firebase + in-memory)
- [x] Learning: ada haritası, node editör, Python simülatör, ilerleme (Hive)
- [x] News: feed + filtreler + detay sayfası
- [x] Chat: destek sohbeti + AI asistan paneli
- [x] Reels: kısa içerik akışı
- [x] Profile: XP, seviye, rozetler
- [x] Persistence: SharedPreferences + Hive
- [x] Release v0.1.0, v0.2.0 (GitHub Releases)
- [ ] Production Firebase config
- [ ] CI/CD (GitHub Actions)
- [ ] App Store & Play Store yayını

## Lisans

Private — © 2026 NeuraDev