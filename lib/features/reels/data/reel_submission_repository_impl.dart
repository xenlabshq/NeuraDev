import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/entities/game_reel.dart';
import '../domain/repositories/reel_submission_repository.dart';

/// Bir günlük yükleme kotasının süresi — Storage maliyetini kontrol
/// altında tutmak için hem yeni gönderi hakkı hem de gönderinin ekranda
/// kalma süresi bu değere bağlı (bkz. [ReelSubmissionRepository] doc
/// yorumu).
const reelUploadCooldown = Duration(hours: 24);

class ReelSubmissionRepositoryImpl implements ReelSubmissionRepository {
  ReelSubmissionRepositoryImpl(this._db, this._storage);
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _reels =>
      _db.collection('reels');

  DocumentReference<Map<String, dynamic>> _uploadLimit(String uid) =>
      _db.collection('upload_limits').doc(uid);

  @override
  Stream<List<GameReel>> watchSubmittedReels() {
    return _reels
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  @override
  Future<DateTime?> lastUploadAt(String uid) async {
    final doc = await _uploadLimit(uid).get();
    final ts = doc.data()?['lastUploadAt'] as Timestamp?;
    return ts?.toDate();
  }

  @override
  Future<void> submitReel(
    GameReel reel, {
    required String submittedByUid,
    String? localMediaPath,
  }) async {
    var mediaUrl = reel.videoUrl;
    if (localMediaPath != null) {
      final ext = _extensionFor(localMediaPath, reel.mediaType);
      final ref = _storage.ref(
        'reels/$submittedByUid/${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await ref.putFile(
        File(localMediaPath),
        SettableMetadata(contentType: _contentTypeFor(reel.mediaType, ext)),
      );
      mediaUrl = await ref.getDownloadURL();
    }
    final now = DateTime.now();
    // Yeni gönderi + günlük yükleme hakkı kaydı ATOMİK olarak (batch)
    // yazılıyor — firestore.rules'daki create kuralı, bu kaydı
    // kontrol ederek aynı kullanıcının 24 saat içinde ikinci bir
    // gönderi oluşturmasını engelliyor.
    final batch = _db.batch();
    batch.set(_reels.doc(), {
      'devName': reel.devName,
      'devTag': reel.devTag,
      'title': reel.title,
      'caption': reel.caption,
      'tags': reel.tags,
      'accent': reel.accent.name,
      'symbols': reel.symbols,
      'hud': reel.hud,
      'gameUrl': reel.gameUrl,
      'videoUrl': mediaUrl,
      'mediaType': reel.mediaType.name,
      'submittedBy': submittedByUid,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(reelUploadCooldown)),
    });
    batch.set(_uploadLimit(submittedByUid), {
      'lastUploadAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> updateReel(GameReel reel, {String? localMediaPath}) async {
    var mediaUrl = reel.videoUrl;
    if (localMediaPath != null) {
      final ext = _extensionFor(localMediaPath, reel.mediaType);
      final ref = _storage.ref(
        'reels/${reel.uploaderId}/${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await ref.putFile(
        File(localMediaPath),
        SettableMetadata(contentType: _contentTypeFor(reel.mediaType, ext)),
      );
      mediaUrl = await ref.getDownloadURL();
    }
    await _reels.doc(reel.id).update({
      'title': reel.title,
      'caption': reel.caption,
      'tags': reel.tags,
      'gameUrl': reel.gameUrl,
      'videoUrl': mediaUrl,
      'mediaType': reel.mediaType.name,
    });
  }

  @override
  Future<void> deleteReel(String id) async {
    // Storage'daki dosyayı da temizlemeyi dene — indirme URL'inden
    // referansı çıkarmak kırılgan olabileceği için (link formatı
    // değişebilir, dosya zaten silinmiş olabilir) en iyi çaba (best
    // effort): başarısız olursa yutup asıl Firestore silme işlemine
    // devam ediyoruz, kullanıcı için asıl önemli olan gönderinin
    // akıştan kalkması.
    try {
      final doc = await _reels.doc(id).get();
      final mediaUrl = doc.data()?['videoUrl'] as String?;
      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        await _storage.refFromURL(mediaUrl).delete();
      }
    } catch (_) {
      // yoksay — dosya zaten yoksa veya silinemiyorsa dokümanı yine sil.
    }
    await _reels.doc(id).delete();
  }

  String _extensionFor(String localPath, ReelMediaType type) {
    final dot = localPath.lastIndexOf('.');
    if (dot != -1 && dot < localPath.length - 1) {
      return localPath.substring(dot + 1).toLowerCase();
    }
    return type == ReelMediaType.video ? 'mp4' : 'jpg';
  }

  String _contentTypeFor(ReelMediaType type, String ext) {
    if (type == ReelMediaType.image) {
      return switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
    }
    return switch (ext) {
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      _ => 'video/mp4',
    };
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
      mediaType: ReelMediaType.values.firstWhere(
        (t) => t.name == data['mediaType'],
        orElse: () => ReelMediaType.video,
      ),
      uploaderId: data['submittedBy'] as String?,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      comments: const [],
    );
  }
}
