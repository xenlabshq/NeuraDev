import '../entities/game_reel.dart';

abstract class ReelsRepository {
  List<GameReel> getAll();

  /// Sonsuz kaydırma (infinite scroll) için sayfalama — [offset] zaten
  /// yüklenmiş öğe sayısıdır, sonraki [pageSize] kadar öğeyi döndürür.
  /// Boş liste dönerse daha fazla öğe kalmadığı anlamına gelir. Şu an
  /// sabit seed veri üzerinde çalışıyor ama imza, gerçek bir backend'e
  /// (örn. Firestore `startAfterDocument` sayfalaması) geçildiğinde de
  /// aynı şekilde kullanılabilir.
  Future<List<GameReel>> fetchMore({required int offset, int pageSize = 10});

  GameReel? getById(String id);
  GameReel toggleLike(String id);
  GameReel toggleSave(String id);
  GameReel toggleFollow(String id);
  GameReel addComment(String reelId, String text);
}
