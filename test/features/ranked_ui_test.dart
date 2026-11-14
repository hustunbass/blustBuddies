import 'package:blast_buddies/core/auth/auth_provider.dart';
import 'package:blast_buddies/core/auth/auth_service.dart';
import 'package:blast_buddies/core/rank/rank.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/features/online/online_screen.dart';
import 'package:blast_buddies/features/rank/league_badge.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/net/online_client.dart';
import 'package:blast_buddies/net/server/supabase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestTokens implements IdTokenSource {
  @override
  bool isSupported(AuthProvider p) => p == AuthProvider.apple;

  @override
  Future<IdCredential?> obtain(AuthProvider p) async => null;

  @override
  Future<void> signOut(AuthProvider p) async {}
}

Future<OnlineClient> pumpOnline(WidgetTester tester, {PublicRank? rank, bool searching = false}) async {
  SharedPreferences.setMockInitialValues({'walletInit': true, 'coin': 100});
  final sp = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final client = OnlineClient()
    ..status = OnlineStatus.connected
    ..rank = rank
    ..searchingRanked = searching;
  await tester.pumpWidget(ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(sp),
      onlineClientProvider.overrideWithValue(client),
      authServiceProvider.overrideWithValue(AuthService(
        api: SupabaseApi('http://127.0.0.1:1', 'sb_publishable_test'),
        store: MemorySessionStore(),
        tokens: _TestTokens(),
      )),
    ],
    child: MaterialApp(
      theme: buildTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const OnlineScreen(),
    ),
  ));
  await tester.pump();
  return client;
}

void main() {
  testWidgets('casual is the default and shows the room list with quick match', (tester) async {
    await pumpOnline(tester);
    expect(find.text('Casual'), findsOneWidget);
    expect(find.text('Ranked'), findsOneWidget);
    expect(find.text('Quick match'), findsOneWidget);
    expect(find.text('Find ranked match'), findsNothing);
  });

  testWidgets('ranked as a guest asks to sign in and hides the casual buttons', (tester) async {
    await pumpOnline(tester);
    await tester.tap(find.text('Ranked'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ranked needs an account'), findsOneWidget);
    expect(find.text('Sign in with Apple'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing, reason: 'not offered where it is not set up');
    expect(find.text('Sign out'), findsNothing);
    expect(find.text('Delete account'), findsNothing);
    expect(find.text('Quick match'), findsNothing);
    expect(find.text('Find ranked match'), findsNothing);
  });

  testWidgets('ranked when signed in shows the rank card and the search button', (tester) async {
    await pumpOnline(
      tester,
      rank: const PublicRank(league: League.silver, tp: 40, promotion: false, placing: false, games: 12),
    );
    await tester.tap(find.text('Ranked'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('Silver'), findsOneWidget);
    expect(find.text('40 TP'), findsOneWidget);
    expect(find.text('Find ranked match'), findsOneWidget);
    expect(find.text('Sign in with Apple'), findsNothing);
    expect(find.text('Sign out'), findsNothing, reason: 'sign-out and delete live in Settings now');
    expect(find.text('Delete account'), findsNothing);
  });

  testWidgets('placement games show their progress instead of a league', (tester) async {
    await pumpOnline(
      tester,
      rank: const PublicRank(league: League.bronze, tp: 0, promotion: false, placing: true, games: 2),
    );
    await tester.tap(find.text('Ranked'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('Placement 2/5'), findsOneWidget);
  });

  testWidgets('a promotion match is announced on the card', (tester) async {
    await pumpOnline(
      tester,
      rank: const PublicRank(league: League.gold, tp: 100, promotion: true, placing: false, games: 30),
    );
    await tester.tap(find.text('Ranked'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.textContaining('Promotion match'), findsOneWidget);
  });

  testWidgets('searching shows a cancel button; switching to casual cancels the search flag', (tester) async {
    final client = await pumpOnline(
      tester,
      rank: const PublicRank(league: League.gold, tp: 10, promotion: false, placing: false, games: 30),
      searching: true,
    );
    await tester.tap(find.text('Ranked'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('Searching for an opponent…'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Casual'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('Quick match'), findsOneWidget);
    expect(client.searchingRanked, isTrue, reason: 'the server answers the cancel; the flag follows it');
  });

  testWidgets('rank change view shows TP, league and a promotion note', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: Column(children: [
          RankChangeView(
            result: RankResult(
              outcome: Outcome.win,
              before: PublicRank(league: League.silver, tp: 80, promotion: false, placing: false, games: 20),
              after: PublicRank(league: League.silver, tp: 100, promotion: true, placing: false, games: 21),
              tpDelta: 20,
              promotionOffered: true,
            ),
          ),
        ]),
      ),
    ));
    expect(find.text('+20 TP'), findsOneWidget);
    expect(find.text('Silver'), findsOneWidget);
    expect(find.text('Promotion match unlocked!'), findsOneWidget);
  });
}
