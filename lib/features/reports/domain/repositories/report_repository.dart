import '../entities/content_report.dart';

abstract class ReportRepository {
  /// Sadece staff'ın erişebildiği, henüz incelenmemiş şikayetlerin akışı.
  Stream<List<ContentReport>> watchPendingReports();

  Future<void> submitReport({
    required ReportedContentType contentType,
    required String contentId,
    required String contentTitle,
    required String reporterId,
    required String reporterName,
    required String reason,
    String? contentOwnerId,
  });

  /// Şikayeti "incelendi" olarak işaretler — staff içeriği kaldırdıktan,
  /// kullanıcıyı banladıktan veya şikayeti asılsız bulup kapattıktan sonra
  /// çağrılır. Hangi aksiyonun alındığı ayrı ayrı (deleteReel/deleteArticle/
  /// setBanned) yapılır; bu sadece kuyruktan düşürür.
  Future<void> dismissReport(String reportId);
}
