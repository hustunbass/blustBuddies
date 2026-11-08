import 'package:blast_buddies/core/cosmetics.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/features/game/logic/entities.dart';
import 'package:blast_buddies/features/game/render/world_painter.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/l10n/names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pick hat, face and body colour; items unlock with story stars.
class WardrobeScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  final WorldPainter _painter = WorldPainter(reducedMotion: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _pick(AppSettings s, int stars, int need, AppSettings next) {
    if (stars < need) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.starsToUnlock(need))));
      return;
    }
    ref.read(settingsProvider.notifier).update(next);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final stars = ref.watch(progressProvider).totalStars;
    final skin = Cosmetics.skin(s.hat, s.face, s.color);
    return Scaffold(
      appBar: AppBar(title: Text(l.wardrobe), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 190,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, _) => CustomPaint(painter: _PreviewPainter(_painter, skin)),
              ),
            ),
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 6),
                Text(l.yourStars(stars), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 16),
            _Section(l.wardrobeColor, [
              for (var i = 0; i < Cosmetics.colors.length; i++)
                _Swatch(
                  color: Cosmetics.colors[i].color == null ? BuddyColors.players[0] : Color(Cosmetics.colors[i].color!),
                  auto: i == 0,
                  selected: s.color == i,
                  locked: stars < Cosmetics.colors[i].stars,
                  onTap: () => _pick(s, stars, Cosmetics.colors[i].stars, s.copyWith(color: i)),
                ),
            ]),
            _Section(l.wardrobeHat, [
              for (var i = 0; i < Cosmetics.hats.length; i++)
                _ItemChip(
                  label: Names.hat(l, i),
                  need: Cosmetics.hats[i].stars,
                  stars: stars,
                  selected: s.hat == i,
                  onTap: () => _pick(s, stars, Cosmetics.hats[i].stars, s.copyWith(hat: i)),
                ),
            ]),
            _Section(l.wardrobeFace, [
              for (var i = 0; i < Cosmetics.faces.length; i++)
                _ItemChip(
                  label: Names.face(l, i),
                  need: Cosmetics.faces[i].stars,
                  stars: stars,
                  selected: s.face == i,
                  onTap: () => _pick(s, stars, Cosmetics.faces[i].stars, s.copyWith(face: i)),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.painter, this.skin);

  final WorldPainter painter;
  final Skin skin;

  @override
  void paint(Canvas canvas, Size size) {
    painter.update(1 / 60);
    painter.paintBuddyPreview(canvas, size, skin, 0);
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => true;
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: children),
        ]),
      );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.auto,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final Color color;
  final bool auto;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: locked ? Colors.white12 : color,
            border: Border.all(color: selected ? Colors.amber : Colors.white24, width: selected ? 4 : 2),
          ),
          child: locked
              ? const Icon(Icons.lock, size: 18, color: Colors.white38)
              : auto
                  ? const Icon(Icons.auto_awesome, size: 18, color: Colors.white)
                  : null,
        ),
      );
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({
    required this.label,
    required this.need,
    required this.stars,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int need;
  final int stars;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = stars < need;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: locked ? const Icon(Icons.lock, size: 16) : null,
      label: Text(locked ? '$label · $need★' : label),
    );
  }
}
