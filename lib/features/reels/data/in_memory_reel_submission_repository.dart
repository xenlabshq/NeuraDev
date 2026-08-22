import 'dart:async';

import '../domain/entities/game_reel.dart';
import '../domain/repositories/reel_submission_repository.dart';

/// Demo mod için — gönderilen reels sadece bu oturum boyunca bellekte kalır.
class InMemoryReelSubmissionRepository implements ReelSubmissionRepository {
  final List<GameReel> _submitted = [];
  final _controller = StreamController<List<GameReel>>.broadcast();

  @override
  Stream<List<GameReel>> watchSubmittedReels() async* {
    yield List.unmodifiable(_submitted);
    yield* _controller.stream;
  }

  int _nextId = 1;

  @override
  Future<void> submitReel(
    GameReel reel, {
    required String submittedByUid,
    String? localVideoPath,
  }) async {
    // Demo modda yükleme yok — `reel.videoUrl` zaten çağıran taraftan
    // (ReelSubmitPage) yerel dosya yolu olarak set edilmiş durumda,
    // `video_player` bunu doğrudan `File` olarak oynatabiliyor.
    // Gerçek id ata — boş id ile silme/güncelleme eşleşemezdi.
    final withId = GameReel(
      id: 'local_${_nextId++}',
      devName: reel.devName,
      devTag: reel.devTag,
      title: reel.title,
      caption: reel.caption,
      tags: reel.tags,
      accent: reel.accent,
      symbols: reel.symbols,
      hud: reel.hud,
      likes: reel.likes,
      comments: reel.comments,
      gameUrl: reel.gameUrl,
      videoUrl: reel.videoUrl,
      uploaderId: reel.uploaderId,
    );
    _submitted.insert(0, withId);
    _controller.add(List.unmodifiable(_submitted));
  }

  @override
  Future<void> updateReel(GameReel reel, {String? localVideoPath}) async {
    final i = _submitted.indexWhere((r) => r.id == reel.id);
    if (i < 0) return;
    _submitted[i] = GameReel(
      id: reel.id,
      devName: reel.devName,
      devTag: reel.devTag,
      title: reel.title,
      caption: reel.caption,
      tags: reel.tags,
      accent: reel.accent,
      symbols: reel.symbols,
      hud: reel.hud,
      likes: reel.likes,
      comments: reel.comments,
      gameUrl: reel.gameUrl,
      videoUrl: localVideoPath ?? reel.videoUrl,
      uploaderId: reel.uploaderId,
    );
    _controller.add(List.unmodifiable(_submitted));
  }

  @override
  Future<void> deleteReel(String id) async {
    _submitted.removeWhere((r) => r.id == id);
    _controller.add(List.unmodifiable(_submitted));
  }
}
