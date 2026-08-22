import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/home_shell.dart' show LessonOverlayScope;
import '../../../../app/theme/colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../admin/presentation/providers/admin_providers.dart';
import '../../../chat/presentation/providers/chat_providers.dart'
    show currentAuthUserProvider;
import '../../../reels/presentation/providers/reels_providers.dart';
import '../../../../shared/models/user_profile.dart' show UserRole;
import '../../domain/entities/content_report.dart';
import '../providers/report_providers.dart';

/// Staff-only sayfa: kullanıcıların şikayet ettiği reels gönderilerini
/// listeler. Erişim ve gerçek yetkilendirme firestore.rules'da (isStaff())
/// zorunlu kılınıyor; bu sayfa sadece istemci tarafı kolaylık.
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  LessonOverlayScope? _overlayScope;

  @override
  void initState() {
    super.initState();
    _overlayScope = LessonOverlayScope(context);
  }

  @override
  void dispose() {
    _overlayScope?.dispose();
    super.dispose();
  }

  Future<void> _removeContent(ContentReport report) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(reelSubmissionRepositoryProvider)
          .deleteReel(report.reelId);
      ref.read(reelsProvider.notifier).removeReel(report.reelId);
      await ref.read(reportRepositoryProvider).dismissReport(report.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportsContentRemoved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportsActionFailed(e.toString()))),
      );
    }
  }

  Future<void> _banUser(ContentReport report) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(userAdminRepositoryProvider)
          .setBanned(report.reelUploaderId, true);
      await ref.read(reportRepositoryProvider).dismissReport(report.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportsUserBannedAndDismissed)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportsActionFailed(e.toString()))),
      );
    }
  }

  Future<void> _dismiss(ContentReport report) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(reportRepositoryProvider).dismissReport(report.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportsDismissed)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportsActionFailed(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reportsAsync = ref.watch(pendingReportsStreamProvider);
    // Banlama sadece admin rolüne açık — moderatör içeriği kaldırabilir
    // ama kullanıcı banlayamaz (bkz. firestore.rules users/{userId}.update).
    final isAdmin = ref.watch(currentAuthUserProvider)?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsPageTitle)),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return Center(child: Text(l10n.reportsEmpty));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _ReportCard(
                  report: reports[i],
                  isAdmin: isAdmin,
                  onRemoveContent: () => _removeContent(reports[i]),
                  onBanUser: () => _banUser(reports[i]),
                  onDismiss: () => _dismiss(reports[i]),
                ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.reportsActionFailed(e.toString()))),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.isAdmin,
    required this.onRemoveContent,
    required this.onBanUser,
    required this.onDismiss,
  });

  final ContentReport report;
  final bool isAdmin;
  final VoidCallback onRemoveContent;
  final VoidCallback onBanUser;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.reelTitle,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.reportsReportedBy(report.reporterName),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(report.reason),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onDismiss,
                child: Text(l10n.reportsDismissAction),
              ),
              if (isAdmin)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                  ),
                  onPressed: onBanUser,
                  child: Text(l10n.reportsBanUserAction),
                ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: onRemoveContent,
                child: Text(l10n.reportsRemoveContentAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
