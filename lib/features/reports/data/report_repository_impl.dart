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
  // istemci tarafı filtre ile çözülüyor. Bu sorgu sadece staff için
  // güvenlidir (firestore.rules `reports` read kuralı `isStaff()`e bağlı,
  // `resource.data`'dan bağımsız olduğu için Firestore bunu bir `where`
  // filtresi olmadan da doğrulayabiliyor — bkz. destek sohbetindeki
  // benzer ama GÜVENSİZ desenin düzeltmesi, watchChatsForUser).
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
    required ReportedContentType contentType,
    required String contentId,
    required String contentTitle,
    required String reporterId,
    required String reporterName,
    required String reason,
    String? contentOwnerId,
  }) async {
    await _reports.add({
      'contentType': contentType.name,
      'contentId': contentId,
      'contentTitle': contentTitle,
      'contentOwnerId': contentOwnerId,
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
      contentType: ReportedContentType.values.firstWhere(
        (t) => t.name == data['contentType'],
        orElse: () => ReportedContentType.reel,
      ),
      contentId: data['contentId'] as String? ?? '',
      contentTitle: data['contentTitle'] as String? ?? '',
      contentOwnerId: data['contentOwnerId'] as String?,
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
