# Neuroup

<p align="center">
  <img src="docs/screenshots/Ekran Görüntüsü_20260822_140510.png" width="200" alt="Python Adaları haritası" />
  <img src="docs/screenshots/Ekran Görüntüsü_20260822_140654.png" width="200" alt="Ada içi ders haritası" />
  <img src="docs/screenshots/Ekran Görüntüsü_20260822_140628.png" width="200" alt="Kod editörü" />
  <img src="docs/screenshots/Ekran Görüntüsü_20260822_141059.png" width="200" alt="Profil sayfası" />
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/xenlabshq/NeuraDev?label=release&color=6366F1" alt="Latest release" />
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Linux-informational" alt="Platforms" />
  <img src="https://img.shields.io/badge/backend-Firebase-FFCA28?logo=firebase&logoColor=white" alt="Firebase" />
  <img src="https://img.shields.io/badge/license-Private-red" alt="License" />
</p>

<p align="center">
  Flutter tabanlı eğitim uygulaması: fütüristik <b>Python Adaları</b> (izometrik 3D harita, gerçek Python simülatörü), <b>Reels</b> (kısa video), gerçek zamanlı <b>Destek Sohbeti</b> ve <b>Haberler</b>.<br />
  Android, iOS ve Linux masaüstünde çalışır.
</p>

> Paket adı: `neuroup` · Binary adı: `neuroup` · Application ID: `com.neuroup.app`

## 📱 Ekran Görüntüleri

<p align="center">
  <img src="docs/screenshots/Ekran Görüntüsü_20260822_140825.png" width="200" alt="AI Asistan" />
  <img src="docs/screenshots/Ekran Görüntüsü_20260822_140856.png" width="200" alt="Haberler" />
  <img src="docs/screenshots/Ekran Görüntüsü_20260822_140929.png" width="200" alt="Haber detayı" />
  <img src="docs/screenshots/Ekran Görüntüsü_20260822_141156.png" width="200" alt="Ayarlar" />
</p>

## ✨ Öne Çıkanlar

- 🧠 **Fütüristik Python Adaları** — izometrik 3D harita, holografik enerji halkaları, HUD köşe parantezleri; 12 ada / 36 ders, gerçek bir Python alt kümesini yorumlayan özel bir simülatör
- 💡 **Doğrudan cevap yok** — her ders boş bir kod şablonuyla başlar, öğrenci önce dener; takılırsa 3 kademeli ipucu, en son çözüm açılır
- 🎬 **Reels** — kullanıcıların kendi oyunlarını paylaştığı dikey video/görsel akışı; Storage maliyetini kontrol altında tutmak için günlük yükleme limiti + 24 saatte otomatik silinme
- 💬 **Gerçek zamanlı destek sohbeti + AI asistan** — kullanıcı/moderatör mesajlaşması Firestore üzerinden, canlı
- 🚩 **Moderasyon** — reels ve haberler şikayet edilebilir; staff panelinden içerik kaldırma / kullanıcı banlama
- 🔐 **Rol tabanlı yetkilendirme** — Firebase Auth + Firestore Security Rules, hem istemci hem sunucu tarafında zorunlu kılınır

## 🏗️ Mimari

- **State management:** Riverpod 2.6
- **Routing:** go_router 14 (ShellRoute tabanlı, auth durumuna göre `redirect`)
- **Backend:** Firebase (Auth, Firestore, Storage, Messaging, Analytics) — `Env.firebaseConfigured=false` iken (varsayılan dev build) in-memory fallback çalışır; production build'lerde gerçek Firebase projesine bağlanır
- **Storage:** SharedPreferences (ayarlar) + Hive (cache)
- **Tasarım sistemi:** Tema-aware token'lar (`AppColors.tokensOf(context)`) — light/dark
- **Mimari pattern:** Feature-first Clean Architecture
  - `lib/core/` — çapraz kesiti (env, failures, services, providers, utils)
  - `lib/shared/` — ortak widget/modeller
  - `lib/features/{admin,auth,learning,news,chat,ai,profile,reels,reports}/` — her feature
    - `data/` — veri kaynakları, modeller, repository implementasyonları + **in-memory fallback**
    - `domain/` — entity, soyut repo, use-case
    - `presentation/` — provider, sayfa, widget

## Features

