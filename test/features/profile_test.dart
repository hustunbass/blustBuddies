import 'dart:math';

import 'package:blast_buddies/core/profile/profile.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/features/profile/profile_widgets.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/net/protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> container([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(sp)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('default names', () {
    test('guests get Guest_#### / Misafir_#### and it is stored', () async {
      final c = await container();
      final p = c.read(profileProvider);
      expect(p.kind, AuthKind.guest);
      expect(p.customName, isFalse);
      expect(p.name, matches(RegExp(r'^(Guest|Misafir)_\d{4}$')));
      expect(c.read(prefsProvider).getString('username'), p.name);
    });

    test('suggestions follow the language and always fit the server limit', () {
      final rng = Random(1);
      expect(PlayerNames.suggest(AuthKind.guest, rng: rng, turkish: true), startsWith('Misafir_'));
      expect(PlayerNames.suggest(AuthKind.guest, rng: rng, turkish: false), startsWith('Guest_'));
      for (var i = 0; i < 300; i++) {
        for (final kind in AuthKind.values) {
          for (final tr in [true, false]) {
            final n = PlayerNames.suggest(kind, rng: rng, turkish: tr);
            expect(n.length, lessThanOrEqualTo(Limits.name), reason: n);
            expect(PlayerNames.isValid(n), isTrue, reason: n);
          }
        }
      }
    });

    test('account names are friendlier than guest names', () {
      final n = PlayerNames.suggest(AuthKind.google, rng: Random(2), turkish: false);
      expect(n, isNot(startsWith('Guest')));
      expect(n, matches(RegExp(r'^[A-Za-z]+_\d{4}$')));
    });
  });

  group('editing', () {
    test('a valid name is cleaned, saved and marked as the player\'s own', () async {
      final c = await container();
      expect(await c.read(profileProvider.notifier).rename('  Ece   Naz '), isTrue);
      expect(c.read(profileProvider).name, 'Ece Naz');
      expect(c.read(profileProvider).customName, isTrue);
      expect(c.read(prefsProvider).getString('username'), 'Ece Naz');
    });

    test('invalid names are rejected and change nothing', () async {
      final c = await container({'username': 'Keep_1', 'usernameCustom': true});
      final n = c.read(profileProvider.notifier);
      for (final bad in ['', ' ', 'a', 'x' * 17, 'no<script>', 'emoji😀']) {
        expect(await n.rename(bad), isFalse, reason: bad);
      }
      expect(c.read(profileProvider).name, 'Keep_1');
    });

    test('Turkish letters and digits are fine', () {
      expect(PlayerNames.isValid('Şükrü_99'), isTrue);
      expect(PlayerNames.isValid('Ağaç.Kız-2'), isTrue);
    });

    test('randomize replaces the name with a fresh default', () async {
      final c = await container({'username': 'Ece', 'usernameCustom': true});
      final name = await c.read(profileProvider.notifier).randomize();
      expect(name, matches(RegExp(r'^(Guest|Misafir)_\d{4}$')));
      expect(c.read(profileProvider).customName, isFalse);
    });

    test('the name typed for online play in earlier versions is kept', () async {
      final c = await container({'onlineName': 'Ece'});
      expect(c.read(profileProvider).name, 'Ece');
      expect(c.read(profileProvider).customName, isTrue);
    });

    test('the name survives a restart', () async {
      final c = await container();
      await c.read(profileProvider.notifier).rename('Berk');
      final again = await container({'username': 'Berk', 'usernameCustom': true});
      expect(again.read(profileProvider).name, 'Berk');
    });
  });

  group('signing in later (Apple / Google)', () {
    test('an auto-generated guest name becomes an account-style default', () async {
      final c = await container();
      final before = c.read(profileProvider).name;
      await c.read(profileProvider.notifier).linkAccount(AuthKind.google);
      final p = c.read(profileProvider);
      expect(p.kind, AuthKind.google);
      expect(p.name, isNot(before));
      expect(p.name, isNot(matches(RegExp(r'^(Guest|Misafir)_'))));
      expect(c.read(prefsProvider).getString('authKind'), 'google');
    });

    test('a name the player picked is never overwritten', () async {
      final c = await container({'username': 'Ece', 'usernameCustom': true});
      await c.read(profileProvider.notifier).linkAccount(AuthKind.apple);
      expect(c.read(profileProvider).name, 'Ece');
      expect(c.read(profileProvider).kind, AuthKind.apple);
    });
  });

  testWidgets('the tag opens the dialog; saving updates the name, bad input blocks saving', (tester) async {
    final c = await container({'username': 'Misafir_1111'});
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Center(child: ProfileTag())),
      ),
    ));
    expect(find.text('Misafir_1111'), findsOneWidget);
    await tester.tap(find.byType(ProfileTag));
    await tester.pumpAndSettle();
    expect(find.text('Adı düzenle'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Kaydet')).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Ece');
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(c.read(profileProvider).name, 'Ece');
    expect(find.text('Ece'), findsOneWidget);
  });
}
