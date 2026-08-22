import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/reports/data/in_memory_report_repository.dart';

void main() {
  test('watchPendingReports is empty before any report is submitted', () async {
    final repo = InMemoryReportRepository();
    final first = await repo.watchPendingReports().first;
    expect(first, isEmpty);
  });

  test('submitReport adds a pending report visible in the stream', () async {
    final repo = InMemoryReportRepository();
    await repo.submitReport(
      reelId: 'reel_1',
      reelTitle: 'Test Oyunu',
      reelUploaderId: 'uploader_1',
      reporterId: 'reporter_1',
      reporterName: 'Ali',
      reason: 'Uygunsuz içerik',
    );

    final pending = await repo.watchPendingReports().first;
    expect(pending, hasLength(1));
    expect(pending.single.reelTitle, 'Test Oyunu');
    expect(pending.single.reason, 'Uygunsuz içerik');
  });

  test('dismissReport removes the report from the pending stream', () async {
    final repo = InMemoryReportRepository();
    await repo.submitReport(
      reelId: 'reel_1',
      reelTitle: 'Test Oyunu',
      reelUploaderId: 'uploader_1',
      reporterId: 'reporter_1',
      reporterName: 'Ali',
      reason: 'Spam',
    );
    final report = (await repo.watchPendingReports().first).single;

    await repo.dismissReport(report.id);

    expect(await repo.watchPendingReports().first, isEmpty);
  });

  test('multiple reports on the same reel are all queued independently', () async {
    final repo = InMemoryReportRepository();
    await repo.submitReport(
      reelId: 'reel_1',
      reelTitle: 'Test Oyunu',
      reelUploaderId: 'uploader_1',
      reporterId: 'reporter_1',
      reporterName: 'Ali',
      reason: 'Spam',
    );
    await repo.submitReport(
      reelId: 'reel_1',
      reelTitle: 'Test Oyunu',
      reelUploaderId: 'uploader_1',
      reporterId: 'reporter_2',
      reporterName: 'Veli',
      reason: 'Taciz',
    );

    final pending = await repo.watchPendingReports().first;
    expect(pending, hasLength(2));
  });
}
