import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/core/failures/failure.dart';
import 'package:neuroup/shared/models/user_profile.dart';
import 'package:neuroup/features/education/domain/entities/quiz.dart';
import 'package:neuroup/features/education/presentation/providers/education_providers.dart';

class QuizSessionState extends Equatable {
  const QuizSessionState({
    this.answers = const {},
    this.currentIndex = 0,
    this.finished = false,
    this.result,
    this.submitting = false,
    this.error,
  });

  final Map<String, int> answers;
  final int currentIndex;
  final bool finished;
  final QuizResult? result;
  final bool submitting;
  final String? error;

  bool isAnswered(String questionId) => answers.containsKey(questionId);

  QuizSessionState copyWith({
    Map<String, int>? answers,
    int? currentIndex,
    bool? finished,
    QuizResult? result,
    bool? submitting,
    String? error,
    bool clearError = false,
  }) =>
      QuizSessionState(
        answers: answers ?? this.answers,
        currentIndex: currentIndex ?? this.currentIndex,
        finished: finished ?? this.finished,
        result: result ?? this.result,
        submitting: submitting ?? this.submitting,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props =>
      [answers, currentIndex, finished, result, submitting, error];
}

class QuizSessionController extends StateNotifier<QuizSessionState> {
  QuizSessionController({
    required this._quiz,
    required String lessonId,
    required this._user,
    required this._ref,
  })  : _lessonId = lessonId,
        super(const QuizSessionState()) {
    _ref.read(lessonRepositoryProvider).markInProgress(_user.id, _lessonId);
  }

  final Quiz _quiz;
  final String _lessonId;
  final UserProfile _user;
  final Ref _ref;

  void answer(String questionId, int optionIndex) {
    final next = Map<String, int>.from(state.answers);
    next[questionId] = optionIndex;
    state = state.copyWith(answers: next, clearError: true);
  }

  void next() {
    if (state.currentIndex < _quiz.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previous() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  Future<void> submit() async {
    state = state.copyWith(submitting: true, clearError: true);
    final result =
        _ref.read(quizRepositoryProvider).evaluate(_quiz, state.answers);
    final saveResult = await _ref.read(lessonRepositoryProvider).saveQuizResult(
          userId: _user.id,
          lessonId: _lessonId,
          score: result.totalScore,
          maxScore: result.maxScore,
        );
    final newState = saveResult.when<QuizSessionState>(
      success: (_) => state.copyWith(
        result: result,
        finished: true,
        submitting: false,
      ),
      failure: (Failure f) => state.copyWith(
        submitting: false,
        error: f.message,
      ),
    );
    state = newState;
  }

  void reset() => state = const QuizSessionState();
}

final StateNotifierProviderFamily<QuizSessionController, QuizSessionState, QuizSessionArgs> quizSessionProvider = StateNotifierProvider.family<
    QuizSessionController, QuizSessionState, QuizSessionArgs>(
  (ref, args) => QuizSessionController(
    ref: ref,
    quiz: args.quiz,
    lessonId: args.lessonId,
    user: args.user,
  ),
);

class QuizSessionArgs {
  const QuizSessionArgs({
    required this.quiz,
    required this.lessonId,
    required this.user,
  });
  final Quiz quiz;
  final String lessonId;
  final UserProfile user;

  @override
  bool operator ==(Object other) =>
      other is QuizSessionArgs &&
      other.lessonId == lessonId &&
      other.user.id == user.id;

  @override
  int get hashCode => Object.hash(lessonId, user.id);
}
