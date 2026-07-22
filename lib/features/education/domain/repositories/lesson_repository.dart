import 'package:neuroup/core/utils/result.dart';
import 'package:neuroup/features/education/domain/entities/lesson.dart';
import 'package:neuroup/features/education/domain/entities/quiz.dart';
import 'package:neuroup/features/education/domain/entities/user_progress.dart';

abstract class LessonRepository {
  Stream<List<Lesson>> watchAll();
  Future<Lesson?> getById(String lessonId);
  Future<List<Lesson>> seedIfEmpty();

  Stream<UserProgress?> watchProgress(String userId, String lessonId);
  Stream<List<UserProgress>> watchAllProgress(String userId);

  Future<void> markInProgress(String userId, String lessonId);
  Future<Result<QuizResult>> saveQuizResult({
    required String userId,
    required String lessonId,
    required int score,
    required int maxScore,
  });
}
