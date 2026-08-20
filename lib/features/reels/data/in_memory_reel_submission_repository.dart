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

  @override
  Future<void> submitReel(
    GameReel reel, {
    required String submittedByUid,
  }) async {
    _submitted.insert(0, reel);
    _controller.add(List.unmodifiable(_submitted));
  }
}
