import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/features/game/logic/level_config.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Three round buddies drawn with vector shapes (logo art).
class BuddyLogo extends StatelessWidget {
  /// Creates the logo of [height].
  const BuddyLogo({super.key, this.height = 90});

  /// Height in logical pixels.
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(size: Size(height * 3, height), painter: _LogoPainter()),
      );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height * 0.36;
    for (var i = 0; i < 3; i++) {
      final c = Offset(size.width * (0.2 + i * 0.3), size.height * 0.55);
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
  bool shouldRepaint(_LogoPainter old) => false;
}

/// Main menu.
class MenuScreen extends StatelessWidget {
  /// Creates the screen.
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
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
                _MenuButton(l.howToPlay, Icons.help_outline, () => context.push('/howto')),
                _MenuButton(l.settings, Icons.settings, () => context.push('/settings')),
              ],
            ),
          ),
        ),
      ),
    );
  }
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

/// Story level picker.
class LevelSelectScreen extends ConsumerWidget {
  /// Creates the screen.
  const LevelSelectScreen({super.key, required this.onStart});

  /// Starts story [level].
  final void Function(BuildContext context, int level) onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final progress = ref.watch(progressProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.selectLevel), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Column(
          children: [
            Text(l.bestScore(progress.bestScore), style: const TextStyle(color: Colors.amber, fontSize: 16)),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 120,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: LevelConfig.totalLevels,
                itemBuilder: (context, i) {
                  final level = i + 1;
                  final locked = level > progress.unlockedLevel;
                  return Semantics(
                    button: true,
                    enabled: !locked,
                    label: locked ? '${l.levelN(level)}, ${l.levelLocked}' : l.levelN(level),
                    child: FilledButton(
                      onPressed: locked ? null : () => onStart(context, level),
                      style: FilledButton.styleFrom(minimumSize: Size.zero),
                      child: ExcludeSemantics(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(locked ? Icons.lock : Icons.star, size: 22),
                            Text('$level', style: const TextStyle(fontSize: 24)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
