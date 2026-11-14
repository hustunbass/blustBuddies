import 'package:blast_buddies/core/auth/auth_service.dart';
import 'package:blast_buddies/net/server/supabase.dart';

class _Tokens implements IdTokenSource {
  _Tokens(this.supported);

  final Set<AuthProvider> supported;

  @override
  bool isSupported(AuthProvider p) => supported.contains(p);

  @override
  Future<IdCredential?> obtain(AuthProvider p) async => null;

  @override
  Future<void> signOut(AuthProvider p) async {}
}

/// An [AuthService] that never touches the network or the platform.
class FakeAuthService extends AuthService {
  FakeAuthService({
    AuthSession? session,
    Set<AuthProvider> supported = const {AuthProvider.apple},
    this.token = 'dev:ann',
  })  : _session = session,
        super(
          api: SupabaseApi('http://127.0.0.1:1', 'sb_publishable_test'),
          store: MemorySessionStore(),
          tokens: _Tokens(supported),
        );

  AuthSession? _session;

  /// Access token handed out after signing in.
  final String token;

  /// Next sign-in fails / is cancelled.
  bool failNext = false, cancelNext = false;

  /// How many times the player signed out.
  int signOuts = 0;

  /// A ready-made session for tests.
  static AuthSession sessionFor(AuthProvider p, {String token = 'dev:ann'}) => AuthSession(
        accessToken: token,
        refreshToken: 'r',
        expiresAt: DateTime.utc(2099),
        provider: p,
      );

  @override
  AuthSession? get session => _session;

  @override
  Future<AuthSession?> restore() async => _session;

  @override
  Future<AuthSession> signIn(AuthProvider provider) async {
    if (cancelNext) {
      cancelNext = false;
      throw AuthCancelled();
    }
    if (failNext) {
      failNext = false;
      throw AuthFailure('test');
    }
    return _session = sessionFor(provider, token: token);
  }

  @override
  Future<String?> freshToken() async => _session?.accessToken;

  @override
  Future<void> signOut() async {
    _session = null;
    signOuts++;
  }
}
