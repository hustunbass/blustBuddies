import 'package:blast_buddies/app.dart';
import 'package:blast_buddies/core/auth/auth_provider.dart';
import 'package:blast_buddies/core/auth/auth_service.dart';
import 'package:blast_buddies/core/economy/grants.dart';
import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/profile/profile.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/ui/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth.dart';

class _OneGift extends GrantsClient {
  final acked = <int>[];

  @override
  Future<List<GrantItem>> pending(Uri base, String token) async => acked.isEmpty ? [const GrantItem(11, 500)] : const [];

  @override
  Future<void> ack(Uri base, String token, List<int> ids) async => acked.addAll(ids);
}

Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  required FakeAuthService auth,
  Map<String, Object> prefs = const {},
  GrantsClient? grants,
}) async {
  tester.platformDispatcher.localesTestValue = const [Locale('en')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  SharedPreferences.setMockInitialValues({'onboardingOffered': true, ...prefs});
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(sp),
    authServiceProvider.overrideWithValue(auth),
    if (grants != null) grantsClientProvider.overrideWithValue(grants),
  ]);
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const BlastBuddiesApp()));
  await tester.pumpAndSettle();
  return container;
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
}

void main() {
  group('first-launch login screen', () {
    testWidgets('is shown before the menu with Apple and a guest option', (tester) async {
      await pumpApp(tester, auth: FakeAuthService());
      expect(find.text('Welcome to Boom Pals'), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsOneWidget);
      expect(find.text('Continue as guest'), findsOneWidget);
      expect(find.text('Story'), findsNothing, reason: 'the menu comes after');
    });

    testWidgets('continuing as a guest opens the menu and is remembered', (tester) async {
      final c = await pumpApp(tester, auth: FakeAuthService());
      await tester.tap(find.text('Continue as guest'));
      await tester.pumpAndSettle();
      expect(find.text('Story'), findsOneWidget);
      expect(c.read(authProvider).signedIn, isFalse);
      expect(c.read(prefsProvider).getBool('loginPromptDone'), isTrue);
    });

    testWidgets('does not come back once the player decided', (tester) async {
      await pumpApp(tester, auth: FakeAuthService(), prefs: {'loginPromptDone': true});
      expect(find.text('Welcome to Boom Pals'), findsNothing);
      expect(find.text('Story'), findsOneWidget);
    });

    testWidgets('signing in opens the menu, links the profile and is remembered', (tester) async {
      final c = await pumpApp(tester, auth: FakeAuthService());
      await tester.tap(find.text('Sign in with Apple'));
      await tester.pumpAndSettle();
      expect(find.text('Story'), findsOneWidget);
      expect(c.read(authProvider).signedIn, isTrue);
      expect(c.read(profileProvider).kind, AuthKind.apple);
      expect(c.read(prefsProvider).getBool('loginPromptDone'), isTrue);
    });

    testWidgets('a failed sign-in stays on the screen; cancelling too', (tester) async {
      final auth = FakeAuthService()..failNext = true;
      await pumpApp(tester, auth: auth);
      await tester.tap(find.text('Sign in with Apple'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Boom Pals'), findsOneWidget);
      auth.cancelNext = true;
      await tester.tap(find.text('Sign in with Apple'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Boom Pals'), findsOneWidget);
    });

    testWidgets('a session kept from an earlier launch skips the screen: no second sign-in', (tester) async {
      final auth = FakeAuthService(session: FakeAuthService.sessionFor(AuthProvider.google));
      final c = await pumpApp(tester, auth: auth);
      expect(find.text('Welcome to Boom Pals'), findsNothing);
      expect(find.text('Story'), findsOneWidget);
      expect(c.read(profileProvider).kind, AuthKind.google, reason: 'the profile follows the restored session');
    });

    testWidgets('not shown where no sign-in method exists', (tester) async {
      await pumpApp(tester, auth: FakeAuthService(supported: const {}));
      expect(find.text('Welcome to Boom Pals'), findsNothing);
      expect(find.text('Story'), findsOneWidget);
    });
  });

  group('settings account section', () {
    testWidgets('a guest can sign in there; no sign-out or delete', (tester) async {
      await pumpApp(tester, auth: FakeAuthService(), prefs: {'loginPromptDone': true});
      await openSettings(tester);
      expect(find.textContaining('Sign in to play ranked'), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);
      expect(find.text('Delete account'), findsNothing);
    });

    testWidgets('signing in from settings switches the section', (tester) async {
      final c = await pumpApp(tester, auth: FakeAuthService(), prefs: {'loginPromptDone': true});
      await openSettings(tester);
      await tester.tap(find.text('Sign in with Apple'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsNothing);
      expect(c.read(profileProvider).kind, AuthKind.apple);
      expect(find.text('Signed in with Apple'), findsOneWidget);
    });

    testWidgets('signed-in players can sign out; the session is gone and the profile is a guest again', (tester) async {
      final auth = FakeAuthService(session: FakeAuthService.sessionFor(AuthProvider.apple));
      final c = await pumpApp(tester, auth: auth, prefs: {'loginPromptDone': true});
      await openSettings(tester);
      expect(find.text('Sign out'), findsOneWidget);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(auth.signOuts, 1);
      expect(c.read(authProvider).signedIn, isFalse);
      expect(c.read(profileProvider).kind, AuthKind.guest);
      expect(find.text('Sign in with Apple'), findsOneWidget);
      expect(find.text('Guest account'), findsOneWidget);
    });

    testWidgets('deleting asks first; cancelling changes nothing', (tester) async {
      final auth = FakeAuthService(session: FakeAuthService.sessionFor(AuthProvider.apple));
      final c = await pumpApp(tester, auth: auth, prefs: {'loginPromptDone': true});
      await openSettings(tester);
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.textContaining('cannot be undone'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete your account?'), findsNothing);
      expect(c.read(authProvider).signedIn, isTrue);
      expect(auth.signOuts, 0);
    });
  });

  group('gifts', () {
    testWidgets('a gift waiting for a signed-in player is credited at launch with a toast', (tester) async {
      final grants = _OneGift();
      // The toast comes and goes while the app settles: record what was shown.
      final seen = <String>[];
      void record() {
        final t = toasts.current;
        if (t != null) seen.add(t.text);
      }

      toasts.addListener(record);
      addTearDown(() => toasts.removeListener(record));
      final c = await pumpApp(
        tester,
        auth: FakeAuthService(session: FakeAuthService.sessionFor(AuthProvider.apple)),
        prefs: {'loginPromptDone': true, 'walletInit': true, 'coin': 100},
        grants: grants,
      );
      expect(c.read(walletProvider).coin, 600);
      expect(grants.acked, [11]);
      expect(seen, contains('A gift for you: +500 coins'));
    });

    testWidgets('a guest gets no gifts', (tester) async {
      final grants = _OneGift();
      final c = await pumpApp(
        tester,
        auth: FakeAuthService(),
        prefs: {'loginPromptDone': true, 'walletInit': true, 'coin': 100},
        grants: grants,
      );
      expect(c.read(walletProvider).coin, 100);
      expect(grants.acked, isEmpty);
    });

    testWidgets('signing in picks up the waiting gift right away', (tester) async {
      final grants = _OneGift();
      final c = await pumpApp(
        tester,
        auth: FakeAuthService(),
        prefs: {'walletInit': true, 'coin': 100},
        grants: grants,
      );
      await tester.tap(find.text('Sign in with Apple'));
      await tester.pumpAndSettle();
      expect(c.read(walletProvider).coin, 600);
      await tester.pump(const Duration(seconds: 10));
    });
  });

  test('the token is only handed out after the stored session is loaded', () async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final auth = FakeAuthService(session: FakeAuthService.sessionFor(AuthProvider.apple, token: 'dev:kept'));
    final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(sp), authServiceProvider.overrideWithValue(auth)]);
    addTearDown(c.dispose);
    // Asked immediately, before anybody listened to the state.
    expect(await c.read(authProvider.notifier).freshToken(), 'dev:kept');
  });
}
