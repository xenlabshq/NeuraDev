import 'package:equatable/equatable.dart';

enum LessonStatus { notStarted, inProgress, completed }

class UserProgress extends Equatable {

  factory UserProgress.empty(String lessonId) =>
      UserProgress(lessonId: lessonId, status: LessonStatus.notStarted);
  const UserProgress({
    required this.lessonId,
    required this.status,
    this.bestScore = 0,
    this.attempts = 0,
    this.lastAttemptAt,
    this.completedAt,
  });

  final String lessonId;
  final LessonStatus status;
  final int bestScore;
  final int attempts;
  final DateTime? lastAttemptAt;
  final DateTime? completedAt;

  bool get isCompleted => status == LessonStatus.completed;

  UserProgress copyWith({
    LessonStatus? status,
    int? bestScore,
    int? attempts,
    DateTime? lastAttemptAt,
    DateTime? completedAt,
  }) =>
      UserProgress(
        lessonId: lessonId,
        status: status ?? this.status,
        bestScore: bestScore ?? this.bestScore,
        attempts: attempts ?? this.attempts,
        lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
        completedAt: completedAt ?? this.completedAt,
      );

  @override
  List<Object?> get props => [
        lessonId,
        status,
        bestScore,
        attempts,
        lastAttemptAt,
        completedAt,
      ];
}
