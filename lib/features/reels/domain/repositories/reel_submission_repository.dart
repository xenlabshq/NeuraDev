import '../entities/game_reel.dart';

/// Kullanıcıların kendi oyunlarını (oyun linki + tanıtım metni) Reels
/// akışına eklemesini sağlayan ayrı repository. Beğeni/kaydetme/yorum gibi
/// oturum-içi etkileşimler ReelsRepository üzerinden yönetilmeye devam
/// eder; bu repository sadece kalıcı gönderim (create) işlemine bakar.
abstract class ReelSubmissionRepository {
  Stream<List<GameReel>> watchSubmittedReels();
  Future<void> submitReel(GameReel reel, {required String submittedByUid});
}
