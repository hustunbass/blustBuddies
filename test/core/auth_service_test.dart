import 'dart:convert';
import 'dart:io';

import 'package:blast_buddies/core/auth/auth_service.dart';
import 'package:blast_buddies/net/server/supabase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSupabase {
  final requests = <({String method, String path, String bearer, String apikey, Map<String, dynamic> body})>[];
  final replies = <String, (int, String)>{};
  late HttpServer server;

  Future<String> start() async {
    server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      final text = await utf8.decoder.bind(req).join();
      requests.add((
        method: req.method,
        path: req.uri.toString(),
        bearer: req.headers.value('authorization') ?? '',
        apikey: req.headers.value('apikey') ?? '',
        body: text.isEmpty ? {} : (jsonDecode(text) as Map).cast<String, dynamic>(),
      ));
      final key = replies.keys.firstWhere((k) => req.uri.toString().startsWith(k), orElse: () => '');
      final (status, body) = replies[key] ?? (404, '{"msg":"nope"}');
      req.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(body);
      await req.response.close();
    });
    return 'http://127.0.0.1:${server.port}';
  }
}

class _FakeTokens implements IdTokenSource {
  IdCredential? next = const IdCredential('apple-id-token', nonce: 'raw-nonce');
  final signedOut = <AuthProvider>[];

  @override
  bool isSupported(AuthProvider provider) => provider == AuthProvider.apple;

  @override
  Future<IdCredential?> obtain(AuthProvider provider) async => next;

  @override
  Future<void> signOut(AuthProvider provider) async => signedOut.add(provider);
}

String _tokenReply({String access = 'access-1', String refresh = 'refresh-1', int expiresIn = 3600}) =>
    jsonEncode({'access_token': access, 'refresh_token': refresh, 'expires_in': expiresIn, 'user': {'id': 'u-1'}});

void main() {
  late _FakeSupabase fake;
  late _FakeTokens tokens;
  late MemorySessionStore store;
  late DateTime now;
  late AuthService service;

  setUp(() async {
    fake = _FakeSupabase();
    final url = await fake.start();
    tokens = _FakeTokens();
    store = MemorySessionStore();
    now = DateTime.utc(2026, 11, 14, 12);
    service = AuthService(api: SupabaseApi(url, 'sb_publishable_x'), store: store, tokens: tokens, now: () => now);
  });

  tearDown(() => fake.server.close(force: true));

  test('sign-in sends the ID token and the raw nonce, then keeps the session', () async {
    fake.replies['/auth/v1/token?grant_type=id_token'] = (200, _tokenReply());
    final s = await service.signIn(AuthProvider.apple);
    expect(s.accessToken, 'access-1');
    final r = fake.requests.single;
    expect(r.method, 'POST');
    expect(r.body, {'provider': 'apple', 'id_token': 'apple-id-token', 'nonce': 'raw-nonce'});
    expect(r.apikey, 'sb_publishable_x');
    expect(r.bearer, '', reason: 'a publishable key is not a bearer token');
    expect(service.session, isNotNull);
    expect(store.value, isNotNull, reason: 'persisted for the next launch');
    expect(s.expiresAt, now.add(const Duration(hours: 1)));
  });

  test('cancelling the system sheet throws AuthCancelled and calls nothing', () async {
    tokens.next = null;
    await expectLater(service.signIn(AuthProvider.apple), throwsA(isA<AuthCancelled>()));
    expect(fake.requests, isEmpty);
    expect(service.session, isNull);
  });

  test('a rejected sign-in throws AuthFailure with the server message', () async {
    fake.replies['/auth/v1/token?grant_type=id_token'] = (400, '{"msg":"Unsupported provider: provider is not enabled"}');
    await expectLater(
      service.signIn(AuthProvider.apple),
      throwsA(isA<AuthFailure>().having((e) => e.message, 'message', contains('not enabled'))),
    );
    expect(service.session, isNull);
    expect(store.value, isNull);
  });

  test('a still valid token is used as is, an expiring one is refreshed and stored', () async {
    fake.replies['/auth/v1/token?grant_type=id_token'] = (200, _tokenReply());
    await service.signIn(AuthProvider.apple);
    fake.requests.clear();
    expect(await service.freshToken(), 'access-1');
    expect(fake.requests, isEmpty);

    now = now.add(const Duration(minutes: 59)); // 1 minute left, inside the 2 minute margin
    fake.replies['/auth/v1/token?grant_type=refresh_token'] = (200, _tokenReply(access: 'access-2', refresh: 'refresh-2'));
    expect(await service.freshToken(), 'access-2');
    expect(fake.requests.single.body, {'refresh_token': 'refresh-1'});
    expect(store.value, contains('refresh-2'));
  });

  test('a refresh the server refuses signs the player out', () async {
    fake.replies['/auth/v1/token?grant_type=id_token'] = (200, _tokenReply());
    await service.signIn(AuthProvider.apple);
    now = now.add(const Duration(hours: 2));
    fake.replies['/auth/v1/token?grant_type=refresh_token'] = (400, '{"msg":"Invalid Refresh Token"}');
    expect(await service.freshToken(), isNull);
    expect(service.session, isNull);
    expect(store.value, isNull);
  });

  test('offline during a refresh keeps the session while the old token is still valid', () async {
    fake.replies['/auth/v1/token?grant_type=id_token'] = (200, _tokenReply());
    await service.signIn(AuthProvider.apple);
    now = now.add(const Duration(minutes: 59));
    fake.replies['/auth/v1/token?grant_type=refresh_token'] = (503, 'down');
    expect(await service.freshToken(), 'access-1');
    expect(service.session, isNotNull);
  });

  test('restore loads the stored session and refreshes it when it expired', () async {
    store.value = jsonEncode(AuthSession(
      accessToken: 'old',
      refreshToken: 'refresh-old',
      expiresAt: now.subtract(const Duration(minutes: 5)),
      provider: AuthProvider.google,
    ).toJson());
    fake.replies['/auth/v1/token?grant_type=refresh_token'] = (200, _tokenReply(access: 'new', refresh: 'refresh-new'));
    final s = await service.restore();
    expect(s!.accessToken, 'new');
    expect(s.provider, AuthProvider.google, reason: 'the sign-in method is remembered');
  });

  test('restore ignores garbage in storage', () async {
    store.value = 'not json';
    expect(await service.restore(), isNull);
    expect(store.value, isNull);
  });

  test('sign-out clears everything, tells Supabase and the provider', () async {
    fake.replies['/auth/v1/token?grant_type=id_token'] = (200, _tokenReply());
    fake.replies['/auth/v1/logout'] = (204, '');
    await service.signIn(AuthProvider.apple);
    fake.requests.clear();
    await service.signOut();
    expect(service.session, isNull);
    expect(store.value, isNull);
    expect(fake.requests.single.path, startsWith('/auth/v1/logout'));
    expect(fake.requests.single.bearer, 'Bearer access-1');
    expect(tokens.signedOut, [AuthProvider.apple]);
  });

  test('sign-out works offline', () async {
    fake.replies['/auth/v1/token?grant_type=id_token'] = (200, _tokenReply());
    await service.signIn(AuthProvider.apple);
    await fake.server.close(force: true);
    await service.signOut();
    expect(service.session, isNull);
    expect(store.value, isNull);
  });
}
