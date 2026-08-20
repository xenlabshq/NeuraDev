import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/game_reel.dart';
import '../domain/repositories/reel_submission_repository.dart';

class ReelSubmissionRepositoryImpl implements ReelSubmissionRepository {
  ReelSubmissionRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _reels =>
      _db.collection('reels');

  @override
  Stream<List<GameReel>> watchSubmittedReels() {
    return _reels
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  @override
  Future<void> submitReel(
    GameReel reel, {
    required String submittedByUid,
  }) async {
    await _reels.add({
      'devName': reel.devName,
      'devTag': reel.devTag,
      'title': reel.title,
      'caption': reel.caption,
      'tags': reel.tags,
      'accent': reel.accent.name,
      'symbols': reel.symbols,
      'hud': reel.hud,
      'gameUrl': reel.gameUrl,
      'submittedBy': submittedByUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  GameReel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return GameReel(
      id: doc.id,
      devName: data['devName'] as String? ?? 'Bilinmeyen',
      devTag: data['devTag'] as String? ?? '@bilinmeyen',
      title: data['title'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      tags: data['tags'] as String? ?? '',
      accent: ReelAccent.values.firstWhere(
        (a) => a.name == data['accent'],
        orElse: () => ReelAccent.violet,
      ),
      symbols: (data['symbols'] as List?)?.cast<String>() ?? const ['🎮'],
      hud: data['hud'] as String? ?? 'Yeni',
      likes: 0,
      gameUrl: data['gameUrl'] as String? ?? '',
      comments: const [],
    );
  }
}
