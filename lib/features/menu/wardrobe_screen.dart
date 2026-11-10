import 'package:blast_buddies/core/cosmetics.dart';
import 'package:blast_buddies/core/economy/price_format.dart';
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

  Future<void> _pick(AppSettings next, String key, int price, {Widget? preview}) async {
    if (!await purchaseWithCoins(context, ref, key, price, preview: preview) || !mounted) return;
    await ref.read(settingsProvider.notifier).update(next);
  }

  /// What the unlock dialog shows: the buddy wearing the item, so the player
  /// sees exactly what they are buying.
  Widget _buddyPreview(Skin skin) => SizedBox(
        width: 88,
        height: 88,
        child: CustomPaint(painter: _TilePainter(_tilePainter, skin, dimmed: false)),
      );

  Widget _colorPreview(Color color) => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white54, width: 3),
        ),
      );

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
                _ColorTile(
                  color: Cosmetics.colors[i].color == null ? BuddyColors.players[0] : Color(Cosmetics.colors[i].color!),
                  auto: i == 0,
                  selected: s.color == i,
                  price: _owned(wallet, 'color', i, Cosmetics.colors[i]) ? 0 : Cosmetics.colors[i].price,
                  onTap: () => _pick(
                    s.copyWith(color: i),
                    'color:$i',
                    Cosmetics.colors[i].price,
                    preview: _colorPreview(
                        Cosmetics.colors[i].color == null ? BuddyColors.players[0] : Color(Cosmetics.colors[i].color!)),
                  ),
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
                  onTap: () => _pick(s.copyWith(hat: i), 'hat:$i', Cosmetics.hats[i].price,
                      preview: _buddyPreview(Cosmetics.skin(i, s.face, s.color))),
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
                  onTap: () => _pick(s.copyWith(face: i), 'face:$i', Cosmetics.faces[i].price,
                      preview: _buddyPreview(Cosmetics.skin(s.hat, i, s.color))),
                ),
            ]),
            _Section(l.wardrobeEmotes, [
              // Free emotes first, then the ones to save up for.
              for (final i in [
                ...List.generate(Emotes.count, (i) => i).where(Emotes.isFree),
                ...List.generate(Emotes.count, (i) => i).where((i) => !Emotes.isFree(i)),
              ])
                _EmoteTile(
                  emoji: Emotes.emoji[i],
                  price: Emotes.isFree(i) || wallet.has(Emotes.key(i)) ? 0 : Emotes.price,
                  onTap: () => purchaseWithCoins(
                    context,
                    ref,
                    Emotes.key(i),
                    Emotes.price,
                    preview: Text(Emotes.emoji[i], style: const TextStyle(fontSize: 56)),
                  ),
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

/// Every wardrobe list is a grid of exactly four columns, whatever the phone.
const int _wardrobeColumns = 4;
const double _wardrobeGap = 10;

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
          LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - _wardrobeGap * (_wardrobeColumns - 1)) / _wardrobeColumns;
            return Wrap(
              spacing: _wardrobeGap,
              runSpacing: _wardrobeGap,
              children: [for (final child in children) SizedBox(width: w, child: child)],
            );
          }),
        ]),
      );
}

/// Shared look of a wardrobe tile (panel, border, tap area).
class _TileFrame extends StatelessWidget {
  const _TileFrame({required this.selected, required this.onTap, required this.semanticLabel, required this.child});

  final bool selected;
  final VoidCallback onTap;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: semanticLabel,
        child: Material(
          color: BuddyColors.panel,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? BuddyColors.gold : Colors.white12, width: selected ? 2.5 : 1),
              ),
              child: ExcludeSemantics(child: child),
            ),
          ),
        ),
      );
}

/// Price line of a tile: coin and amount while locked, a tick otherwise.
class _TileFooter extends StatelessWidget {
  const _TileFooter({required this.price, required this.selected, this.showCheck = true});

  final int price;
  final bool selected;
  final bool showCheck;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 16,
        child: price > 0
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                const CoinIcon(size: 13),
                const SizedBox(width: 3),
                Text(coinShort(price),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: BuddyColors.gold)),
              ])
            : showCheck
                ? Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 14, color: selected ? BuddyColors.gold : Colors.white24)
                : null,
      );
}

/// A body colour: the real colour stays visible while locked (dimmed, with a
/// lock) so the player can see what they would unlock.
class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.color,
    required this.auto,
    required this.selected,
    required this.price,
    required this.onTap,
  });

  final Color color;
  final bool auto;
  final bool selected;
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = price > 0;
    return _TileFrame(
      selected: selected,
      onTap: onTap,
      semanticLabel: locked ? '$price' : '',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        LayoutBuilder(builder: (context, c) {
          final d = (c.maxWidth - 16).clamp(34.0, 56.0);
          return SizedBox(
            height: 64,
            child: Center(
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: locked ? color.withValues(alpha: .55) : color,
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: auto && !locked ? const Icon(Icons.auto_awesome, size: 20, color: Colors.white) : null,
                ),
                if (locked)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.lock_rounded, size: 14, color: Colors.white70),
                  ),
              ]),
            ),
          );
        }),
        const SizedBox(height: 2),
        _TileFooter(price: price, selected: selected),
      ]),
    );
  }
}

/// An emote: free ones can be used right away, the others show their price.
class _EmoteTile extends StatelessWidget {
  const _EmoteTile({required this.emoji, required this.price, required this.onTap});

  final String emoji;
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = price > 0;
    return _TileFrame(
      selected: false,
      onTap: onTap,
      semanticLabel: locked ? '$emoji, $price' : emoji,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          height: 64,
          child: Center(
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              Opacity(opacity: locked ? .5 : 1, child: Text(emoji, style: const TextStyle(fontSize: 34))),
              if (locked) const Positioned(right: -10, bottom: -4, child: Icon(Icons.lock_rounded, size: 16, color: Colors.white70)),
            ]),
          ),
        ),
        const SizedBox(height: 2),
        _TileFooter(price: price, selected: false, showCheck: false),
      ]),
    );
  }
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
    return _TileFrame(
      selected: selected,
      onTap: onTap,
      semanticLabel: locked ? '$label, $price' : label,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        LayoutBuilder(builder: (context, c) {
          final d = (c.maxWidth - 8).clamp(40.0, 64.0);
          return SizedBox(
            height: 64,
            width: d,
            child: Stack(alignment: Alignment.center, children: [
              CustomPaint(size: Size(d, 64), painter: _TilePainter(painter, skin, dimmed: locked)),
              if (locked) const Icon(Icons.lock_rounded, size: 18, color: Colors.white70),
            ]),
          );
        }),
        const SizedBox(height: 2),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
        const SizedBox(height: 3),
        _TileFooter(price: price, selected: selected),
      ]),
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
