import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/reports/data/in_memory_report_repository.dart';
import 'package:neuroup/features/reports/domain/entities/content_report.dart';

void main() {
  test('watchPendingReports is empty before any report is submitted', () async {
    final repo = InMemoryReportRepository();
    final first = await repo.watchPendingReports().first;
    expect(first, isEmpty);
  });

  test('submitReport adds a pending reel report visible in the stream', () async {
    final repo = InMemoryReportRepository();
    await repo.submitReport(
      contentType: ReportedContentType.reel,
      contentId: 'reel_1',
      contentTitle: 'Test Oyunu',
      contentOwnerId: 'uploader_1',
      reporterId: 'reporter_1',
      reporterName: 'Ali',
      reason: 'Uygunsuz içerik',
    );

    final pending = await repo.watchPendingReports().first;
    expect(pending, hasLength(1));
    expect(pending.single.contentTitle, 'Test Oyunu');
    expect(pending.single.contentOwnerId, 'uploader_1');
    expect(pending.single.reason, 'Uygunsuz içerik');
  });

  test('submitReport adds a pending news report with no content owner', () async {
    final repo = InMemoryReportRepository();
    await repo.submitReport(
      contentType: ReportedContentType.news,
      contentId: 'news_1',
      contentTitle: 'Test Haberi',
      reporterId: 'reporter_1',
      reporterName: 'Ali',
      reason: 'Yanlış bilgi',
    );

    final pending = await repo.watchPendingReports().first;
    expect(pending, hasLength(1));
    expect(pending.single.contentType, ReportedContentType.news);
    expect(pending.single.contentOwnerId, isNull);
  });

  test('dismissReport removes the report from the pending stream', () async {
    final repo = InMemoryReportRepository();
    await repo.submitReport(
      contentType: ReportedContentType.reel,
      contentId: 'reel_1',
      contentTitle: 'Test Oyunu',
      contentOwnerId: 'uploader_1',
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
      contentType: ReportedContentType.reel,
      contentId: 'reel_1',
      contentTitle: 'Test Oyunu',
      contentOwnerId: 'uploader_1',
      reporterId: 'reporter_1',
      reporterName: 'Ali',
      reason: 'Spam',
    );
    await repo.submitReport(
      contentType: ReportedContentType.reel,
      contentId: 'reel_1',
      contentTitle: 'Test Oyunu',
      contentOwnerId: 'uploader_1',
      reporterId: 'reporter_2',
      reporterName: 'Veli',
      reason: 'Taciz',
    );

    final pending = await repo.watchPendingReports().first;
    expect(pending, hasLength(2));
  });
}
