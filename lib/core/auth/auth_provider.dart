import 'dart:async';

import 'package:blast_buddies/core/auth/auth_service.dart';
import 'package:blast_buddies/core/auth/platform_auth.dart';
import 'package:blast_buddies/core/auth/supabase_config.dart';
import 'package:blast_buddies/net/server/supabase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app-wide [AuthService]; tests override it.
final authServiceProvider = Provider<AuthService>((ref) => AuthService(
      api: SupabaseApi(SupabaseConfig.url, SupabaseConfig.publishableKey),
      store: const SecureSessionStore(),
      tokens: PlatformIdTokens(),
    ));

/// Outcome of a sign-in attempt.
enum SignInResult {
  /// Signed in.
  ok,

  /// The player closed the system sheet.
  cancelled,

  /// Something went wrong.
  failed,
}

/// Sign-in state.
class AuthState {
  /// Creates a state.
  const AuthState({this.session, this.busy = false, this.ready = false});

  /// Current session, null for a guest.
  final AuthSession? session;

  /// A sign-in or sign-out is running.
  final bool busy;

  /// The stored session has been loaded.
  final bool ready;

  /// Signed in.
  bool get signedIn => session != null;
}

/// Drives [AuthService] for the UI.
class AuthNotifier extends Notifier<AuthState> {
  AuthService get _service => ref.read(authServiceProvider);

  @override
  AuthState build() {
    unawaited(_restore());
    return const AuthState();
  }

  Future<void> _restore() async {
    final s = await _service.restore();
    state = AuthState(session: s, ready: true);
  }

  /// Whether [p] is offered on this device.
  bool supports(AuthProvider p) => _service.tokens.isSupported(p);

  /// Signs in with [p].
  Future<SignInResult> signIn(AuthProvider p) async {
    state = AuthState(session: state.session, busy: true, ready: true);
    try {
      final s = await _service.signIn(p);
      state = AuthState(session: s, ready: true);
      return SignInResult.ok;
    } on AuthCancelled {
      state = AuthState(session: state.session, ready: true);
      return SignInResult.cancelled;
    } on Object {
      state = AuthState(session: state.session, ready: true);
      return SignInResult.failed;
    }
  }

  /// Signs out.
  Future<void> signOut() async {
    state = AuthState(session: state.session, busy: true, ready: true);
    await _service.signOut();
    state = const AuthState(ready: true);
  }

  /// A token that is valid now (refreshed if necessary), or null.
  Future<String?> freshToken() async {
    final t = await _service.freshToken();
    final s = _service.session;
    if (s?.accessToken != state.session?.accessToken) state = AuthState(session: s, ready: state.ready);
    return t;
  }
}

/// See [AuthNotifier].
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
