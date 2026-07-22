import 'package:neuroup/features/education/data/repositories/quiz_repository_impl.dart';
import 'package:neuroup/features/education/domain/entities/quiz.dart';
import 'package:neuroup/features/education/domain/repositories/quiz_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late QuizRepository repo;
  late FakeFirebaseFirestore db;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = QuizRepositoryImpl(db);
  });

  group('QuizRepositoryImpl.evaluate', () {
    const quiz = Quiz(
      id: 'q1',
      lessonId: 'l1',
      questions: [
        Question(
          id: 'q1',
          text: '2+2?',
          options: ['3', '4', '5', '6'],
          correctIndex: 1,
          explanation: '',
          points: 10,
        ),
        Question(
          id: 'q2',
          text: '3*3?',
          options: ['6', '9', '12'],
          correctIndex: 1,
          explanation: '',
          points: 20,
        ),
      ],
    );

    test('all correct → pass', () {
      final result = repo.evaluate(quiz, {'q1': 1, 'q2': 1});
      expect(result.correctCount, 2);
      expect(result.totalScore, 30);
      expect(result.maxScore, 30);
      expect(result.passed, isTrue);
      expect(result.percentage, 100);
    });

    test('partial correct → score reflects points', () {
      final result = repo.evaluate(quiz, {'q1': 1, 'q2': 0});
      expect(result.correctCount, 1);
      expect(result.totalScore, 10);
      expect(result.passed, isFalse);
    });

    test('all wrong → fail', () {
      final result = repo.evaluate(quiz, {'q1': 0, 'q2': 0});
      expect(result.correctCount, 0);
      expect(result.totalScore, 0);
      expect(result.passed, isFalse);
    });

    test('empty answers → 0 score, fail', () {
      final result = repo.evaluate(quiz, const {});
      expect(result.totalScore, 0);
      expect(result.passed, isFalse);
    });
  });
}
