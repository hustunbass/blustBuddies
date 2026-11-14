import 'package:blast_buddies/core/auth/auth_provider.dart';
import 'package:blast_buddies/core/auth/auth_service.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/features/auth/account_actions.dart';
import 'package:blast_buddies/features/online/online_screen.dart';
import 'package:blast_buddies/net/online_client.dart';
import 'package:blast_buddies/net/server/blast_server.dart';
import 'package:blast_buddies/net/server/rank_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth.dart';

void main() {
  late BlastServer server;
  late InMemoryRankStore store;
  late String address;
  late FakeAuthService auth;
  late ProviderContainer c;
  late OnlineClient client;

  Future<void> boot({AuthSession? session}) async {
    store = InMemoryRankStore();
    server = BlastServer(auth: DevAuthVerifier(), ranks: store);
    address = '127.0.0.1:${await server.start(port: 0, address: '127.0.0.1')}';
    SharedPreferences.setMockInitialValues({'onlineCustomServer': address});
    final sp = await SharedPreferences.getInstance();
    auth = FakeAuthService(session: session);
    // Fail fast when the server is gone instead of waiting for it to wake up.
    client = OnlineClient(wakeUpTime: const Duration(milliseconds: 300), retryDelay: const Duration(milliseconds: 100));
    c = ProviderContainer(overrides: [
      prefsProvider.overrideWithValue(sp),
      authServiceProvider.overrideWithValue(auth),
      onlineClientProvider.overrideWithValue(client),
    ]);
    // Let the stored session load, as the app does at launch.
    await c.read(authProvider.notifier).restored;
    c.read(authProvider);
  }

  tearDown(() async {
    await client.disconnect();
    c.dispose();
    await server.close();
  });

  test('deleting from Settings connects on its own, deletes on the server and signs out', () async {
    await boot(session: FakeAuthService.sessionFor(AuthProvider.apple, token: 'dev:ann'));
    expect(client.status, OnlineStatus.disconnected, reason: 'the player never opened Online');
    expect(await deleteAccountFlow(c), isTrue);
    expect(store.deleted, ['ann']);
    expect(auth.signOuts, 1);
    expect(c.read(authProvider).signedIn, isFalse);
    expect(client.status, OnlineStatus.disconnected);
  });

  test('when the server cannot be reached nothing is deleted and the player stays signed in', () async {
    await boot(session: FakeAuthService.sessionFor(AuthProvider.apple, token: 'dev:ann'));
    await server.close();
    expect(await deleteAccountFlow(c), isFalse);
    expect(auth.signOuts, 0);
    expect(c.read(authProvider).signedIn, isTrue);
  });

  test('a token the server rejects cannot delete anything and keeps the session', () async {
    await boot(session: FakeAuthService.sessionFor(AuthProvider.apple, token: 'not-valid'));
    expect(await deleteAccountFlow(c), isFalse);
    expect(store.deleted, isEmpty);
    expect(auth.signOuts, 0);
  });

  test('signing in while Online is open renews the connection so the server knows the player', () async {
    await boot();
    expect(await reconnectOnline(c, client), isTrue);
    expect(client.rank, isNull, reason: 'connected as a guest');
    final result = await signInFlow(c, AuthProvider.apple);
    expect(result, SignInResult.ok);
    expect(client.status, OnlineStatus.connected);
    expect(client.rank, isNotNull, reason: 'reconnected with the token');
  });

  test('signing out while Online is open continues as a guest', () async {
    await boot(session: FakeAuthService.sessionFor(AuthProvider.apple, token: 'dev:ann'));
    expect(await reconnectOnline(c, client), isTrue);
    expect(client.rank, isNotNull);
    await signOutFlow(c);
    expect(client.status, OnlineStatus.connected);
    expect(client.rank, isNull);
    expect(auth.signOuts, 1);
  });

  test('signing in with Online closed does not open a connection', () async {
    await boot();
    expect(await signInFlow(c, AuthProvider.apple), SignInResult.ok);
    expect(client.status, OnlineStatus.disconnected);
  });
}
