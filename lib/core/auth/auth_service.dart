import 'dart:convert';

import 'package:blast_buddies/net/server/supabase.dart';

/// Sign-in methods.
enum AuthProvider {
  /// Sign in with Apple (iOS).
  apple,

  /// Google sign-in (iOS and Android).
  google,
}

/// What the platform gives after the player picked an account.
class IdCredential {
  /// Creates a credential.
  const IdCredential(this.idToken, {this.nonce});

  /// The provider's ID token (a JWT).
  final String idToken;

  /// The *raw* nonce whose hash the provider put into the token, if any.
  final String? nonce;
}

/// Platform part of signing in (system sheets of Apple and Google).
abstract class IdTokenSource {
  /// Whether [provider] can be used on this device with this configuration.
  bool isSupported(AuthProvider provider);

  /// Shows the system sheet. Null when the player cancelled.
  Future<IdCredential?> obtain(AuthProvider provider);

  /// Forgets the provider's own session.
  Future<void> signOut(AuthProvider provider);
}

/// Where the session is kept between launches (Keychain / Keystore).
abstract class SessionStore {
  /// Stored value, if any.
  Future<String?> read();

  /// Stores [value]; null deletes it.
  Future<void> write(String? value);
}

/// [SessionStore] in memory (tests).
class MemorySessionStore implements SessionStore {
  /// Creates a store, optionally pre-filled.
  MemorySessionStore([this.value]);

  /// Current value.
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String? v) async => value = v;
}

/// A Supabase session.
class AuthSession {
  /// Creates a session.
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.provider,
  });

  /// Parses the stored form.
  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        accessToken: j['a'] as String,
        refreshToken: j['r'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch((j['e'] as num).toInt(), isUtc: true),
        provider: AuthProvider.values.firstWhere((p) => p.name == j['p'], orElse: () => AuthProvider.apple),
      );

  /// Short-lived token the game server checks.
  final String accessToken;

  /// Long-lived token used to get a new access token.
  final String refreshToken;

  /// When [accessToken] expires.
  final DateTime expiresAt;

  /// How the player signed in.
  final AuthProvider provider;

  /// True if the access token is expired or about to be.
  bool expiresWithin(Duration d, DateTime now) => expiresAt.difference(now) <= d;

  /// Stored form.
  Map<String, dynamic> toJson() => {
        'a': accessToken,
        'r': refreshToken,
        'e': expiresAt.millisecondsSinceEpoch,
        'p': provider.name,
      };
}

/// The player closed the system sheet.
class AuthCancelled implements Exception {
  @override
  String toString() => 'sign-in cancelled';
}

/// Sign-in failed (network, provider disabled, bad token ...).
class AuthFailure implements Exception {
  /// Creates a failure.
  AuthFailure(this.message);

  /// What went wrong, for logs.
  final String message;

  @override
  String toString() => 'sign-in failed: $message';
}

/// Signs players in through Supabase Auth and keeps the session fresh.
class AuthService {
  /// Creates the service; [api] must use the publishable key.
  AuthService({
    required this.api,
    required this.store,
    required this.tokens,
    DateTime Function()? now,
    this.refreshMargin = const Duration(minutes: 2),
  }) : _now = now ?? DateTime.now;

  /// Supabase client (publishable key).
  final SupabaseApi api;

  /// Session storage.
  final SessionStore store;

  /// Apple / Google sheets.
  final IdTokenSource tokens;

  /// A token that expires within this long is refreshed before use.
  final Duration refreshMargin;

  final DateTime Function() _now;
  AuthSession? _session;

  /// Current session, null when signed out.
  AuthSession? get session => _session;

  /// Loads the stored session and refreshes it if needed.
  Future<AuthSession?> restore() async {
    try {
      final raw = await store.read();
      if (raw == null) return null;
      _session = AuthSession.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } on Object {
      await store.write(null);
      return null;
    }
    await freshToken();
    return _session;
  }

  /// Opens the system sheet for [provider] and signs in. Throws
  /// [AuthCancelled] or [AuthFailure].
  Future<AuthSession> signIn(AuthProvider provider) async {
    final cred = await tokens.obtain(provider);
    if (cred == null) throw AuthCancelled();
    final (status, body) = await _post('/auth/v1/token?grant_type=id_token', {
      'provider': provider.name,
      'id_token': cred.idToken,
      if (cred.nonce != null) 'nonce': cred.nonce,
    });
    if (status != 200) throw AuthFailure('sign-in rejected ($status): ${_msg(body)}');
    return _save(_parse(body, provider));
  }

  /// A usable access token (refreshed when it is about to expire), or null if
  /// signed out. A refresh the server rejects signs the player out.
  Future<String?> freshToken() async {
    final s = _session;
    if (s == null) return null;
    if (!s.expiresWithin(refreshMargin, _now())) return s.accessToken;
    try {
      final (status, body) = await _post('/auth/v1/token?grant_type=refresh_token', {'refresh_token': s.refreshToken});
      if (status == 200) return (await _save(_parse(body, s.provider))).accessToken;
      if (status >= 400 && status < 500) {
        _session = null;
        await store.write(null);
        return null;
      }
    } on Object {
      // Offline: keep the session, the old token may still be accepted.
    }
    return s.expiresAt.isAfter(_now()) ? s.accessToken : null;
  }

  /// Signs out here and at the provider.
  Future<void> signOut() async {
    final s = _session;
    _session = null;
    await store.write(null);
    if (s == null) return;
    try {
      await api.request('POST', '/auth/v1/logout?scope=local', bearer: s.accessToken);
    } on Object {
      // The local session is already gone; the server copy expires by itself.
    }
    await tokens.signOut(s.provider);
  }

  Future<(int, String)> _post(String path, Map<String, dynamic> body) =>
      api.request('POST', path, body: body);

  AuthSession _parse(String body, AuthProvider provider) {
    final j = jsonDecode(body);
    if (j is! Map || j['access_token'] is! String || j['refresh_token'] is! String) {
      throw AuthFailure('unexpected answer');
    }
    final seconds = (j['expires_in'] as num?)?.toInt() ?? 3600;
    return AuthSession(
      accessToken: j['access_token'] as String,
      refreshToken: j['refresh_token'] as String,
      expiresAt: _now().toUtc().add(Duration(seconds: seconds)),
      provider: provider,
    );
  }

  Future<AuthSession> _save(AuthSession s) async {
    _session = s;
    await store.write(jsonEncode(s.toJson()));
    return s;
  }

  static String _msg(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map) return '${j['msg'] ?? j['error_description'] ?? j['message'] ?? body}';
    } on Object {
      // fall through
    }
    return body;
  }
}
