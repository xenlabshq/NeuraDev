import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/app/theme/app_theme.dart';
import 'package:neuroup/app/theme/colors.dart';
import 'package:neuroup/shared/widgets/common_widgets.dart';
import 'package:neuroup/features/education/domain/entities/lesson.dart';
import 'package:neuroup/features/education/presentation/providers/education_providers.dart';
import 'package:neuroup/features/education/presentation/pages/quiz_page.dart';

class LessonDetailPage extends ConsumerWidget {
  const LessonDetailPage({required this.lessonId, super.key});
  final String lessonId;

  Color _colorFor(Subject s) => switch (s) {
        Subject.math => AppColors.mathColor,
        Subject.science => AppColors.scienceColor,
        Subject.history => AppColors.historyColor,
        Subject.language => AppColors.languageColor,
        Subject.technology => AppColors.technologyColor,
        Subject.art => AppColors.artColor,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLesson = ref.watch(lessonDetailProvider(lessonId));
    final asyncQuiz = ref.watch(quizProvider(lessonId));
    final asyncProgress = ref.watch(lessonProgressProvider(lessonId));

    return Scaffold(
      body: asyncLesson.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (lesson) {
          if (lesson == null) {
            return const Center(child: Text('Ders bulunamadı'));
          }
          final color = _colorFor(lesson.subject);
          final progress = asyncProgress.valueOrNull;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          bottom: -30,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    lesson.thumbnailEmoji,
                                    style: const TextStyle(fontSize: 30),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GradientPill(
                                  label: lesson.subject.label,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  lesson.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _MetaPill(
                        icon: Icons.timer_outlined,
                        label: '${lesson.durationMinutes} dakika',
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      _MetaPill(
                        icon: Icons.bar_chart_rounded,
                        label: lesson.difficulty.label,
                        color: color,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    lesson.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Konular',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: lesson.topics
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                t,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: asyncQuiz.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Text('Quiz yüklenemedi: $e'),
                    data: (quiz) {
                      if (quiz == null) {
                        return const _QuizCardEmpty();
                      }
                      return _QuizCard(
                        color: color,
                        questionCount: quiz.questions.length,
                        passingScore: quiz.passingScore,
                        bestScore: progress?.bestScore ?? 0,
                        onStart: () =>
                            Navigator.of(context).push<Widget>(
                          MaterialPageRoute<Widget>(
                            builder: (_) => QuizPage(
                              lessonId: lessonId,
                              lessonTitle: lesson.title,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.color,
    required this.questionCount,
    required this.passingScore,
    required this.bestScore,
    required this.onStart,
  });
  final Color color;
  final int questionCount;
  final int passingScore;
  final int bestScore;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Quiz Zamanı!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$questionCount soru ile bilgini test et',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Geçme notu: %$passingScore',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (bestScore > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'En iyi: $bestScore%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Quize Başla'),
              onPressed: onStart,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizCardEmpty extends StatelessWidget {
  const _QuizCardEmpty();
  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.quiz_outlined,
      title: 'Quiz henüz yok',
      message: 'Bu ders için hazırlanmış bir quiz bulunmuyor.',
    );
  }
}