| Modül | Açıklama |
|---|---|
| **Learning** | Fütüristik izometrik ada haritası, snake-path node bağlantıları, Python editör + simülatör (liste/dict/fonksiyon/string/dosya desteği), canlı değişken izleyici, 3 kademeli ipucu sistemi, XP/streak ilerlemesi (Hive cache) |
| **Reels** | Dikey video/görsel akışı, yorum çekmecesi, like/paylaş — giriş yapmadan da gezilebilir. Giriş yapmış kullanıcılar günde bir video ya da resim yükleyebilir (24 saatte otomatik silinir) |
| **News** | Kategori filtreleri, pinned SliverAppBar, haber detay sayfası, şikayet etme. Moderatör/admin rolündeki kullanıcılar uygulama içinden haber ekleyip düzenleyip silebilir |
| **Chat** | Destek sohbeti (öğrenci/moderatör), kanal listesi, gerçek-zamanlı mesajlaşma + AI asistan paneli |
| **Reports** | Reels ve haberler için şikayet kuyruğu — staff içeriği kaldırabilir veya kullanıcıyı banlayabilir |
| **Auth** | Firebase Auth: e-posta/şifre + Google ile giriş, şifre sıfırlama e-postası, rol tabanlı yetkilendirme (`users/{uid}.role`, Firestore Security Rules ile sunucu tarafında da zorunlu kılınır) |
| **Admin** | Sadece `admin`/`moderatör` rolündeki kullanıcılara görünen Yönetim Paneli — kullanıcı arama, rol atama, banlama |
| **Profile** | XP, seviye (Bronze→Master), rozetler, ayarlar (tema/dil/bildirim), gerçek uygulama sürümü |

## Persistence

- **SharedPreferences** — `AppSettings` (tema, dil, bildirim, metin ölçeği)
- **Hive** — `app_settings_box`, `learning_progress_box`, `news_cache_box`
- **Firestore** — `users`, `news`, `reels`, `upload_limits`, `support_chats`, `reports` (production build'lerde; bkz. `firestore.rules`)
- **Storage** — `reels/{uid}/...` (bkz. `storage.rules`, Blaze planı gerektirir)

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
flutter test                     # 375+ tests pass
flutter build linux --debug      # ./build/linux/x64/debug/bundle/neuroup
flutter build apk --release --dart-define=FIREBASE_CONFIGURED=true
```

## 📦 Son Sürüm — v0.6.8

- 🐛 Kritik: şikayet formu gönderilince gerçek cihazda çökme (crash) düzeltildi
- 🐛 3 tuşlu (gesture olmayan) Android navigasyonunda yüzen bar/içerik çakışması düzeltildi
- 🐛 Ders bitirme akışında "Ana Sayfaya Dön" ve "Önerilenle Başla" hataları düzeltildi
- 🎨 Python Adaları'nda fütüristik/tech görsel yenileme (holografik enerji halkası, devre izi dokusu, HUD köşe parantezleri)
- 💡 36 dersin tamamında 3 kademeli ipucu sistemi + boş başlangıç kod şablonları
- 🆕 Algoritmalar ve Mini Projeler adaları (6 yeni ileri seviye ders)
- 🚩 Haberler için de şikayet etme özelliği
- 💰 Reels: Storage maliyet kontrolü (günlük 1 yükleme, 24 saatte otomatik silinme)

<details>
<summary>Önceki sürümler</summary>

**v0.6.2+11**
- ✅ Gerçek Firebase bağlantısı (Auth + Firestore, `neuraup-app` projesi)
- ✅ Rol tabanlı yetkilendirme (RBAC) + Firestore Security Rules
- ✅ Google ile giriş + şifre sıfırlama
- ✅ Haber Yönetimi admin sistemi (gerçek CRUD)
- ✅ Yönetim Paneli (uygulama içi rol atama)
- ✅ Reels'e kullanıcı içerik gönderimi
- ✅ `/login` + `/register` route'ları ve auth redirect guard'ı

</details>

## 🗺️ Yol Haritası

- [x] Proje iskeleti, tema (light/dark tokens), router
- [x] Auth (Firebase Auth: e-posta/şifre + Google, RBAC, in-memory fallback)
- [x] Learning: fütüristik ada haritası, node editör, Python simülatör, ipucu sistemi, ilerleme (Hive)
- [x] News: feed + filtreler + detay sayfası + admin CRUD + şikayet
- [x] Chat: destek sohbeti + AI asistan paneli
- [x] Reels: kısa içerik akışı + kullanıcı gönderimi + maliyet kontrolü
- [x] Reports: reels + haber şikayet sistemi
- [x] Profile: XP, seviye, rozetler
- [x] Admin: Yönetim Paneli (arama, rol atama, banlama)
- [x] Persistence: SharedPreferences + Hive + Firestore
- [x] Production Firebase config
- [x] Release v0.1.0 → v0.6.8+17 (GitHub Releases)
- [ ] Release imzalama (gerçek keystore — şu an debug imzalı)
- [ ] CI/CD (GitHub Actions)
- [ ] App Store & Play Store yayını

## Lisans

Private — © 2026 NeuraDev
