import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/core/providers/core_providers.dart';
import 'package:neuroup/features/education/data/repositories/lesson_repository_impl.dart';
import 'package:neuroup/features/education/data/repositories/quiz_repository_impl.dart';
import 'package:neuroup/features/education/domain/entities/lesson.dart';
import 'package:neuroup/features/education/domain/entities/quiz.dart';
import 'package:neuroup/features/education/domain/entities/user_progress.dart';
import 'package:neuroup/features/education/domain/repositories/lesson_repository.dart';
import 'package:neuroup/features/education/domain/repositories/quiz_repository.dart';
import 'package:neuroup/features/chat/presentation/providers/chat_providers.dart' show currentAuthUserProvider;

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LessonRepositoryImpl(ref.watch(firestoreProvider)),
);

final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => QuizRepositoryImpl(ref.watch(firestoreProvider)),
);

final lessonsStreamProvider = StreamProvider<List<Lesson>>((ref) {
  return ref.watch(lessonRepositoryProvider).watchAll();
});

final FutureProviderFamily<Lesson?, String> lessonDetailProvider =
    FutureProvider.family<Lesson?, String>((ref, lessonId) async {
  await ref.read(quizRepositoryProvider).seedIfEmpty();
  await ref.read(lessonRepositoryProvider).seedIfEmpty();
  return ref.read(lessonRepositoryProvider).getById(lessonId);
});

final FutureProviderFamily<Quiz?, String> quizProvider =
    FutureProvider.family<Quiz?, String>((ref, lessonId) async {
  return ref.read(quizRepositoryProvider).getForLesson(lessonId);
});

final myLessonProgressProvider = StreamProvider<List<UserProgress>>((ref) {
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(lessonRepositoryProvider).watchAllProgress(user.id);
});

final StreamProviderFamily<UserProgress?, String> lessonProgressProvider =
    StreamProvider.family<UserProgress?, String>((ref, lessonId) {
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(lessonRepositoryProvider).watchProgress(user.id, lessonId);
});
