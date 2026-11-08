import 'dart:math';

import 'package:blast_buddies/core/grid/map_generator.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/l10n/names.dart';
import 'package:blast_buddies/features/game/logic/level_config.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Three round buddies drawn with vector shapes (logo art).
class BuddyLogo extends StatefulWidget {
  /// Creates the logo of [height].
  const BuddyLogo({super.key, this.height = 90});

  /// Height in logical pixels.
  final double height;

  @override
  State<BuddyLogo> createState() => _BuddyLogoState();
}

class _BuddyLogoState extends State<BuddyLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            size: Size(widget.height * 3, widget.height),
            painter: _LogoPainter(_c.value),
          ),
        ),
      );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height * 0.36;
    for (var i = 0; i < 3; i++) {
      final hop = (sin((t + i * .22) * 2 * pi)).abs();
      final c = Offset(size.width * (0.2 + i * 0.3), size.height * 0.55 - hop * r * .35);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.dx, size.height * .55 + r * 1.05), width: r * (1.5 - hop * .4), height: r * .3),
        Paint()..color = const Color(0x33000000),
      );
      canvas.drawCircle(c, r, Paint()..color = BuddyColors.players[i]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(0, -r * .1), width: r * 1.3, height: r * .7),
          Radius.circular(r * .35),
        ),
        Paint()..color = const Color(0xFFECEFF1),
      );
      for (final dx in [-.25, .25]) {
        canvas.drawCircle(c.translate(r * dx, -r * .1), r * .11, Paint()..color = const Color(0xFF263238));
      }
      canvas.drawLine(
        c.translate(0, -r),
        c.translate(0, -r * 1.35),
        Paint()
          ..color = Colors.white70
          ..strokeWidth = 3,
      );
      canvas.drawCircle(c.translate(0, -r * 1.4), r * .12, Paint()..color = Colors.redAccent);
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.t != t;
}

/// Main menu.
class MenuScreen extends StatelessWidget {
  /// Creates the screen.
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF232C4D), Color(0xFF171D33)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BuddyLogo(),
                  const SizedBox(height: 8),
                  Semantics(
                    header: true,
                    child: Text(l.appTitle,
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 24),
                  _MenuButton(l.storyMode, Icons.play_arrow, () => context.push('/levels')),
                  _MenuButton(l.battleMode, Icons.groups, () => context.push('/battle')),
                  _MenuButton(l.onlineMode, Icons.public, () => context.push('/online')),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _MiniButton(l.wardrobe, Icons.checkroom, () => context.push('/wardrobe')),
                      _MiniButton(l.achievements, Icons.emoji_events, () => context.push('/achievements')),
                      _MiniButton(l.howToPlay, Icons.help_outline, () => context.push('/howto')),
                      _MiniButton(l.settings, Icons.settings, () => context.push('/settings')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: SizedBox(
          width: 80,
          child: Material(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: ExcludeSemantics(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 26, color: Colors.white70),
                    const SizedBox(height: 4),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

class _MenuButton extends StatelessWidget {
  const _MenuButton(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: FilledButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label)),
      );
}

/// Story level picker: ten worlds of ten levels with star ratings.
class LevelSelectScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const LevelSelectScreen({super.key, required this.onStart});

  /// Starts story [level].
  final void Function(BuildContext context, int level) onStart;

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen> {
  static const _maxTile = 92.0;
  static const _gap = 10.0;
  static const _headerH = 96.0;
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final unlocked = ref.read(progressProvider).unlockedLevel.clamp(1, LevelConfig.totalLevels);
    _scroll = ScrollController(initialScrollOffset: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final w = MediaQuery.sizeOf(context).width - 32;
      final cols = (w / (_maxTile + _gap)).ceil();
      final tile = (w - _gap * (cols - 1)) / cols;
      final rows = (10 / cols).ceil();
      final worldH = _headerH + rows * (tile / .82) + (rows - 1) * _gap + 24;
      final target = ((unlocked - 1) ~/ 10) * worldH;
      _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final progress = ref.watch(progressProvider);
    final worlds = LevelConfig.totalLevels ~/ 10;
    return Scaffold(
      appBar: AppBar(title: Text(l.selectLevel), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(l.starsCount(progress.totalStars),
                  style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(width: 18),
              Text(l.bestScore(progress.bestScore), style: const TextStyle(color: Colors.white70, fontSize: 15)),
            ]),
            Expanded(
              child: CustomScrollView(
                controller: _scroll,
                slivers: [
                  for (var w = 0; w < worlds; w++) ...[
                    SliverToBoxAdapter(child: _WorldHeader(world: w, progress: progress)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: _maxTile,
                          mainAxisSpacing: _gap,
                          crossAxisSpacing: _gap,
                          childAspectRatio: .82,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          childCount: 10,
                          (context, i) {
                            final level = w * 10 + i + 1;
                            return _LevelTile(
                              level: level,
                              stars: progress.stars[level] ?? 0,
                              locked: level > progress.unlockedLevel,
                              current: level == progress.unlockedLevel,
                              onTap: () => widget.onStart(context, level),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldHeader extends StatelessWidget {
  const _WorldHeader({required this.world, required this.progress});

  final int world;
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = MapTheme.of(world % MapGenerator.themeCount);
    final stars = progress.starsIn(world * 10 + 1, world * 10 + 10);
    return Container(
      height: _LevelSelectScreenState._headerH,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [theme.floorA, theme.wall]),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${l.worldN(world + 1)} · ${Names.map(l, world)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(Names.story(l, world),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.25)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star, color: Colors.amber, size: 18),
          Text(' $stars/30', style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.stars,
    required this.locked,
    required this.current,
    required this.onTap,
  });

  final int level;
  final int stars;
  final bool locked;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final boss = LevelConfig.isBossLevel(level);
    final color = boss ? const Color(0xFFB71C1C) : Theme.of(context).colorScheme.primaryContainer;
    return Semantics(
      button: true,
      enabled: !locked,
      label: locked
          ? '${l.levelN(level)}, ${l.levelLocked}'
          : '${l.levelN(level)}, ${l.starsCount(stars)}',
      child: Material(
        color: locked ? Colors.white10 : color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: locked ? null : onTap,
          child: Container(
            decoration: current
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber, width: 3),
                  )
                : null,
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (locked)
                    const Icon(Icons.lock, size: 18, color: Colors.white38)
                  else if (boss)
                    const Icon(Icons.local_fire_department, size: 18, color: Colors.amber)
                  else
                    const SizedBox(height: 18),
                  Text('$level',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800, color: locked ? Colors.white38 : Colors.white)),
                  const SizedBox(height: 2),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < 3; i++)
                      Icon(i < stars ? Icons.star : Icons.star_border,
                          size: 14, color: i < stars ? Colors.amber : Colors.white30),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
