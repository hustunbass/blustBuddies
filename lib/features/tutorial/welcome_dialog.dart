import 'package:blast_buddies/core/onboarding.dart';
import 'package:blast_buddies/features/menu/menu_screens.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// "Welcome, buddy!" Resolves to true to start the tutorial, false to skip it
/// (null when dismissed, which counts as skipping).
Future<bool?> showWelcomeDialog(BuildContext context) =>
    showDialog<bool>(context: context, builder: (_) => const _WelcomeDialog());

class _WelcomeDialog extends StatelessWidget {
  const _WelcomeDialog();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Center(child: BuddyLogo(height: 64)),
            const SizedBox(height: 14),
            Text(l.welcomeTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text(l.welcomeBody(OnboardingNotifier.reward),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white70)),
            const SizedBox(height: 18),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.welcomeStart)),
            const SizedBox(height: 4),
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.welcomeSkip)),
          ]),
        ),
      ),
    );
  }
}
