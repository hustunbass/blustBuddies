import 'dart:async';

import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/features/online/online_game_view.dart';
import 'package:blast_buddies/features/online/online_room_view.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/net/online_client.dart';
import 'package:blast_buddies/net/protocol.dart';
import 'package:blast_buddies/net/server_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide online client.
final onlineClientProvider = Provider<OnlineClient>((ref) {
  final c = OnlineClient();
  ref.onDispose(c.dispose);
  return c;
});

/// Human readable room mode, e.g. "2 vs 2".
String roomModeLabel(AppLocalizations l, int capacity, bool teams) =>
    teams ? l.modeTeams : (capacity == 2 ? l.modeDuel : l.modeFfa(capacity));

/// Text for a rejected request.
String errorText(AppLocalizations l, ErrorCode c) => switch (c) {
      ErrorCode.wrongPassword => l.errWrongPassword,
      ErrorCode.roomFull => l.errRoomFull,
      ErrorCode.roomNotFound => l.errRoomNotFound,
      ErrorCode.inProgress => l.errInProgress,
      ErrorCode.tooManyAttempts => l.errTooManyAttempts,
      ErrorCode.serverFull => l.errServerFull,
      ErrorCode.versionMismatch => l.errVersion,
      ErrorCode.badRequest => l.errGeneric,
    };

/// Online battle: connect, browse/create rooms, ready up and play.
/// The visible part follows the [OnlineClient] state.
class OnlineScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const OnlineScreen({super.key});

  @override
  ConsumerState<OnlineScreen> createState() => _OnlineScreenState();
}

class _OnlineScreenState extends ConsumerState<OnlineScreen> {
  late final OnlineClient _client = ref.read(onlineClientProvider);
  late final StreamSubscription<ErrorCode> _errors;

  @override
  void initState() {
    super.initState();
    _errors = _client.errors.listen((code) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorText(AppLocalizations.of(context), code))));
    });
  }

  @override
  void dispose() {
    unawaited(_errors.cancel());
    unawaited(_client.disconnect());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _client,
      builder: (context, _) {
        final match = _client.match;
        if (match != null) return OnlineGameView(key: ObjectKey(match), client: _client, match: match);
        final room = _client.room;
        if (room != null) return OnlineRoomView(client: _client, room: room);
        if (_client.status == OnlineStatus.connected) return _RoomListView(client: _client);
        return _ConnectView(client: _client);
      },
    );
  }
}

class _ConnectView extends ConsumerStatefulWidget {
  const _ConnectView({required this.client});

  final OnlineClient client;

  @override
  ConsumerState<_ConnectView> createState() => _ConnectViewState();
}

class _ConnectViewState extends ConsumerState<_ConnectView> {
  late final TextEditingController _name;
  late final TextEditingController _server;
  bool _failed = false;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(prefsProvider);
    _name = TextEditingController(text: p.getString('onlineName') ?? '');
    _server = TextEditingController(text: p.getString('onlineCustomServer') ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final p = ref.read(prefsProvider);
    await p.setString('onlineName', _name.text.trim());
    _cancelled = false;
    final custom = _server.text.trim();
    await p.setString('onlineCustomServer', custom);
    final ok = await widget.client.connect(custom.isEmpty ? defaultServerUrl : custom, _name.text);
    if (mounted) setState(() => _failed = !ok && !_cancelled);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final busy = widget.client.status == OnlineStatus.connecting;
    final message = _failed
        ? l.connectFailed
        : widget.client.lostConnection
            ? l.connectionLost
            : null;
    return Scaffold(
      appBar: AppBar(title: Text(l.onlineTitle), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _name,
                    maxLength: Limits.name,
                    textInputAction: TextInputAction.go,
                    decoration: InputDecoration(labelText: l.yourName, prefixIcon: const Icon(Icons.person)),
                    onSubmitted: (_) => busy ? null : _connect(),
                  ),
                  const SizedBox(height: 8),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(message,
                          textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                    ),
                  if (busy && widget.client.waking)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(l.serverWaking,
                          textAlign: TextAlign.center, style: const TextStyle(color: Colors.amberAccent)),
                    ),
                  FilledButton.icon(
                    onPressed: busy ? null : _connect,
                    icon: busy
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.wifi),
                    label: Text(l.connect),
                  ),
                  if (busy)
                    TextButton(
                      onPressed: () {
                        _cancelled = true;
                        widget.client.disconnect();
                      },
                      child: Text(l.cancel),
                    ),
                  const SizedBox(height: 16),
                  Text(l.onlineHint, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    title: Text(l.advanced, style: const TextStyle(color: Colors.white70)),
                    initiallyExpanded: _server.text.isNotEmpty,
                    children: [
                      TextField(
                        controller: _server,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: l.serverAddress,
                          hintText: l.serverHint,
                          prefixIcon: const Icon(Icons.dns),
                        ),
                        onSubmitted: (_) => busy ? null : _connect(),
                      ),
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

class _RoomListView extends StatelessWidget {
  const _RoomListView({required this.client});

  final OnlineClient client;

  Future<void> _join(BuildContext context, RoomSummary r) async {
    var password = '';
    if (r.locked) {
      final p = await showDialog<String>(context: context, builder: (_) => _PasswordDialog(room: r.name));
      if (p == null) return;
      password = p;
    }
    client.joinRoom(r.id, password: password);
  }

  Future<void> _create(BuildContext context) async {
    final req = await showDialog<_CreateRequest>(context: context, builder: (_) => const _CreateRoomDialog());
    if (req == null) return;
    client.createRoom(name: req.name, capacity: req.capacity, teams: req.teams, password: req.password);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rooms = client.rooms;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.rooms),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(tooltip: l.disconnect, onPressed: client.disconnect, icon: const Icon(Icons.wifi_off)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: Text(l.createRoom),
      ),
      body: SafeArea(
        child: rooms.isEmpty
            ? Center(child: Text(l.noRooms, style: const TextStyle(fontSize: 18, color: Colors.white70)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                itemCount: rooms.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final r = rooms[i];
                  return _RoomCard(room: r, onJoin: r.joinable ? () => _join(context, r) : null);
                },
              ),
      ),
    );
  }
}

