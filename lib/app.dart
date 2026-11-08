import 'package:blast_buddies/core/audio/audio_service.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/features/game/application/game_state.dart';
import 'package:blast_buddies/features/game/ui/game_screen.dart';
import 'package:blast_buddies/features/menu/achievements_screen.dart';
import 'package:blast_buddies/features/menu/battle_setup_screen.dart';
import 'package:blast_buddies/features/menu/how_to_play_screen.dart';
import 'package:blast_buddies/features/menu/menu_screens.dart';
import 'package:blast_buddies/features/menu/wardrobe_screen.dart';
import 'package:blast_buddies/features/online/online_screen.dart';
import 'package:blast_buddies/features/settings/settings_screen.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds the app router.
GoRouter buildRouter() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const MenuScreen()),
        GoRoute(
          path: '/levels',
          builder: (_, _) => LevelSelectScreen(
            onStart: (context, level) =>
                context.pushReplacement('/game', extra: GameArgs.story(level: level)),
          ),
        ),
        GoRoute(path: '/battle', builder: (_, _) => const BattleSetupScreen()),
        GoRoute(path: '/online', builder: (_, _) => const OnlineScreen()),
        GoRoute(path: '/wardrobe', builder: (_, _) => const WardrobeScreen()),
        GoRoute(path: '/achievements', builder: (_, _) => const AchievementsScreen()),
        GoRoute(path: '/howto', builder: (_, _) => const HowToPlayScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: '/game',
          redirect: (_, state) => state.extra is GameArgs ? null : '/',
          builder: (_, state) => GameScreen(
            key: ValueKey(state.extra),
            args: state.extra! as GameArgs,
          ),
        ),
      ],
    );

/// Root widget.
class BlastBuddiesApp extends ConsumerStatefulWidget {
  /// Creates the app.
  const BlastBuddiesApp({super.key});

  @override
  ConsumerState<BlastBuddiesApp> createState() => _BlastBuddiesAppState();
}

class _BlastBuddiesAppState extends ConsumerState<BlastBuddiesApp> {
  final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      theme: buildTheme(),
      routerConfig: _router,
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

/// Initialises services and runs the app.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
  await container.read(audioProvider).preload();
  runApp(UncontrolledProviderScope(container: container, child: const BlastBuddiesApp()));
}
