import '../entities/game_reel.dart';

/// Kullanıcıların kendi oyunlarını (oyun linki + tanıtım metni) Reels
/// akışına eklemesini sağlayan ayrı repository. Beğeni/kaydetme/yorum gibi
/// oturum-içi etkileşimler ReelsRepository üzerinden yönetilmeye devam
/// eder; bu repository sadece kalıcı gönderim (create) işlemine bakar.
abstract class ReelSubmissionRepository {
  Stream<List<GameReel>> watchSubmittedReels();

  /// [localVideoPath] doluysa (kullanıcının cihazından seçtiği oynanış
  /// videosu) gerçek (Firestore/Storage) implementasyon dosyayı yükleyip
  /// `reel.videoUrl`'ü indirme linkiyle değiştirir; in-memory
  /// implementasyon zaten [reel.videoUrl] üzerinde yerel yolu taşıdığı için
  /// bu parametreyi yok sayar.
  Future<void> submitReel(
    GameReel reel, {
    required String submittedByUid,
    String? localVideoPath,
  });

  /// [reel]'in metinsel alanlarını (başlık/tanıtım/etiket/oyun linki)
  /// günceller — sadece gönderiyi paylaşan kullanıcı çağırabilir
  /// (firestore.rules bunu sunucu tarafında da zorunlu kılar).
  /// [localVideoPath] doluysa video da değiştirilir; boşsa mevcut video
  /// korunur.
  Future<void> updateReel(GameReel reel, {String? localVideoPath});

  /// [id]'li gönderiyi kaldırır — sahibi kendi gönderisini veya bir
  /// moderatör/admin herhangi bir gönderiyi silebilir (firestore.rules).
  Future<void> deleteReel(String id);
}
