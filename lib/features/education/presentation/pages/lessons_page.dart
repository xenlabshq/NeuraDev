import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:neuroup/app/theme/app_theme.dart';
import 'package:neuroup/app/theme/colors.dart';
import 'package:neuroup/shared/widgets/common_widgets.dart';
import 'package:neuroup/features/education/domain/entities/lesson.dart';
import 'package:neuroup/features/education/domain/entities/user_progress.dart';
import 'package:neuroup/features/education/presentation/providers/education_providers.dart';

class LessonsPage extends ConsumerWidget {
  const LessonsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLessons = ref.watch(lessonsStreamProvider);
    final asyncProgress = ref.watch(myLessonProgressProvider);

    return Scaffold(
      body: asyncLessons.when(
        loading: () => const _LessonsLoading(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Hata: $e', textAlign: TextAlign.center),
          ),
        ),
        data: (lessons) {
          final progressList = asyncProgress.valueOrNull ?? const [];
          final progressMap = {for (final p in progressList) p.lessonId: p};
          return CustomScrollView(
            slivers: [
              const _LessonsHeader(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _ProgressOverview(
                    lessons: lessons,
                    progress: progressList,
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Tüm Dersler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.separated(
                  itemCount: lessons.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final lesson = lessons[i];
                    final progress = progressMap[lesson.id];
                    return _LessonCard(
                      lesson: lesson,
                      progress: progress,
                      onTap: () => context.push('/lessons/${lesson.id}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LessonsLoading extends StatelessWidget {
  const _LessonsLoading();
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Skeleton(width: 200, height: 28),
              const SizedBox(height: 16),
              const Skeleton(width: double.infinity, height: 120),
              const SizedBox(height: 12),
              const Skeleton(width: double.infinity, height: 120),
              const SizedBox(height: 12),
              const Skeleton(width: double.infinity, height: 120),
            ]),
          ),
        ),
      ],
    );
  }
}

class _LessonsHeader extends StatelessWidget {
  const _LessonsHeader();
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Dersler',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Yeni şeyler öğren, quizlerle pekiştir',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({required this.lessons, required this.progress});
  final List<Lesson> lessons;
  final List<UserProgress> progress;

  @override
  Widget build(BuildContext context) {
    final completed =
        progress.where((p) => p.status == LessonStatus.completed).length;
    final inProgress = progress
        .where((p) => p.status == LessonStatus.inProgress)
        .length;
    final totalScore = progress.fold<int>(0, (sum, p) => sum + p.bestScore);

    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.check_circle_rounded,
            value: '$completed',
            label: 'Tamamlanan',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            icon: Icons.timelapse_rounded,
            value: '$inProgress',
            label: 'Devam Eden',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            icon: Icons.star_rounded,
            value: '$totalScore',
            label: 'Toplam XP',
            color: AppColors.gold,
          ),
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.progress,
    required this.onTap,
  });

  final Lesson lesson;
  final UserProgress? progress;
  final VoidCallback onTap;

  Color get _subjectColor {
    switch (lesson.subject) {
      case Subject.math:
        return AppColors.mathColor;
      case Subject.science:
        return AppColors.scienceColor;
      case Subject.history:
        return AppColors.historyColor;
      case Subject.language:
        return AppColors.languageColor;
      case Subject.technology:
        return AppColors.technologyColor;
      case Subject.art:
        return AppColors.artColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = progress?.bestScore ?? 0;
    final completed = progress?.status == LessonStatus.completed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border:
                Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _subjectColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                alignment: Alignment.center,
                child: Text(
                  lesson.thumbnailEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GradientPill(
                          label: lesson.subject.label,
                          color: _subjectColor,
                        ),
                        const SizedBox(width: 6),
                        if (completed)
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.success,
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    if (score > 0) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceAlt,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _subjectColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'En iyi: $score%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _subjectColor,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${lesson.durationMinutes} dk',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.bookmark_outline_rounded,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${lesson.topics.length} konu',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
