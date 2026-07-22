import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neuroup/core/failures/failure.dart';
import 'package:neuroup/core/services/logger_service.dart';
import 'package:neuroup/core/utils/result.dart';
import 'package:neuroup/features/education/domain/entities/lesson.dart';
import 'package:neuroup/features/education/domain/entities/quiz.dart';
import 'package:neuroup/features/education/domain/entities/user_progress.dart';
import 'package:neuroup/features/education/domain/repositories/lesson_repository.dart';

class LessonRepositoryImpl implements LessonRepository {
  LessonRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _lessons =>
      _db.collection('lessons');

  CollectionReference<Map<String, dynamic>> _progress(String userId) =>
      _db.collection('users').doc(userId).collection('progress');

  @override
  Stream<List<Lesson>> watchAll() => _lessons
      .orderBy('order')
      .snapshots()
      .map((snap) => snap.docs.map(_lessonFromDoc).toList());

  @override
  Future<Lesson?> getById(String lessonId) async {
    final doc = await _lessons.doc(lessonId).get();
    if (!doc.exists) return null;
    return _lessonFromDoc(doc);
  }

  @override
  Future<List<Lesson>> seedIfEmpty() async {
    final existing = await _lessons.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return (await _lessons.get())
          .docs
          .map(_lessonFromDoc)
          .toList();
    }
    LoggerService.info('Seeding lessons collection...');
    final batch = _db.batch();
    for (final lesson in _defaultLessons()) {
      batch.set(_lessons.doc(lesson.id), _lessonToMap(lesson));
    }
    await batch.commit();
    return _defaultLessons();
  }

  @override
  Stream<UserProgress?> watchProgress(String userId, String lessonId) {
    return _progress(userId)
        .doc(lessonId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return _progressFromDoc(doc);
    });
  }

  @override
  Stream<List<UserProgress>> watchAllProgress(String userId) {
    return _progress(userId).snapshots().map((snap) =>
        snap.docs.map(_progressFromDoc).toList());
  }

  @override
  Future<void> markInProgress(String userId, String lessonId) async {
    final ref = _progress(userId).doc(lessonId);
    final current = await ref.get();
    if (current.exists) return;
    await ref.set({
      'status': LessonStatus.inProgress.name,
      'bestScore': 0,
      'attempts': 0,
      'lastAttemptAt': null,
      'completedAt': null,
    });
  }

  @override
  Future<Result<QuizResult>> saveQuizResult({
    required String userId,
    required String lessonId,
    required int score,
    required int maxScore,
  }) async {
    try {
      final ref = _progress(userId).doc(lessonId);
      final current = await ref.get();
      final previous = current.exists ? _progressFromDoc(current) : null;
      final percentage =
          maxScore == 0 ? 0 : ((score / maxScore) * 100).round();
      final passed = percentage >= 60;
      final bestScore = previous == null
          ? percentage
          : (percentage > previous.bestScore
              ? percentage
              : previous.bestScore);
      final status =
          passed ? LessonStatus.completed : LessonStatus.inProgress;
      await ref.set({
        'status': status.name,
        'bestScore': bestScore,
        'attempts': (previous?.attempts ?? 0) + 1,
        'lastAttemptAt': DateTime.now(),
        'completedAt': passed
            ? (previous?.completedAt ?? DateTime.now())
            : previous?.completedAt,
      });
      return Success(QuizResult(
        totalScore: score,
        maxScore: maxScore,
        correctCount: 0,
        totalQuestions: 0,
        passed: passed,
      ));
    } catch (e, st) {
      LoggerService.error('saveQuizResult failed', e, st);
      return Err(failureFromException(e, st));
    }
  }

  Lesson _lessonFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Lesson(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      subject: Subject.values.firstWhere(
        (s) => s.name == data['subject'],
        orElse: () => Subject.math,
      ),
      difficulty: Difficulty.values.firstWhere(
        (d) => d.name == data['difficulty'],
        orElse: () => Difficulty.beginner,
      ),
      order: (data['order'] as num?)?.toInt() ?? 0,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 10,
      thumbnailEmoji: data['thumbnailEmoji'] as String? ?? '📘',
      topics: (data['topics'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> _lessonToMap(Lesson l) => {
        'title': l.title,
        'description': l.description,
        'subject': l.subject.name,
        'difficulty': l.difficulty.name,
        'order': l.order,
        'durationMinutes': l.durationMinutes,
        'thumbnailEmoji': l.thumbnailEmoji,
        'topics': l.topics,
      };

  UserProgress _progressFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserProgress(
      lessonId: doc.id,
      status: LessonStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => LessonStatus.notStarted,
      ),
      bestScore: (data['bestScore'] as num?)?.toInt() ?? 0,
      attempts: (data['attempts'] as num?)?.toInt() ?? 0,
      lastAttemptAt: (data['lastAttemptAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }
}

List<Lesson> _defaultLessons() => const [
      Lesson(
        id: 'math_basics',
        title: 'Temel Matematik',
        description:
            'Toplama, çıkarma, çarpma ve bölme işlemlerinin temellerini öğren.',
        subject: Subject.math,
        difficulty: Difficulty.beginner,
        order: 1,
        durationMinutes: 15,
        thumbnailEmoji: '🔢',
        topics: ['Toplama', 'Çıkarma', 'Çarpma', 'Bölme'],
      ),
      Lesson(
        id: 'science_intro',
        title: 'Fen Bilimlerine Giriş',
        description:
            'Madde, enerji ve canlılar hakkında temel kavramları keşfet.',
        subject: Subject.science,
        difficulty: Difficulty.beginner,
        order: 2,
        durationMinutes: 20,
        thumbnailEmoji: '🔬',
        topics: ['Madde', 'Enerji', 'Canlılar', 'Çevre'],
      ),
      Lesson(
        id: 'history_ancient',
        title: 'İlk Çağ Uygarlıkları',
        description:
            'Sümer, Mısır, Yunan ve Roma uygarlıklarının özelliklerini öğren.',
        subject: Subject.history,
        difficulty: Difficulty.intermediate,
        order: 3,
        durationMinutes: 25,
        thumbnailEmoji: '🏛️',
        topics: ['Sümer', 'Mısır', 'Yunan', 'Roma'],
      ),
      Lesson(
        id: 'tech_logic',
        title: 'Algoritmik Düşünce',
        description:
            'Problemleri adım adım çözme ve algoritma mantığını anlama.',
        subject: Subject.technology,
        difficulty: Difficulty.intermediate,
        order: 4,
        durationMinutes: 30,
        thumbnailEmoji: '💻',
        topics: ['Algoritma', 'Sıralama', 'Mantık', 'Problem Çözme'],
      ),
    ];
