import 'package:equatable/equatable.dart';

enum ReportStatus { pending, reviewed }

/// Şikayet edilen içeriğin türü — hangi repository'den silineceğini ve
/// "kullanıcıyı banla" aksiyonunun anlamlı olup olmadığını belirler
/// (haberlerin bir yükleyeni/sahibi yok, sadece staff tarafından yazılır).
enum ReportedContentType { reel, news }

/// Bir kullanıcının bir reel gönderisini ya da bir haberi şikayet
/// etmesiyle oluşan kayıt. Sadece staff (moderatör/admin) görebilir
/// (bkz. firestore.rules) — şikayet edeni koruma amaçlı, sıradan
/// kullanıcılar birbirinin şikayetlerini göremez.
class ContentReport extends Equatable {
  const ContentReport({
    required this.id,
    required this.contentType,
    required this.contentId,
    required this.contentTitle,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    required this.createdAt,
    this.contentOwnerId,
    this.status = ReportStatus.pending,
  });

  final String id;
  final ReportedContentType contentType;
  final String contentId;
  final String contentTitle;
  /// Reel'lerde yükleyenin uid'i; haberlerde bir sahip kavramı olmadığı
  /// için `null` — bu yüzden haber şikayetlerinde "Kullanıcıyı Banla"
  /// aksiyonu gösterilmez.
  final String? contentOwnerId;
  final String reporterId;
  final String reporterName;
  final String reason;
  final DateTime createdAt;
  final ReportStatus status;

  @override
  List<Object?> get props => [
    id,
    contentType,
    contentId,
    contentTitle,
    contentOwnerId,
    reporterId,
    reporterName,
    reason,
    createdAt,
    status,
  ];
}
