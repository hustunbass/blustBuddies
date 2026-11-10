// Screenshot harness for the store posters (not part of the shipped app).
//
//   flutter run -d <simulator> -t tool/shots/shots_main.dart
//
// The app polls /tmp/shot_cmd; scripts write a command, then take a
// screenshot with `xcrun simctl io booted screenshot`.
import 'dart:async';
import 'dart:io';

import 'package:blast_buddies/app.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/settings/stats.dart';
import 'package:blast_buddies/core/ui/toast.dart';
import 'package:blast_buddies/features/game/application/game_state.dart';
import 'package:blast_buddies/features/game/logic/bot_brain.dart';
import 'package:blast_buddies/features/online/online_room_view.dart';
import 'package:blast_buddies/features/shop/shop_sheet.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/net/online_client.dart';
import 'package:blast_buddies/net/protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  final stars = [for (var l = 1; l <= 31; l++) '$l:${l % 5 == 0 ? 2 : 3}'].join(',');
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'onboardingOffered': true,
    'onboardingDone': true,
    'sound': false,
    'music': false,
    'walletInit': true,
    'coin': 1840,
    'lives': 5,
    'unlocked': 32,
    'stars': stars,
    'best': 48210,
    'username': 'Mira',
    'usernameCustom': true,
    'hat': 3,
    'face': 2,
    'color': 4,
    'owned': [
      'hat:1', 'hat:2', 'hat:3', 'hat:4', 'face:1', 'face:2', 'face:3', 'color:1', 'color:2', 'color:3', 'color:4', //
    ],
    'stat_kills': 214,
    'stat_blocks': 2380,
    'stat_bombs': 1675,
    'stat_wins': 38,
    'stat_onlineWins': 12,
    'stat_onlineGames': 41,
    'stat_games': 96,
    'stat_levels': 31,
    'stat_bosses': 1,
    'stat_powerups': 320,
    'stat_emotes': 25,
    'stat_streak': 6,
    'dailyStreak': 6,
    'dailyBest': 9,
    'firstBuyDone': true,
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
  // Unlock everything the seeded statistics already earned, so no
  // "achievement unlocked" toasts pop up over the screenshots.
  await container.read(statsProvider.notifier).check();
  runApp(UncontrolledProviderScope(container: container, child: const _ShotApp()));
}

class _ShotApp extends StatefulWidget {
  const _ShotApp();

  @override
  State<_ShotApp> createState() => _ShotAppState();
}

class _ShotAppState extends State<_ShotApp> {
  final GoRouter _router = buildRouter();
  final ValueNotifier<Widget?> _overlay = ValueNotifier(null);
  Locale? _locale;
  String _last = '';
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(milliseconds: 300), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  BuildContext? get _navContext => _router.routerDelegate.navigatorKey.currentContext;

  void _check() {
    final f = File(const String.fromEnvironment('SHOT_CMD', defaultValue: '/tmp/shot_cmd'));
    if (!f.existsSync()) return;
    final cmd = f.readAsStringSync().trim();
    if (cmd.isEmpty || cmd == _last) return;
    _last = cmd;
    _run(cmd);
  }

  void _run(String cmd) {
    final parts = cmd.split(' ');
    final arg = parts.length > 1 ? parts[1] : '';
    _overlay.value = null;
    switch (parts.first) {
      case 'orient':
        SystemChrome.setPreferredOrientations(DeviceOrientation.values).then((_) =>
            SystemChrome.setPreferredOrientations(
                arg == 'land' ? [DeviceOrientation.landscapeLeft] : [DeviceOrientation.portraitUp]));
      case 'locale':
        setState(() => _locale = Locale(arg));
      case 'route':
        _router.go(arg);
      case 'battle':
        _router.go('/');
        _router.go('/game', extra: GameArgs.battle(humans: 1, bots: 3, seed: int.tryParse(arg) ?? 7, botLevel: BotLevel.hard));
      case 'teams':
        _router.go('/');
        _router.go('/game', extra: GameArgs.battle(humans: 1, bots: 3, teams: true, seed: int.tryParse(arg) ?? 11));
      case 'story':
        _router.go('/');
        _router.go('/game', extra: GameArgs.story(level: int.tryParse(arg) ?? 12, seed: 5));
      case 'shop':
        _router.go('/');
        Timer(const Duration(milliseconds: 600), () {
          final c = _navContext;
          if (c != null) showShopSheet(c);
        });
      case 'pop':
        final c = _navContext;
        if (c != null && Navigator.of(c).canPop()) Navigator.of(c).pop();
      case 'room':
        _router.go('/');
        final client = OnlineClient()..status = OnlineStatus.connected;
        final room = RoomDetails(
          id: 'K7QZ2',
          name: 'Friday Party',
          capacity: 7,
          teams: false,
          locked: false,
          phase: RoomPhase.lobby,
          slots: const [
            RoomMember(name: 'Mira', ready: true, you: true),
            RoomMember(name: 'Deniz', ready: true),
            RoomMember(name: 'Kaan', ready: true, boost: true),
            RoomMember(name: 'Ece', ready: false),
            RoomMember(name: 'Tolga', ready: true),
            RoomMember(name: 'Selin', ready: true),
            null,
          ],
        );
        client.room = room;
        _overlay.value = Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => OnlineRoomView(client: client, room: room)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
      locale: _locale,
      builder: (context, child) => ToastHost(
        child: ValueListenableBuilder<Widget?>(
          valueListenable: _overlay,
          builder: (_, o, _) => Stack(children: [child ?? const SizedBox.shrink(), if (o != null) Positioned.fill(child: o)]),
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
