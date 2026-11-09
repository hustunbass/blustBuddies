import 'package:blast_buddies/core/settings/stats.dart';
import 'package:blast_buddies/core/ui/toast.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/l10n/names.dart';

/// Shows a gold toast for each freshly unlocked achievement.
void toastAchievements(AppLocalizations l, List<Achievement> fresh) {
  for (final a in fresh) {
    showToast(Names.achievement(l, a), title: l.achievementToastTitle, kind: ToastKind.achievement);
  }
}
