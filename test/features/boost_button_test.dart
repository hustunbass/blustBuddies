import 'package:blast_buddies/core/ads/ad_service.dart';
import 'package:blast_buddies/core/ui/toast.dart';
import 'package:blast_buddies/features/online/boost_button.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/net/online_client.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoAd extends DebugAdService {
  @override
  Future<bool> showRewarded(AdPlacement placement) async => false;
}

Future<void> pumpButton(WidgetTester tester, OnlineClient client, AdService ads) async {
  toasts.clear();
  addTearDown(toasts.clear);
  SharedPreferences.setMockInitialValues({});
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [prefsProvider.overrideWithValue(sp), adServiceProvider.overrideWithValue(ads)],
    child: MaterialApp(
      builder: (context, child) => ToastHost(child: child!),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListenableBuilder(listenable: client, builder: (_, _) => BoostButton(client: client)),
      ),
    ),
  ));
}

void main() {
  testWidgets('watching the ad enables the 2-bomb start and shows the badge', (tester) async {
    final client = OnlineClient();
    await pumpButton(tester, client, DebugAdService());
    expect(find.text('Watch ad: start with 2 bombs'), findsOneWidget);
    await tester.tap(find.text('Watch ad: start with 2 bombs'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(client.boosted, isTrue);
    expect(find.text('Your next match starts with 2 bombs'), findsOneWidget);
    expect(find.text('Watch ad: start with 2 bombs'), findsNothing);
  });

  testWidgets('no ad available: no advantage is granted', (tester) async {
    final client = OnlineClient();
    await pumpButton(tester, client, _NoAd());
    await tester.tap(find.text('Watch ad: start with 2 bombs'));
    await tester.pump();
    await tester.pump();
    expect(client.boosted, isFalse);
    expect(find.text('No ad available right now. Try again in a moment.'), findsOneWidget);
  });
}
