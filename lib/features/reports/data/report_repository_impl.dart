import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/content_report.dart';
import '../domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  // `where('status', ...)` + `orderBy('createdAt', ...)` farklı alanlarda
  // composite index isteyip index yoksa tüm akışı çökertir (bu oturumda
  // haberler/destek sohbetinde yaşanan aynı sorun) — tek-alanlı orderBy +
  // istemci tarafı filtre ile çözülüyor.
  @override
  Stream<List<ContentReport>> watchPendingReports() {
    return _reports
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(_fromDoc)
              .where((r) => r.status == ReportStatus.pending)
              .toList(),
        );
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
    await _reports.add({
      'reelId': reelId,
      'reelTitle': reelTitle,
      'reelUploaderId': reelUploaderId,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reason': reason,
      'status': ReportStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> dismissReport(String reportId) async {
    await _reports.doc(reportId).update({
      'status': ReportStatus.reviewed.name,
    });
  }

  ContentReport _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ContentReport(
      id: doc.id,
      reelId: data['reelId'] as String? ?? '',
      reelTitle: data['reelTitle'] as String? ?? '',
      reelUploaderId: data['reelUploaderId'] as String? ?? '',
      reporterId: data['reporterId'] as String? ?? '',
      reporterName: data['reporterName'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ReportStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ReportStatus.pending,
      ),
    );
  }
}
