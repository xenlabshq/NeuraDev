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
    required ReportedContentType contentType,
    required String contentId,
    required String contentTitle,
    required String reporterId,
    required String reporterName,
    required String reason,
    String? contentOwnerId,
  }) async {
    _reports.insert(
      0,
      ContentReport(
        id: 'report_${_nextId++}',
        contentType: contentType,
        contentId: contentId,
        contentTitle: contentTitle,
        contentOwnerId: contentOwnerId,
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
      contentType: _reports[i].contentType,
      contentId: _reports[i].contentId,
      contentTitle: _reports[i].contentTitle,
      contentOwnerId: _reports[i].contentOwnerId,
      reporterId: _reports[i].reporterId,
      reporterName: _reports[i].reporterName,
      reason: _reports[i].reason,
      createdAt: _reports[i].createdAt,
      status: ReportStatus.reviewed,
    );
    _emit();
  }
}
