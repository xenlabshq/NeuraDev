import 'package:neuroup/features/education/domain/entities/quiz.dart';

abstract class QuizRepository {
  Future<Quiz?> getForLesson(String lessonId);
  Future<void> seedIfEmpty();
  QuizResult evaluate(Quiz quiz, Map<String, int> answers);
}
