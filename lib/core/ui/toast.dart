import 'package:blast_buddies/core/theme.dart';
import 'package:flutter/material.dart';

/// Look of a toast.
enum ToastKind {
  /// Neutral information.
  info(Icons.info_outline_rounded, Color(0xFF64B5F6)),

  /// Something worked.
  success(Icons.check_circle_rounded, Color(0xFF66BB6A)),

  /// Something went wrong.
  error(Icons.error_outline_rounded, Color(0xFFEF5350)),

  /// A trophy was won.
  achievement(Icons.emoji_events_rounded, BuddyColors.gold),

  /// Coins were paid out.
  coins(Icons.monetization_on_rounded, BuddyColors.gold);

  const ToastKind(this.icon, this.color);

  /// Default icon.
  final IconData icon;

  /// Accent colour.
  final Color color;
}

/// One message waiting to be shown.
class ToastMessage {
  /// Creates a message.
  const ToastMessage(
    this.text, {
    this.title,
    this.kind = ToastKind.info,
    this.actionLabel,
    this.onAction,
    this.leading,
  });

  /// Main text.
  final String text;

  /// Optional small line above the text.
  final String? title;

  /// Look.
  final ToastKind kind;

  /// Label of the optional button.
  final String? actionLabel;

  /// Called when the button is tapped.
  final VoidCallback? onAction;

  /// Replaces the kind's icon (e.g. the coin).
  final Widget? leading;

  /// How long it stays fully visible.
  Duration get hold => kind == ToastKind.achievement || actionLabel != null
      ? const Duration(milliseconds: 3600)
      : const Duration(milliseconds: 2400);
}

/// Queue shared by the whole app, so a toast can be raised from anywhere (also
/// from code that has no BuildContext, e.g. a purchase finishing later).
class ToastController extends ChangeNotifier {
  final List<ToastMessage> _queue = [];
  ToastMessage? _current;

  /// Message on screen, if any.
  ToastMessage? get current => _current;

  /// Number of messages that are waiting.
  int get waiting => _queue.length;

  /// Queues [m] (an identical message already waiting is dropped).
  void show(ToastMessage m) {
    final dupe = (_current?.text == m.text && _current?.kind == m.kind) ||
        _queue.any((q) => q.text == m.text && q.kind == m.kind);
    if (dupe) return;
    _queue.add(m);
    if (_current == null) _next();
  }

  /// Called by the host when the current message is gone.
  void done() => _next();

  /// Drops everything.
  void clear() {
    _queue.clear();
    _current = null;
    notifyListeners();
  }

  void _next() {
    _current = _queue.isEmpty ? null : _queue.removeAt(0);
    notifyListeners();
  }
}

/// The app-wide toast queue.
final ToastController toasts = ToastController();

/// Shows a toast: a rounded card that slides in from the top, stays a moment
/// and slides out again. Use instead of SnackBars.
void showToast(
  String text, {
  String? title,
  ToastKind kind = ToastKind.info,
  String? actionLabel,
  VoidCallback? onAction,
  Widget? leading,
}) =>
    toasts.show(ToastMessage(text, title: title, kind: kind, actionLabel: actionLabel, onAction: onAction, leading: leading));

/// Draws the toasts above [child]. Place it once, in `MaterialApp.builder`.
class ToastHost extends StatefulWidget {
  /// Creates the host.
  const ToastHost({super.key, required this.child, ToastController? controller}) : _controller = controller;

  /// The app.
  final Widget child;

  final ToastController? _controller;

  @override
  State<ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<ToastHost> with SingleTickerProviderStateMixin {
  static const _slide = Duration(milliseconds: 320);

  // "Reduce motion" must not shorten how long a message stays up, so this
  // controller ignores that setting (the slide is skipped instead, see build).
  late final AnimationController _anim = AnimationController(vsync: this, animationBehavior: AnimationBehavior.preserve);
  ToastController get _ctrl => widget._controller ?? toasts;
  ToastMessage? _shown;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChange);
    _anim.addStatusListener((s) {
      if (s == AnimationStatus.completed) _dismiss();
    });
    _onChange();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChange);
    _anim.dispose();
    super.dispose();
  }

  void _onChange() {
    final next = _ctrl.current;
    if (identical(next, _shown)) return;
    _shown = next;
    if (next == null) {
      _anim.stop();
    } else {
      // [slide in] [hold] [slide out] on a single controller, so no timers.
      _anim.duration = _slide * 2 + next.hold;
      _anim.forward(from: 0);
    }
    if (mounted) setState(() {});
  }

  void _dismiss() {
    if (_shown == null) return;
    _shown = null;
    _ctrl.done(); // may show the next one (see _onChange)
    // Nothing queued: remove the card, or its invisible shell would keep
    // swallowing taps at the top of the screen.
    if (mounted) setState(() {});
  }

  /// 0 hidden .. 1 fully shown, with the hold in the middle.
  double _visible(double t, ToastMessage m) {
    final total = (_slide * 2 + m.hold).inMilliseconds.toDouble();
    final ms = t * total;
    final inMs = _slide.inMilliseconds.toDouble();
    if (ms < inMs) return Curves.easeOutCubic.transform(ms / inMs);
    if (ms > total - inMs) return Curves.easeInCubic.transform((total - ms) / inMs);
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final m = _shown;
    return Stack(children: [
      widget.child,
      if (m != null)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            minimum: const EdgeInsets.only(top: 6),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final v = _visible(_anim.value, m);
                final still = MediaQuery.disableAnimationsOf(context);
                return Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, still ? 0 : -24 * (1 - v)),
                    child: Center(child: _ToastCard(message: m, onClose: _dismiss)),
                  ),
                );
              },
            ),
          ),
        ),
    ]);
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.message, required this.onClose});

  final ToastMessage message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final color = m.kind.color;
    return Semantics(
      liveRegion: true,
      label: [if (m.title != null) m.title!, m.text].join('. '),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onClose,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            decoration: BoxDecoration(
              color: BuddyColors.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: .55), width: 1.5),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 6))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: .18), shape: BoxShape.circle),
                child: m.leading ?? Icon(m.kind.icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (m.title != null)
                    Text(
                      m.title!.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: color),
                    ),
                  Text(
                    m.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, height: 1.25),
                  ),
                ]),
              ),
              if (m.actionLabel != null) ...[
                const SizedBox(width: 10),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () {
                    m.onAction?.call();
                    onClose();
                  },
                  child: Text(m.actionLabel!),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
