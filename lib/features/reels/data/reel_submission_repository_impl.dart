import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/entities/game_reel.dart';
import '../domain/repositories/reel_submission_repository.dart';

class ReelSubmissionRepositoryImpl implements ReelSubmissionRepository {
  ReelSubmissionRepositoryImpl(this._db, this._storage);
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

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
    String? localVideoPath,
  }) async {
    var videoUrl = reel.videoUrl;
    if (localVideoPath != null) {
      final ref = _storage.ref(
        'reels/$submittedByUid/${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await ref.putFile(File(localVideoPath));
      videoUrl = await ref.getDownloadURL();
    }
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
      'videoUrl': videoUrl,
      'submittedBy': submittedByUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateReel(GameReel reel, {String? localVideoPath}) async {
    var videoUrl = reel.videoUrl;
    if (localVideoPath != null) {
      final ref = _storage.ref(
        'reels/${reel.uploaderId}/${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await ref.putFile(File(localVideoPath));
      videoUrl = await ref.getDownloadURL();
    }
    await _reels.doc(reel.id).update({
      'title': reel.title,
      'caption': reel.caption,
      'tags': reel.tags,
      'gameUrl': reel.gameUrl,
      'videoUrl': videoUrl,
    });
  }

  @override
  Future<void> deleteReel(String id) async {
    // Storage'daki videoyu da temizlemeyi dene — indirme URL'inden
    // referansı çıkarmak kırılgan olabileceği için (link formatı
    // değişebilir, dosya zaten silinmiş olabilir) en iyi çaba (best
    // effort): başarısız olursa yutup asıl Firestore silme işlemine
    // devam ediyoruz, kullanıcı için asıl önemli olan gönderinin
    // akıştan kalkması.
    try {
      final doc = await _reels.doc(id).get();
      final videoUrl = doc.data()?['videoUrl'] as String?;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        await _storage.refFromURL(videoUrl).delete();
      }
    } catch (_) {
      // yoksay — video zaten yoksa veya silinemiyorsa dokümanı yine sil.
    }
    await _reels.doc(id).delete();
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
      videoUrl: data['videoUrl'] as String?,
      uploaderId: data['submittedBy'] as String?,
      comments: const [],
    );
  }
}
