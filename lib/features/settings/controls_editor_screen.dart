import 'package:blast_buddies/core/settings/control_layout.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/features/game/ui/controls.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets the player drag the joystick and the bomb button anywhere they like.
///
/// The screen copies the real game layout (header, arena, control area), so
/// what is placed here lands in the same spot during play. Portrait and
/// landscape are saved separately.
class ControlsEditorScreen extends ConsumerWidget {
  /// Creates the screen.
  const ControlsEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final portrait = c.maxHeight > c.maxWidth;
          final header = Container(
            height: 60,
            color: Colors.black26,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(l.controlsTitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              TextButton.icon(
                onPressed: () {
                  final s = ref.read(settingsProvider);
                  notifier.update(portrait
                      ? s.copyWith(controlsPortrait: const ControlLayout())
                      : s.copyWith(controlsLandscape: const ControlLayout()));
                },
                icon: const Icon(Icons.restart_alt),
                label: Text(l.controlsReset),
              ),
              FilledButton(onPressed: () => Navigator.of(context).maybePop(), child: Text(l.controlsDone)),
              const SizedBox(width: 8),
            ]),
          );
          const arena = _MockArena();
          if (portrait) {
            return Column(children: [
              header,
              const Flexible(child: AspectRatio(aspectRatio: 13 / 11, child: arena)),
              const Expanded(child: _EditArea(landscape: false)),
            ]);
          }
          return Column(children: [
            header,
            const Expanded(
              child: Stack(children: [
                Positioned.fill(child: arena),
                Positioned.fill(child: _EditArea(landscape: true)),
              ]),
            ),
          ]);
        }),
      ),
    );
  }
}

/// A stand-in for the game view so the control area has the same size.
class _MockArena extends StatelessWidget {
  const _MockArena();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(painter: _ArenaPainter(), child: const SizedBox.expand()),
      );
}

class _ArenaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cols = 13, rows = 11;
    final cell = Size(size.width / cols, size.height / rows);
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final wall = x == 0 || y == 0 || x == cols - 1 || y == rows - 1 || (x.isEven && y.isEven);
        canvas.drawRect(
          Rect.fromLTWH(x * cell.width, y * cell.height, cell.width, cell.height),
          Paint()..color = wall ? BuddyColors.wall : ((x + y).isEven ? BuddyColors.floorA : BuddyColors.floorB),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ArenaPainter old) => false;
}

class _EditArea extends ConsumerStatefulWidget {
  const _EditArea({required this.landscape});

  final bool landscape;

  @override
  ConsumerState<_EditArea> createState() => _EditAreaState();
}

class _EditAreaState extends ConsumerState<_EditArea> {
  /// Layout while a finger is dragging; saved when it lets go.
  ControlLayout? _drag;

  void _save(ControlLayout layout) {
    final s = ref.read(settingsProvider);
    ref.read(settingsProvider.notifier).update(
          widget.landscape ? s.copyWith(controlsLandscape: layout) : s.copyWith(controlsPortrait: layout),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final saved = widget.landscape ? s.controlsLandscape : s.controlsPortrait;
    final layout = _drag ?? saved;
    final stickSize = scaled(140, s.controlScale);
    final bombSize = scaled(96, s.controlScale);
    return LayoutBuilder(builder: (context, c) {
      final area = Size(c.maxWidth, c.maxHeight);
      final stick = ControlGeometry.stick(area, stickSize, leftHanded: s.leftHanded, layout: layout);
      final bomb = ControlGeometry.bomb(area, bombSize, leftHanded: s.leftHanded, layout: layout);

      Widget draggable({
        required Rect rect,
        required String label,
        required Widget child,
        required ControlLayout Function(Rect moved) onMove,
      }) =>
          Positioned.fromRect(
            rect: rect,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) => setState(() => _drag = onMove(rect.shift(d.delta))),
              onPanEnd: (_) {
                final done = _drag;
                setState(() => _drag = null);
                if (done != null) _save(done);
              },
              child: Semantics(
                label: '$label – ${l.controlsHint}',
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: IgnorePointer(child: child),
                ),
              ),
            ),
          );

      return Stack(children: [
        Positioned(
          top: 8,
          left: 12,
          right: 12,
          child: Card(
            color: Colors.black54,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(l.controlsHint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                Row(children: [
                  const Icon(Icons.zoom_in, size: 20),
                  Expanded(
                    child: Slider(
                      min: 0.7,
                      max: 1.4,
                      divisions: 7,
                      value: s.controlScale,
                      label: '${(s.controlScale * 100).round()}%',
                      onChanged: (v) => ref.read(settingsProvider.notifier).update(s.copyWith(controlScale: v)),
                    ),
                  ),
                  Text(l.leftHanded, style: const TextStyle(fontSize: 13)),
                  Switch(
                    value: s.leftHanded,
                    onChanged: (v) => ref.read(settingsProvider.notifier).update(s.copyWith(
                          leftHanded: v,
                          // Moving to the other hand mirrors where things were put.
                          controlsPortrait: s.controlsPortrait.mirrored(),
                          controlsLandscape: s.controlsLandscape.mirrored(),
                        )),
                  ),
                ]),
              ]),
            ),
          ),
        ),
        draggable(
          rect: stick,
          label: l.joystick,
          child: VirtualJoystick(size: stickSize, onChanged: (_) {}),
          onMove: (r) => ControlGeometry.withStickAt(layout, area, stickSize, r, leftHanded: s.leftHanded),
        ),
        draggable(
          rect: bomb,
          label: l.bombButton,
          child: BombButton(size: bombSize, onPressed: () {}),
          onMove: (r) => ControlGeometry.withBombAt(layout, area, bombSize, r, leftHanded: s.leftHanded),
        ),
      ]);
    });
  }
}
