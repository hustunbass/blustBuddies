import 'dart:async';
import 'dart:math';

import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/core/ui/toast.dart';
import 'package:blast_buddies/features/online/boost_button.dart';
import 'package:blast_buddies/features/online/online_screen.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/net/online_client.dart';
import 'package:blast_buddies/net/protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Room lobby: slots, ready toggles and the start countdown.
class OnlineRoomView extends StatelessWidget {
  /// Creates the view for [room].
  const OnlineRoomView({super.key, required this.client, required this.room});

  /// Connection.
  final OnlineClient client;

  /// Current room state.
  final RoomDetails room;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final me = room.mySlot >= 0 ? room.slots[room.mySlot] : null;
    final ready = me?.ready ?? false;
    final full = room.filled == room.capacity;
    final Widget status = switch (room.phase) {
      RoomPhase.countdown => _Countdown(key: ValueKey(room.countdown), seconds: room.countdown ?? 3),
      _ when !full => Text(l.waitingForPlayers(room.filled, room.capacity)),
      _ => Text(l.waitingForReady),
    };
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) client.leaveRoom();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            tooltip: l.leaveRoom,
            onPressed: client.leaveRoom,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            if (room.locked) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.lock, size: 18)),
            Flexible(child: Text(room.name, overflow: TextOverflow.ellipsis)),
          ]),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(roomModeLabel(l, room.capacity, room.teams),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.amber)),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: room.id));
                          showToast(l.codeCopied, kind: ToastKind.success);
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: Text(l.roomCode(room.id),
                            style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (var i = 0; i < room.capacity; i++) _SlotTile(slot: i, room: room),
                    const SizedBox(height: 16),
                    DefaultTextStyle.merge(
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.white70),
                      child: Semantics(liveRegion: true, child: status),
                    ),
                    const SizedBox(height: 16),
                    if (room.phase != RoomPhase.playing) ...[
                      BoostButton(client: client),
                      const SizedBox(height: 10),
                    ],
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: ready ? Colors.blueGrey : Colors.green,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: me == null ? null : () => client.setReady(!ready),
                      icon: Icon(ready ? Icons.close : Icons.check),
                      label: Text(ready ? l.cancelReady : l.imReady, style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: client.leaveRoom,
                      icon: const Icon(Icons.logout),
                      label: Text(l.leaveRoom),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.room});

  final int slot;
  final RoomDetails room;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = room.slots[slot];
    final team = room.teams ? slot % 2 : null;
    return Card(
      shape: team == null
          ? null
          : RoundedRectangleBorder(
              side: BorderSide(color: BuddyColors.teams[team], width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: m == null ? Colors.white12 : BuddyColors.players[slot],
          child: Text(l.playerN(slot + 1),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        title: Text(
          m == null ? l.emptySlot : (m.you ? l.youTag(m.name) : m.name),
          style: TextStyle(
            fontWeight: m?.you ?? false ? FontWeight.bold : FontWeight.normal,
            color: m == null ? Colors.white38 : null,
          ),
        ),
        subtitle: team == null && !(m?.boost ?? false)
            ? null
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (team != null) Text(l.teamN(team + 1), style: TextStyle(color: BuddyColors.teams[team])),
                if (m?.boost ?? false)
                  Text('⚡ ${l.boostBadge(boostedStartBombs)}',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w700)),
              ]),
        trailing: m == null
            ? null
            : Chip(
                avatar: Icon(m.ready ? Icons.check_circle : Icons.hourglass_empty,
                    color: m.ready ? Colors.greenAccent : Colors.white54, size: 18),
                label: Text(m.ready ? l.readyLabel : l.notReady),
              ),
      ),
    );
  }
}

/// Counts down locally from the server-provided [seconds].
class _Countdown extends StatefulWidget {
  const _Countdown({super.key, required this.seconds});

  final double seconds;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  final Stopwatch _clock = Stopwatch()..start();
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = max(0, widget.seconds - _clock.elapsedMilliseconds / 1000);
    final n = max(1, left.ceil());
    return Text(
      AppLocalizations.of(context).startsIn(n),
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.greenAccent),
    );
  }
}
