# EduPlay

Eğitim, haber, sohbet ve oyunları birleştiren, iOS ve Android için Flutter tabanlı çapraz platform mobil uygulama.

## Mimari

- **State management:** Riverpod 2.x
- **Routing:** go_router
- **Backend:** Firebase (Auth, Firestore, Storage, Messaging)
- **Chat:** Stream Chat
- **Oyun:** Flame
- **AI:** Google Gemini / OpenAI
- **Mimari pattern:** Feature-first Clean Architecture
  - `lib/core/` — çapraz kesiti (env, failures, services, providers)
  - `lib/shared/` — ortak widget/modeller
  - `lib/features/{auth,education,news,chat,game,ai}/` — her feature
    - `data/` — veri kaynakları, modeller, repo implementasyonları
    - `domain/` — entity, soyut repo, use-case
    - `presentation/` — provider, sayfa, widget

## Başlarken

```bash
cd eduplay
flutter pub get
cp .env.example .env   # doldurun
flutter run
```

## Komutlar (Makefile)

```bash
make get          # bağımlılıklar
make analyze      # dart analyze
make test         # unit + widget testleri
make format       # dart format
make build-apk    # Android release
make build-ios    # iOS release
```

## Test

```bash
flutter test
```

## Yol Haritası

- [x] Proje iskeleti, tema, router
- [x] Auth (Firebase)
- [ ] Education: dersler, quiz, ilerleme
- [ ] News: feed + FCM
- [ ] Chat: Stream Chat entegrasyonu
- [ ] Game: Flame mini oyunlar
- [ ] AI: Gemini/OpenAI asistan
- [ ] CI/CD, Sentry, Firebase Analytics
- [ ] App Store & Play Store yayını
