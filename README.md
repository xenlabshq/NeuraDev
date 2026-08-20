# Neuroup

Flutter tabanlı, **Python Adaları (3D snake-path harita)**, **Reels (kısa video)**, **Destek sohbeti** ve **Haberler** içeren eğitim uygulaması. iOS, Android ve Linux masaüstünde çalışır.

> Paket adı: `neuroup` · Binary adı: `neuroup` · Application ID: `com.neuroup.app`

## Mimari

- **State management:** Riverpod 2.6
- **Routing:** go_router 14 (ShellRoute tabanlı, auth durumuna göre `redirect`)
- **Backend:** Firebase (Auth, Firestore, Storage, Messaging, Analytics) — `Env.firebaseConfigured=false` iken (varsayılan dev build) in-memory fallback çalışır; production build'lerde gerçek Firebase projesine bağlanır
- **Storage:** SharedPreferences (ayarlar) + Hive (cache)
- **Tasarım sistemi:** Tema-aware token'lar (`AppColors.tokensOf(context)`) — light/dark
- **Mimari pattern:** Feature-first Clean Architecture
  - `lib/core/` — çapraz kesiti (env, failures, services, providers, utils)
  - `lib/shared/` — ortak widget/modeller
  - `lib/features/{admin,auth,learning,news,chat,ai,profile,reels}/` — her feature
    - `data/` — veri kaynakları, modeller, repository implementasyonları + **in-memory fallback**
    - `domain/` — entity, soyut repo, use-case
    - `presentation/` — provider, sayfa, widget

## Features

| Modül | Açıklama |
|---|---|
| **Learning** | 3D izometrik ada haritası, snake-path node bağlantıları, Python editör + simülatör (liste/dict/fonksiyon/string/dosya desteği), canlı değişken izleyici, XP/streak ilerlemesi (Hive cache) |
| **Reels** | Dikey kısa içerik akışı, yorum çekmecesi, like/paylaş — giriş yapmadan da gezilebilir. Giriş yapmış kullanıcılar kendi oyunlarının linkini gönderebilir (Firestore'a gerçek zamanlı yazılır) |
| **News** | Kategori filtreleri, pinned SliverAppBar, haber detay sayfası. Moderatör/admin rolündeki kullanıcılar uygulama içinden haber ekleyip düzenleyip silebilir |
| **Chat** | Destek sohbeti (öğrenci/moderatör), kanal listesi, gerçek-zamanlı mesajlaşma |
| **AI** | Yerel komut-tabanlı AI asistan (offline demo modda çalışır) |
| **Auth** | Firebase Auth: e-posta/şifre + Google ile giriş, şifre sıfırlama e-postası, rol tabanlı yetkilendirme (`users/{uid}.role`, Firestore Security Rules ile sunucu tarafında da zorunlu kılınır) |
| **Admin** | Sadece `admin` rolündeki kullanıcılara görünen Yönetim Paneli — kullanıcı listesi + rol atama, Firebase Console'a gitmeye gerek kalmadan |
| **Profile** | XP, seviye (Bronze→Master), rozetler, ayarlar (tema/dil/bildirim) |

## Persistence

- **SharedPreferences** — `AppSettings` (tema, dil, bildirim, metin ölçeği)
- **Hive** — `app_settings_box`, `learning_progress_box`, `news_cache_box`
- **Firestore** — `users`, `news`, `reels`, `support_chats` (production build'lerde; bkz. `firestore.rules`)

## Başlarken

```bash
git clone https://github.com/xenlabshq/NeuraDev.git
cd NeuraDev
flutter pub get
flutter run -d linux   # veya flutter run -d <device-id>
```

> Varsayılan (dart-define olmadan) build **demo mod**da çalışır — Firebase'e hiç bağlanmaz, tüm özellikler in-memory repo'lar ile çalışır, giriş ekranı devre dışıdır. Gerçek Firebase'e bağlı bir build için `android/app/google-services.json` + `lib/firebase_options.dart` gerekir (ikisi de `.gitignore`'da, `flutterfire configure` ile üretilir) ve şu flag ile derlenir:
>
> ```bash
> flutter build apk --release --dart-define=FIREBASE_CONFIGURED=true
> ```

## Komutlar (Makefile)

```bash
make get           # bağımlılıklar
make analyze       # dart analyze --fatal-infos
make test          # unit + widget testleri
make format        # dart format
make build-apk     # Android release APK (demo mod — FIREBASE_CONFIGURED flag'i elle eklenmeli)
make build-linux   # Linux release bundle
make build-ios     # iOS release (codesign'sız)
make clean         # flutter clean
```

## Doğrulama (AGENTS.md)

```bash
dart analyze                     # 0 errors
flutter test                     # 220+ tests pass
flutter build linux --debug      # ./build/linux/x64/debug/bundle/neuroup
flutter build apk --release --dart-define=FIREBASE_CONFIGURED=true
```

## Release v0.6.2+11 (Mevcut)

- ✅ Gerçek Firebase bağlantısı (Auth + Firestore, `neuraup-app` projesi)
- ✅ Rol tabanlı yetkilendirme (RBAC) + Firestore Security Rules
- ✅ Google ile giriş + şifre sıfırlama
- ✅ Haber Yönetimi admin sistemi (gerçek CRUD)
- ✅ Yönetim Paneli (uygulama içi rol atama)
- ✅ Reels'e kullanıcı içerik gönderimi
- ✅ `/login` + `/register` route'ları ve auth redirect guard'ı
- 📦 Android APK (universal, `FIREBASE_CONFIGURED=true`)
- 🐧 Linux bundle (extract & run `./neuroup`, demo mod)

## Yol Haritası

- [x] Proje iskeleti, tema (light/dark tokens), router
- [x] Auth (Firebase Auth: e-posta/şifre + Google, RBAC, in-memory fallback)
- [x] Learning: ada haritası, node editör, Python simülatör, ilerleme (Hive)
- [x] News: feed + filtreler + detay sayfası + admin CRUD
- [x] Chat: destek sohbeti + AI asistan paneli
- [x] Reels: kısa içerik akışı + kullanıcı gönderimi
- [x] Profile: XP, seviye, rozetler
- [x] Admin: Yönetim Paneli (rol atama)
- [x] Persistence: SharedPreferences + Hive + Firestore
- [x] Production Firebase config
- [x] Release v0.1.0 → v0.6.2+11 (GitHub Releases)
- [ ] Release imzalama (gerçek keystore — şu an debug imzalı)
- [ ] CI/CD (GitHub Actions)
- [ ] App Store & Play Store yayını

## Lisans

Private — © 2026 NeuraDev
