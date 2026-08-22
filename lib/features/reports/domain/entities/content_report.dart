import 'package:equatable/equatable.dart';

enum ReportStatus { pending, reviewed }

/// Bir kullanıcının bir reel gönderisini şikayet etmesiyle oluşan kayıt.
/// Sadece staff (moderatör/admin) görebilir (bkz. firestore.rules) —
/// şikayet edeni koruma amaçlı, sıradan kullanıcılar birbirinin
/// şikayetlerini göremez.
class ContentReport extends Equatable {
  const ContentReport({
    required this.id,
    required this.reelId,
    required this.reelTitle,
    required this.reelUploaderId,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    required this.createdAt,
    this.status = ReportStatus.pending,
  });

  final String id;
  final String reelId;
  final String reelTitle;
  final String reelUploaderId;
  final String reporterId;
  final String reporterName;
  final String reason;
  final DateTime createdAt;
  final ReportStatus status;

  @override
  List<Object?> get props => [
    id,
    reelId,
    reelTitle,
    reelUploaderId,
    reporterId,
    reporterName,
    reason,
    createdAt,
    status,
  ];
}
