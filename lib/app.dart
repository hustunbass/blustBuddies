import 'dart:async';
import 'dart:io' show Platform;

import 'package:blast_buddies/core/ads/ad_service.dart';
import 'package:blast_buddies/core/ads/admob_service.dart';
import 'package:blast_buddies/core/ads/ads_removed.dart';
import 'package:blast_buddies/core/audio/audio_service.dart';
import 'package:blast_buddies/core/daily/daily.dart';
import 'package:blast_buddies/core/economy/packages.dart';
import 'package:blast_buddies/core/store/purchase_service.dart';
import 'package:blast_buddies/core/store/store.dart';
import 'package:blast_buddies/core/ui/toast.dart';
import 'package:blast_buddies/features/shop/economy_widgets.dart';
import 'package:blast_buddies/features/shop/store_messages.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/features/game/application/game_state.dart';
import 'package:blast_buddies/features/game/ui/game_screen.dart';
import 'package:blast_buddies/features/menu/achievements_screen.dart';
import 'package:blast_buddies/features/menu/battle_setup_screen.dart';
import 'package:blast_buddies/features/menu/how_to_play_screen.dart';
import 'package:blast_buddies/features/menu/menu_screens.dart';
import 'package:blast_buddies/features/daily/daily_screen.dart';
import 'package:blast_buddies/features/menu/wardrobe_screen.dart';
import 'package:blast_buddies/features/online/online_screen.dart';
import 'package:blast_buddies/features/settings/controls_editor_screen.dart';
import 'package:blast_buddies/features/tutorial/tutorial_screen.dart';
import 'package:blast_buddies/features/settings/settings_screen.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
        GoRoute(path: '/daily', builder: (_, _) => const DailyScreen()),
        GoRoute(path: '/tutorial', builder: (_, _) => const TutorialScreen()),
        GoRoute(path: '/howto', builder: (_, _) => const HowToPlayScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(path: '/controls', builder: (_, _) => const ControlsEditorScreen()),
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

class _BlastBuddiesAppState extends ConsumerState<BlastBuddiesApp> with WidgetsBindingObserver {
  final GoRouter _router = buildRouter();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the background, maybe after midnight: start the new day.
    if (state == AppLifecycleState.resumed) ref.read(dailyProvider.notifier).refresh();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      theme: buildTheme(),
      routerConfig: _router,
      builder: (context, child) => _StoreToasts(child: ToastHost(child: child ?? const SizedBox.shrink())),
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
  late final ProviderContainer container;
  final ads = AdMobService(adsRemoved: () => container.read(adsRemovedProvider));
  // Real purchases are iOS-only for now (Android is planned for later).
  final PurchaseService store = !kIsWeb && Platform.isIOS ? StoreKitPurchaseService() : UnavailablePurchaseService();
  container = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(prefs),
    adServiceProvider.overrideWithValue(ads),
    purchaseServiceProvider.overrideWithValue(store),
  ]);
  // Create the store controller now so it hears purchases left over from an
  // earlier launch (e.g. the app was closed while the payment sheet was open).
  container.read(storeProvider);
  await container.read(audioProvider).preload();
  runApp(UncontrolledProviderScope(container: container, child: const BlastBuddiesApp()));
  // Consent + tracking prompts need a visible UI, so start ads after launch.
  unawaited(ads.init());
  unawaited(store.init(allProductIds).then((_) => container.read(storeProvider.notifier).refreshPrices()));
}

/// Turns store results into toasts. Purchases can finish after the shop is
/// closed (Ask to Buy, slow network), so this listens app-wide.
class _StoreToasts extends ConsumerStatefulWidget {
  const _StoreToasts({required this.child});

  final Widget child;

  @override
  ConsumerState<_StoreToasts> createState() => _StoreToastsState();
}

class _StoreToastsState extends ConsumerState<_StoreToasts> {
  StreamSubscription<StoreMessage>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(storeProvider.notifier).messages.listen((m) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      final text = storeMessageText(l, m);
      switch (m.kind) {
        case StoreMessageKind.coins:
          toastCoins(l, m.coins);
        case StoreMessageKind.adsRemoved:
        case StoreMessageKind.restored:
          showToast(text, kind: ToastKind.success);
        case StoreMessageKind.unavailable:
        case StoreMessageKind.productMissing:
        case StoreMessageKind.failed:
          showToast(text, kind: ToastKind.error);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
