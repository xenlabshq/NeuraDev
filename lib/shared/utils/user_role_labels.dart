import '../../l10n/gen/app_localizations.dart';
import '../models/user_profile.dart';

/// `UserRole.label` sabit Türkçe döner — çevrilebilir arayüzlerde bunun
/// yerine bu locale-aware etiketi kullan.
extension UserRoleLabel on UserRole {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    UserRole.student => l10n.authRoleStudent,
    UserRole.teacher => l10n.authRoleTeacher,
    UserRole.parent => l10n.authRoleParent,
    UserRole.moderator => l10n.roleModerator,
    UserRole.admin => l10n.roleAdmin,
  };
}