/// One row of the room list. The name gets the full width (two lines max),
/// details live in chips below it and the join button sits on the right.
class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onJoin});

  final RoomSummary room;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final playing = room.phase == RoomPhase.playing;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (room.locked) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 2, right: 6),
                          child: Icon(Icons.lock, size: 16, color: Colors.amber),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          room.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Chip(
                        icon: room.teams ? Icons.groups : Icons.person,
                        label: roomModeLabel(l, room.capacity, room.teams),
                      ),
                      _SeatChip(players: room.players, capacity: room.capacity),
                      if (playing)
                        _Chip(icon: Icons.sports_esports, label: l.inGame, color: Colors.orangeAccent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: onJoin,
              style: FilledButton.styleFrom(minimumSize: const Size(84, 44), padding: const EdgeInsets.symmetric(horizontal: 18)),
              child: Text(l.join),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Flexible(
          child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

/// "2/4" with one dot per seat, filled when taken.
class _SeatChip extends StatelessWidget {
  const _SeatChip({required this.players, required this.capacity});

  final int players;
  final int capacity;

  @override
  Widget build(BuildContext context) {
    final full = players >= capacity;
    final c = full ? Colors.redAccent : Colors.greenAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: c.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < capacity; i++)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < players ? c : Colors.transparent,
              border: Border.all(color: c, width: 1.2),
            ),
          ),
        const SizedBox(width: 3),
        Text('$players/$capacity', style: TextStyle(fontSize: 12.5, color: c, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.room});

  final String room;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.room),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        obscureText: true,
        maxLength: Limits.password,
        decoration: InputDecoration(labelText: l.password, prefixIcon: const Icon(Icons.lock)),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text), child: Text(l.join)),
      ],
    );
  }
}

class _CreateRequest {
  const _CreateRequest(this.name, this.capacity, this.teams, this.password);

  final String name;
  final int capacity;
  final bool teams;
  final String password;
}

class _CreateRoomDialog extends StatefulWidget {
  const _CreateRoomDialog();

  @override
  State<_CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<_CreateRoomDialog> {
  final _name = TextEditingController();
  final _password = TextEditingController();
  int _capacity = 2;
  bool _teams = false;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final teams = _teams && _capacity == 4;
    return AlertDialog(
      title: Text(l.createRoom),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              maxLength: Limits.roomName,
              decoration: InputDecoration(labelText: l.roomName),
            ),
            const SizedBox(height: 8),
            Text(l.playerCount),
            const SizedBox(height: 6),
            SegmentedButton<int>(
              segments: [for (final n in [2, 3, 4]) ButtonSegment(value: n, label: Text('$n'))],
              selected: {_capacity},
              onSelectionChanged: (s) => setState(() => _capacity = s.first),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.teamsLabel),
              value: teams,
              onChanged: _capacity == 4 ? (v) => setState(() => _teams = v) : null,
            ),
            Text(roomModeLabel(l, _capacity, teams),
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.amber, fontSize: 16)),
            TextField(
              controller: _password,
              obscureText: true,
              maxLength: Limits.password,
              decoration: InputDecoration(labelText: l.passwordOptional, prefixIcon: const Icon(Icons.lock)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _CreateRequest(_name.text.trim(), _capacity, teams, _password.text),
          ),
          child: Text(l.create),
        ),
      ],
    );
  }
}
