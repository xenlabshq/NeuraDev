import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/app/theme/app_theme.dart';
import 'package:neuroup/app/theme/colors.dart';
import 'package:neuroup/shared/models/user_profile.dart';
import 'package:neuroup/shared/widgets/common_widgets.dart';
import 'package:neuroup/features/chat/presentation/providers/chat_providers.dart' show currentAuthUserProvider;
import 'package:neuroup/features/education/domain/entities/quiz.dart';
import 'package:neuroup/features/education/presentation/providers/education_providers.dart';
import 'package:neuroup/features/education/presentation/providers/quiz_session_controller.dart';

class QuizPage extends ConsumerWidget {
  const QuizPage({
    required this.lessonId,
    required this.lessonTitle,
    super.key,
  });
  final String lessonId;
  final String lessonTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAuthUserProvider);
    final asyncQuiz = ref.watch(quizProvider(lessonId));

    return Scaffold(
      appBar: AppBar(
        title: Text(lessonTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: asyncQuiz.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (quiz) {
          if (quiz == null) {
            return const Center(child: Text('Quiz bulunamadı'));
          }
          if (user == null) {
            return const Center(child: Text('Giriş yapılmadı'));
          }
          return _QuizRunner(quiz: quiz, lessonId: lessonId, user: user);
        },
      ),
    );
  }
}

class _QuizRunner extends ConsumerWidget {
  const _QuizRunner({
    required this.quiz,
    required this.lessonId,
    required this.user,
  });
  final Quiz quiz;
  final String lessonId;
  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = QuizSessionArgs(quiz: quiz, lessonId: lessonId, user: user);
    final state = ref.watch(quizSessionProvider(args));
    final controller = ref.read(quizSessionProvider(args).notifier);

    if (state.finished && state.result != null) {
      return _ResultView(result: state.result!);
    }

    final question = quiz.questions[state.currentIndex];
    final total = quiz.questions.length;
    final isLast = state.currentIndex == total - 1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru ${state.currentIndex + 1} / $total',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              GradientPill(
                label: '+${question.points} puan',
                gradient: AppColors.warmGradient,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (state.currentIndex + 1) / total,
              minHeight: 8,
              backgroundColor: AppColors.surfaceAlt,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.3,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final selected = state.answers[question.id] == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionTile(
                label: option,
                index: index,
                selected: selected,
                onTap: () => controller.answer(question.id, index),
              ),
            );
          }),
          const Spacer(),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                state.error!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Row(
            children: [
              if (state.currentIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Geri'),
                    onPressed:
                        state.submitting ? null : controller.previous,
                  ),
                ),
              if (state.currentIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  icon: Icon(
                    isLast
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isLast
                        ? (state.submitting ? 'Gönderiliyor...' : 'Bitir')
                        : 'İleri',
                  ),
                  onPressed: !state.isAnswered(question.id) || state.submitting
                      ? null
                      : isLast
                          ? controller.submit
                          : controller.next,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});
  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final color =
        result.passed ? AppColors.success : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                result.passed
                    ? Icons.celebration_rounded
                    : Icons.refresh_rounded,
                size: 64,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              result.passed ? 'Tebrikler!' : 'Tekrar Dene',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              result.passed
                  ? 'Bu dersi başarıyla tamamladın'
                  : 'Biraz daha pratik yapmalısın',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '%${result.percentage.round()}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Skor',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  _StatRow(
                    label: 'Doğru cevap',
                    value:
                        '${result.correctCount} / ${result.totalQuestions}',
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    label: 'Puan',
                    value: '${result.totalScore} / ${result.maxScore}',
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    label: 'Sonuç',
                    value: result.passed ? 'BAŞARILI ✓' : 'BAŞARISIZ',
                    highlight: result.passed,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Derse Dön'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(
      {required this.label,
      required this.value,
      this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
