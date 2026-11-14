import 'dart:async';

import 'package:blast_buddies/core/auth/auth_provider.dart';
import 'package:blast_buddies/core/auth/auth_service.dart';
import 'package:blast_buddies/core/auth/login_prompt.dart';
import 'package:blast_buddies/core/ui/toast.dart';
import 'package:blast_buddies/features/auth/account_actions.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// First-launch screen: sign in with Apple or Google, or continue as a guest
/// (casual games only). Shown once; accounts are managed in Settings later.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _leaving = false;

  Future<void> _done() async {
    if (_leaving) return;
    _leaving = true;
    await ref.read(loginPromptDoneProvider.notifier).markDone();
    if (mounted) context.go('/');
  }

  Future<void> _signIn(AuthProvider p) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final l = AppLocalizations.of(context);
    final result = await signInFlow(container, p);
    switch (result) {
      case SignInResult.ok:
        await _done();
      case SignInResult.cancelled:
        break;
      case SignInResult.failed:
        showToast(l.signInFailed, kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    // A session kept from an earlier install: nothing to ask.
    if (auth.signedIn && !_leaving) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_done()));
    }
    final providers = [
      for (final p in AuthProvider.values)
        if (ref.read(authProvider.notifier).supports(p)) p,
    ];
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF232C4D), Color(0xFF171D33)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.loginTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 28),
                    for (final p in providers) ...[
                      if (p == AuthProvider.apple)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: auth.busy ? null : () => _signIn(p),
                          icon: const Icon(Icons.apple),
                          label: Text(l.signInWithApple, style: const TextStyle(fontSize: 17)),
                        )
                      else
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                          onPressed: auth.busy ? null : () => _signIn(p),
                          icon: const Icon(Icons.login),
                          label: Text(l.signInWithGoogle, style: const TextStyle(fontSize: 17)),
                        ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: auth.busy ? null : _done,
                      child: Text(l.continueAsGuest, style: const TextStyle(fontSize: 17)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.loginGuestNote,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
