import '../entities/content_report.dart';

abstract class ReportRepository {
  /// Sadece staff'ın erişebildiği, henüz incelenmemiş şikayetlerin akışı.
  Stream<List<ContentReport>> watchPendingReports();

  Future<void> submitReport({
    required String reelId,
    required String reelTitle,
    required String reelUploaderId,
    required String reporterId,
    required String reporterName,
    required String reason,
  });

  /// Şikayeti "incelendi" olarak işaretler — staff gönderiyi kaldırdıktan,
  /// kullanıcıyı banladıktan veya şikayeti asılsız bulup kapattıktan sonra
  /// çağrılır. Hangi aksiyonun alındığı ayrı ayrı (deleteReel/setBanned)
  /// yapılır; bu sadece kuyruktan düşürür.
  Future<void> dismissReport(String reportId);
}
