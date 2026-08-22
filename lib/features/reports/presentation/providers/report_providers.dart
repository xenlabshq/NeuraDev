import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/env/env.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/in_memory_report_repository.dart';
import '../../data/report_repository_impl.dart';
import '../../domain/repositories/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  if (!Env.firebaseConfigured) {
    return InMemoryReportRepository();
  }
  return ReportRepositoryImpl(ref.watch(firestoreProvider));
});

final pendingReportsStreamProvider = StreamProvider(
  (ref) => ref.watch(reportRepositoryProvider).watchPendingReports(),
);
