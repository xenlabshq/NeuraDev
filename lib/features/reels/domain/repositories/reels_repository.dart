import '../entities/game_reel.dart';

abstract class ReelsRepository {
  List<GameReel> getAll();
  GameReel? getById(String id);
  GameReel toggleLike(String id);
  GameReel toggleSave(String id);
  GameReel toggleFollow(String id);
  GameReel addComment(String reelId, String text);
}
