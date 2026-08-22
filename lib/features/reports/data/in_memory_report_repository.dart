import 'dart:async';

import '../domain/entities/content_report.dart';
import '../domain/repositories/report_repository.dart';

class InMemoryReportRepository implements ReportRepository {
  final List<ContentReport> _reports = [];
  final _controller = StreamController<List<ContentReport>>.broadcast();
  int _nextId = 1;

  void _emit() {
    _controller.add(
      List.unmodifiable(
        _reports.where((r) => r.status == ReportStatus.pending),
      ),
    );
  }

  @override
  Stream<List<ContentReport>> watchPendingReports() async* {
    yield List.unmodifiable(
      _reports.where((r) => r.status == ReportStatus.pending),
    );
    yield* _controller.stream;
  }

  @override
  Future<void> submitReport({
    required String reelId,
    required String reelTitle,
    required String reelUploaderId,
    required String reporterId,
    required String reporterName,
    required String reason,
  }) async {
    _reports.insert(
      0,
      ContentReport(
        id: 'report_${_nextId++}',
        reelId: reelId,
        reelTitle: reelTitle,
        reelUploaderId: reelUploaderId,
        reporterId: reporterId,
        reporterName: reporterName,
        reason: reason,
        createdAt: DateTime.now(),
      ),
    );
    _emit();
  }

  @override
  Future<void> dismissReport(String reportId) async {
    final i = _reports.indexWhere((r) => r.id == reportId);
    if (i < 0) return;
    _reports[i] = ContentReport(
      id: _reports[i].id,
      reelId: _reports[i].reelId,
      reelTitle: _reports[i].reelTitle,
      reelUploaderId: _reports[i].reelUploaderId,
      reporterId: _reports[i].reporterId,
      reporterName: _reports[i].reporterName,
      reason: _reports[i].reason,
      createdAt: _reports[i].createdAt,
      status: ReportStatus.reviewed,
    );
    _emit();
  }
}
