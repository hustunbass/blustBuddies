import 'dart:convert';
import 'dart:io';

import 'package:blast_buddies/core/auth/auth_provider.dart';
import 'package:blast_buddies/core/auth/auth_service.dart';
import 'package:blast_buddies/core/economy/grants.dart';
import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/net/server/blast_server.dart';
import 'package:blast_buddies/net/server/rank_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth.dart';

/// Ack that always fails: the server keeps offering the gift.
class _FlakyAck extends GrantsClient {
  @override
  Future<void> ack(Uri base, String token, List<int> ids) async => throw const HttpException('offline');
}

void main() {
  late BlastServer server;
  late InMemoryRankStore store;
  late Uri base;

  Future<(int, Map<String, dynamic>)> call(String path, {String? token, String method = 'POST', Object? body}) async {
    final http = HttpClient();
    try {
      final req = await http.openUrl(method, base.resolve(path));
      if (token != null) req.headers.set('authorization', 'Bearer $token');
      if (body != null) req.add(utf8.encode(jsonEncode(body)));
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      return (res.statusCode, text.isEmpty ? <String, dynamic>{} : (jsonDecode(text) as Map).cast<String, dynamic>());
    } finally {
      http.close(force: true);
    }
  }

  Future<void> boot({Duration interval = Duration.zero, bool ranked = true}) async {
    store = InMemoryRankStore();
    server = BlastServer(
      auth: ranked ? DevAuthVerifier() : null,
      ranks: ranked ? store : null,
      grantsMinInterval: interval,
    );
    base = Uri.parse('http://127.0.0.1:${await server.start(port: 0, address: '127.0.0.1')}');
  }

  tearDown(() => server.close());

  group('server endpoints', () {
    test('only the signed-in player gets his own gifts', () async {
      await boot();
      store
        ..addGrant('ann', 500)
        ..addGrant('bob', 9000)
        ..addGrant('ann', 250);
      final (status, body) = await call('/grants', token: 'dev:ann');
      expect(status, 200);
      expect((body['grants'] as List).map((g) => (g as Map)['coins']), [500, 250]);
      expect(body.toString().contains('note'), isFalse, reason: 'the admin note stays private');
    });

    test('no token, a bad token, the wrong method and a casual-only server are all refused', () async {
      await boot();
      expect((await call('/grants')).$1, 401);
      expect((await call('/grants', token: 'garbage')).$1, 401);
      expect((await call('/grants', token: 'dev:ann', method: 'GET')).$1, 405);
      await server.close();
      await boot(ranked: false);
      expect((await call('/grants', token: 'dev:ann')).$1, 404);
    });

    test('confirming marks the gifts claimed once; other players\' gifts are untouched', () async {
      await boot();
      final a = store.addGrant('ann', 500);
      final b = store.addGrant('bob', 700);
      expect((await call('/grants/ack', token: 'dev:ann', body: {'ids': [a, b]})).$1, 200);
      expect(store.claimedGrants, [a], reason: 'ann cannot confirm bob\'s gift');
      final (_, again) = await call('/grants', token: 'dev:ann');
      expect(again['grants'], isEmpty);
      final (_, bobs) = await call('/grants', token: 'dev:bob');
      expect((bobs['grants'] as List).length, 1);
    });

    test('garbage in the confirmation is a bad request, not a crash', () async {
      await boot();
      final http = HttpClient();
      final req = await http.postUrl(base.resolve('/grants/ack'));
      req.headers.set('authorization', 'Bearer dev:ann');
      req.add(utf8.encode('{not json'));
      final res = await req.close();
      expect(res.statusCode, 400);
      await res.drain<void>();
      http.close(force: true);
      expect((await call('/grants', token: 'dev:ann')).$1, 200, reason: 'still serving');
    });

    test('asking again within the interval is throttled', () async {
      await boot(interval: const Duration(seconds: 5));
      expect((await call('/grants', token: 'dev:ann')).$1, 200);
      expect((await call('/grants', token: 'dev:ann')).$1, 429);
      expect((await call('/grants', token: 'dev:bob')).$1, 200, reason: 'per player');
    });
  });

  group('claimGrants', () {
    late ProviderContainer c;
    late SharedPreferences prefs;

    Future<void> setUpClient({
      AuthSession? session,
      GrantsClient? client,
      String token = 'dev:ann',
    }) async {
      SharedPreferences.setMockInitialValues({
        'walletInit': true,
        'coin': 100,
        'onlineCustomServer': '127.0.0.1:${base.port}',
      });
      prefs = await SharedPreferences.getInstance();
      c = ProviderContainer(overrides: [
        prefsProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(FakeAuthService(session: session, token: token)),
        if (client != null) grantsClientProvider.overrideWithValue(client),
      ]);
      addTearDown(c.dispose);
      await c.read(authProvider.notifier).restored;
    }

    test('adds the coins, confirms them and publishes a notice', () async {
      await boot();
      store
        ..addGrant('ann', 500)
        ..addGrant('ann', 250);
      await setUpClient(session: FakeAuthService.sessionFor(AuthProvider.apple));
      expect(await claimGrants(c), 750);
      expect(c.read(walletProvider).coin, 850);
      expect(c.read(grantNoticeProvider), 750);
      expect(store.claimedGrants.length, 2);
      expect(await claimGrants(c), 0, reason: 'nothing left');
      expect(c.read(walletProvider).coin, 850);
    });

    test('a gift is credited once even when confirming fails and the server offers it again', () async {
      await boot();
      store.addGrant('ann', 500);
      await setUpClient(session: FakeAuthService.sessionFor(AuthProvider.apple), client: _FlakyAck());
      expect(await claimGrants(c), 500);
      expect(store.claimedGrants, isEmpty, reason: 'the confirmation never arrived');
      expect(await claimGrants(c), 0, reason: 'the same gift is not paid twice');
      expect(c.read(walletProvider).coin, 600);
    });

    test('guests, a missing server and a rejected token just give nothing', () async {
      await boot();
      store.addGrant('ann', 500);
      await setUpClient();
      expect(await claimGrants(c), 0, reason: 'guest');
      c.dispose();
      await setUpClient(session: FakeAuthService.sessionFor(AuthProvider.apple, token: 'bad'));
      expect(await claimGrants(c), 0, reason: 'token rejected');
      c.dispose();
      await server.close();
      await setUpClient(session: FakeAuthService.sessionFor(AuthProvider.apple));
      expect(await claimGrants(c), 0, reason: 'server down: no crash');
      expect(c.read(walletProvider).coin, 100);
    });
  });
}
