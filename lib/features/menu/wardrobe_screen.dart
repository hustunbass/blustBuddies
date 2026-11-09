import 'package:blast_buddies/core/cosmetics.dart';
import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/emotes.dart';
import 'package:blast_buddies/features/shop/economy_widgets.dart';
import 'package:blast_buddies/features/shop/purchase.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/features/game/logic/entities.dart';
import 'package:blast_buddies/features/game/render/world_painter.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/l10n/names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pick hat, face and body colour; items are bought with coins.
class WardrobeScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  final WorldPainter _painter = WorldPainter(reducedMotion: true);

  /// Draws the little previews in the grids (never ticked: a still pose).
  final WorldPainter _tilePainter = WorldPainter(reducedMotion: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _pick(AppSettings next, String key, int price) async {
    if (!await purchaseWithCoins(context, ref, key, price) || !mounted) return;
    await ref.read(settingsProvider.notifier).update(next);
  }

  bool _owned(WalletData w, String kind, int i, CosmeticItem item) => item.price == 0 || w.has('$kind:$i');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final wallet = ref.watch(walletProvider);
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
                const CoinChip(),
              ]),
            ),
            const SizedBox(height: 16),
            _Section(l.wardrobeColor, [
              for (final i in Cosmetics.byPrice(Cosmetics.colors))
                _Swatch(
                  color: Cosmetics.colors[i].color == null ? BuddyColors.players[0] : Color(Cosmetics.colors[i].color!),
                  auto: i == 0,
                  selected: s.color == i,
                  locked: !_owned(wallet, 'color', i, Cosmetics.colors[i]),
                  onTap: () => _pick(s.copyWith(color: i), 'color:$i', Cosmetics.colors[i].price),
                ),
            ]),
            _Section(l.wardrobeHat, [
              for (final i in Cosmetics.byPrice(Cosmetics.hats))
                _CosmeticTile(
                  label: Names.hat(l, i),
                  skin: Cosmetics.skin(i, s.face, s.color),
                  painter: _tilePainter,
                  price: _owned(wallet, 'hat', i, Cosmetics.hats[i]) ? 0 : Cosmetics.hats[i].price,
                  selected: s.hat == i,
                  onTap: () => _pick(s.copyWith(hat: i), 'hat:$i', Cosmetics.hats[i].price),
                ),
            ]),
            _Section(l.wardrobeFace, [
              for (final i in Cosmetics.byPrice(Cosmetics.faces))
                _CosmeticTile(
                  label: Names.face(l, i),
                  skin: Cosmetics.skin(s.hat, i, s.color),
                  painter: _tilePainter,
                  price: _owned(wallet, 'face', i, Cosmetics.faces[i]) ? 0 : Cosmetics.faces[i].price,
                  selected: s.face == i,
                  onTap: () => _pick(s.copyWith(face: i), 'face:$i', Cosmetics.faces[i].price),
                ),
            ]),
            _Section(l.wardrobeEmotes, [
              for (var i = 0; i < Emotes.count; i++)
                if (Emotes.isFree(i) || wallet.has(Emotes.key(i)))
                  Chip(label: Text(Emotes.emoji[i], style: const TextStyle(fontSize: 18)))
                else
                  ActionChip(
                    avatar: const Icon(Icons.lock, size: 16),
                    label: _PriceLabel(Emotes.emoji[i], Emotes.price, fontSize: 18),
                    onPressed: () => purchaseWithCoins(context, ref, Emotes.key(i), Emotes.price),
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

/// A hat or face shown on the buddy, with its name and price.
class _CosmeticTile extends StatelessWidget {
  const _CosmeticTile({
    required this.label,
    required this.skin,
    required this.painter,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Skin skin;
  final WorldPainter painter;

  /// 0 = owned (or free).
  final int price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = price > 0;
    return Semantics(
      button: true,
      selected: selected,
      label: locked ? '$label, $price' : label,
      child: Material(
        color: BuddyColors.panel,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 84,
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? BuddyColors.gold : Colors.white12, width: selected ? 2.5 : 1),
            ),
            child: ExcludeSemantics(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  height: 64,
                  width: 64,
                  child: Stack(alignment: Alignment.center, children: [
                    CustomPaint(size: const Size(64, 64), painter: _TilePainter(painter, skin, dimmed: locked)),
                    if (locked) const Icon(Icons.lock_rounded, size: 18, color: Colors.white70),
                  ]),
                ),
                const SizedBox(height: 2),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
                const SizedBox(height: 3),
                SizedBox(
                  height: 16,
                  child: locked
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          const CoinIcon(size: 13),
                          const SizedBox(width: 3),
                          Text('$price',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: BuddyColors.gold)),
                        ])
                      : Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                          size: 14, color: selected ? BuddyColors.gold : Colors.white24),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _TilePainter extends CustomPainter {
  _TilePainter(this.painter, this.skin, {required this.dimmed});

  final WorldPainter painter;
  final Skin skin;
  final bool dimmed;

  @override
  void paint(Canvas canvas, Size size) {
    if (dimmed) canvas.saveLayer(Offset.zero & size, Paint()..color = const Color(0x8CFFFFFF));
    painter.paintBuddyPreview(canvas, size, skin, 0);
    if (dimmed) canvas.restore();
  }

  @override
  bool shouldRepaint(_TilePainter old) => old.skin != skin || old.dimmed != dimmed;
}

/// "Name · 120 [coin]" with the real coin picture.
class _PriceLabel extends StatelessWidget {
  const _PriceLabel(this.name, this.price, {this.fontSize});

  final String name;
  final int price;
  final double? fontSize;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$name · $price', style: TextStyle(fontSize: fontSize)),
        const SizedBox(width: 4),
        const CoinIcon(size: 16),
      ]);
}
