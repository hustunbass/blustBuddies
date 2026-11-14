import 'package:blast_buddies/core/auth/auth_provider.dart';
import 'package:blast_buddies/core/auth/auth_service.dart';
import 'package:blast_buddies/core/ui/toast.dart';
import 'package:blast_buddies/features/auth/account_actions.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Account controls for Settings: sign in (guests), sign out and delete the
/// account (signed-in players).
class AccountSection extends ConsumerStatefulWidget {
  /// Creates the section.
  const AccountSection({super.key});

  @override
  ConsumerState<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<AccountSection> {
  bool _deleting = false;

  Future<void> _signIn(AuthProvider p) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final l = AppLocalizations.of(context);
    final result = await signInFlow(container, p);
    if (result == SignInResult.failed) showToast(l.signInFailed, kind: ToastKind.error);
  }

  Future<void> _signOut() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final l = AppLocalizations.of(context);
    await signOutFlow(container);
    showToast(l.signedOutToast);
  }

  Future<void> _delete() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final l = AppLocalizations.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.deleteAccountTitle),
        content: Text(l.deleteAccountBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() => _deleting = true);
    final ok = await deleteAccountFlow(container);
    if (mounted) setState(() => _deleting = false);
    showToast(ok ? l.accountDeletedToast : l.deleteAccountFailed, kind: ok ? ToastKind.success : ToastKind.error);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final busy = auth.busy || _deleting;
    if (auth.signedIn) {
      return Column(children: [
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(l.signOutLabel),
          enabled: !busy,
          onTap: _signOut,
        ),
        ListTile(
          leading: Icon(Icons.delete_forever, color: busy ? null : Colors.redAccent),
          title: Text(l.deleteAccount, style: TextStyle(color: busy ? null : Colors.redAccent)),
          subtitle: _deleting ? const LinearProgressIndicator() : null,
          enabled: !busy,
          onTap: _delete,
        ),
      ]);
    }
    final providers = [
      for (final p in AuthProvider.values)
        if (ref.read(authProvider.notifier).supports(p)) p,
    ];
    if (providers.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.accountGuestHint, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 10),
        for (final p in providers) ...[
          if (p == AuthProvider.apple)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              onPressed: busy ? null : () => _signIn(p),
              icon: const Icon(Icons.apple),
              label: Text(l.signInWithApple),
            )
          else
            OutlinedButton.icon(
              onPressed: busy ? null : () => _signIn(p),
              icon: const Icon(Icons.login),
              label: Text(l.signInWithGoogle),
            ),
          const SizedBox(height: 8),
        ],
      ]),
    );
  }
}
