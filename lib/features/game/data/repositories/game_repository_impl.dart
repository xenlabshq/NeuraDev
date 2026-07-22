import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neuroup/core/services/logger_service.dart';
import 'package:neuroup/features/game/domain/entities/game_score.dart';
import 'package:neuroup/features/game/domain/entities/word_puzzle.dart';
import 'package:neuroup/features/game/domain/repositories/game_repository.dart';

class GameRepositoryImpl implements GameRepository {
  GameRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _puzzles =>
      _db.collection('game_puzzles');

  CollectionReference<Map<String, dynamic>> get _scores =>
      _db.collection('game_scores');

  @override
  Future<List<WordPuzzle>> getPuzzles() async {
    final snap = await _puzzles.get();
    if (snap.docs.isEmpty) {
      await seedIfEmpty();
      return _defaultPuzzles();
    }
    return snap.docs.map(_puzzleFromDoc).toList();
  }

  @override
  Future<void> seedIfEmpty() async {
    final existing = await _puzzles.limit(1).get();
    if (existing.docs.isNotEmpty) return;
    LoggerService.info('Seeding game puzzles...');
    final batch = _db.batch();
    for (final p in _defaultPuzzles()) {
      batch.set(_puzzles.doc(p.id), _puzzleToMap(p));
    }
    await batch.commit();
  }

  @override
  Future<void> saveScore(GameScore score) async {
    await _scores.add({
      'userId': score.userId,
      'gameId': score.gameId,
      'score': score.score,
      'completedAt': score.completedAt,
      'durationSeconds': score.durationSeconds,
    });
  }

  @override
  Future<List<GameScore>> getTopScores(String gameId, {int limit = 10}) async {
    final snap = await _scores
        .where('gameId', isEqualTo: gameId)
        .orderBy('score', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return GameScore(
        userId: data['userId'] as String? ?? '',
        gameId: data['gameId'] as String? ?? '',
        score: (data['score'] as num?)?.toInt() ?? 0,
        completedAt: (data['completedAt'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  WordPuzzle _puzzleFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return WordPuzzle(
      id: doc.id,
      answer: data['answer'] as String? ?? '',
      hint: data['hint'] as String? ?? '',
      scrambled: data['scrambled'] as String? ?? '',
      difficulty: PuzzleDifficulty.values.firstWhere(
        (d) => d.name == data['difficulty'],
        orElse: () => PuzzleDifficulty.easy,
      ),
      points: (data['points'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> _puzzleToMap(WordPuzzle p) => {
        'answer': p.answer,
        'hint': p.hint,
        'scrambled': p.scrambled,
        'difficulty': p.difficulty.name,
        'points': p.points,
      };
}

List<WordPuzzle> _defaultPuzzles() {
  final raw = <(String, String, String)>[
    ('p1', 'KEDİ', 'Miyavlayan evcil hayvan'),
    ('p2', 'KÖPEK', 'En sadık dost'),
    ('p3', 'OKUL', 'Öğrenme yeri'),
    ('p4', 'KALEM', 'Yazı aracı'),
    ('p5', 'GÜNEŞ', "Dünya'ya ışık veren yıldız"),
    ('p6', 'BULUT', 'Gökyüzünde beyaz'),
    ('p7', 'AĞAÇ', 'Oksijen üreten bitki'),
    ('p8', 'DENİZ', 'Tuzlu su kütlesi'),
    ('p9', 'BİLGİSAYAR', 'Elektronik hesap makinesi'),
    ('p10', 'KÜTÜPHANE', 'Kitapların evi'),
    ('p11', 'MATEMATİK', 'Sayılar bilimi'),
    ('p12', 'ASTRONOT', 'Uzaya giden kişi'),
  ];
  return raw.map((r) {
    final (id, answer, hint) = r;
    return WordPuzzle.generate(id, answer, hint);
  }).toList();
}
