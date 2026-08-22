import '../../l10n/gen/app_localizations.dart';
import '../models/user_level.dart';

/// `BadgeTemplate.name`/`.description` sabit Türkçe döner — çevrilebilir
/// arayüzlerde bunun yerine bu locale-aware etiketleri kullan.
extension BadgeTemplateLabel on BadgeTemplate {
  String localizedName(AppLocalizations l10n) => switch (id) {
    'first_step' => l10n.badgeFirstStepName,
    'quiz_master' => l10n.badgeQuizMasterName,
    'streak_7' => l10n.badgeStreak7Name,
    'word_champion' => l10n.badgeWordChampionName,
    'math_wizard' => l10n.badgeMathWizardName,
    'science_explorer' => l10n.badgeScienceExplorerName,
    'history_buff' => l10n.badgeHistoryBuffName,
    'helper' => l10n.badgeHelperName,
    _ => name,
  };

  String localizedDescription(AppLocalizations l10n) => switch (id) {
    'first_step' => l10n.badgeFirstStepDesc,
    'quiz_master' => l10n.badgeQuizMasterDesc,
    'streak_7' => l10n.badgeStreak7Desc,
    'word_champion' => l10n.badgeWordChampionDesc,
    'math_wizard' => l10n.badgeMathWizardDesc,
    'science_explorer' => l10n.badgeScienceExplorerDesc,
    'history_buff' => l10n.badgeHistoryBuffDesc,
    'helper' => l10n.badgeHelperDesc,
    _ => description,
  };
}
