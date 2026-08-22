import '../entities/game_reel.dart';

/// Kullanıcıların kendi oyunlarını (oyun linki + tanıtım metni) Reels
/// akışına eklemesini sağlayan ayrı repository. Beğeni/kaydetme/yorum gibi
/// oturum-içi etkileşimler ReelsRepository üzerinden yönetilmeye devam
/// eder; bu repository sadece kalıcı gönderim (create) işlemine bakar.
///
/// Firebase Storage maliyetini kontrol altında tutmak için iki kural
/// uygulanıyor: kullanıcı başına günde bir yükleme ([lastUploadAt]) ve
/// gönderiler 24 saat sonra süresi dolmuş sayılıp herhangi bir istemci
/// tarafından temizlenebiliyor ([GameReel.expiresAt]). Gerçek zamanlı
/// sunucu tarafı otomatik silme Cloud Functions (ve dolayısıyla Blaze
/// planı) gerektirir — bu proje şimdilik Blaze'siz çalışmak istediği
/// için süresi dolmuş içerik, ona rastlayan HERHANGİ bir istemci
/// tarafından (bkz. ReelsPage) tembel (lazy) şekilde temizleniyor.
abstract class ReelSubmissionRepository {
  Stream<List<GameReel>> watchSubmittedReels();

  /// Kullanıcının en son gönderisinin zamanı — günlük yükleme hakkını
  /// hesaplamak için kullanılır. Hiç gönderim yapmadıysa `null`.
  Future<DateTime?> lastUploadAt(String uid);

  /// [localMediaPath] doluysa (kullanıcının cihazından seçtiği video/resim)
  /// gerçek (Firestore/Storage) implementasyon dosyayı yükleyip
  /// `reel.videoUrl`'ü indirme linkiyle değiştirir; in-memory
  /// implementasyon zaten [reel.videoUrl] üzerinde yerel yolu taşıdığı için
  /// bu parametreyi yok sayar.
  Future<void> submitReel(
    GameReel reel, {
    required String submittedByUid,
    String? localMediaPath,
  });

  /// [reel]'in metinsel alanlarını (başlık/tanıtım/etiket/oyun linki)
  /// günceller — sadece gönderiyi paylaşan kullanıcı çağırabilir
  /// (firestore.rules bunu sunucu tarafında da zorunlu kılar).
  /// [localMediaPath] doluysa video/resim de değiştirilir; boşsa mevcut
  /// medya korunur. Düzenleme günlük yükleme hakkını harcamaz.
  Future<void> updateReel(GameReel reel, {String? localMediaPath});

  /// [id]'li gönderiyi kaldırır — sahibi kendi gönderisini, bir
  /// moderatör/admin herhangi bir gönderiyi, ya da süresi dolmuş
  /// (`expiresAt` geçmiş) herhangi bir gönderiyi HERKES silebilir
  /// (firestore.rules).
  Future<void> deleteReel(String id);
}
