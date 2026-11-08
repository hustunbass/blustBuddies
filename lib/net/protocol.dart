/// Wire protocol shared by the online server and the app (pure Dart).
///
/// Every message is a JSON object with a string field `t` (type).
library;

/// Bumped on incompatible protocol changes.
const int protocolVersion = 1;

/// Default TCP port of the server.
const int defaultServerPort = 8080;

/// Input limits (enforced by the server, mirrored by the UI).
class Limits {
  Limits._();

  /// Player name length.
  static const int name = 16;

  /// Room name length.
  static const int roomName = 24;

  /// Room password length.
  static const int password = 32;

  /// Largest accepted client frame in bytes.
  static const int messageBytes = 4096;
}

/// Message type names.
class Msg {
  Msg._();

  // client -> server

  /// `{name, v, skin: [hat, face, colour]}` first message.
  static const hello = 'hello';

  /// `{name, capacity, teams, password?}`.
  static const createRoom = 'create';

  /// `{room, password?}`.
  static const joinRoom = 'join';

  /// Leave the current room.
  static const leaveRoom = 'leave';

  /// `{ready}`.
  static const setReady = 'ready';

  /// `{d: Dir index, b: bomb pressed, x: detonate}`.
  static const input = 'in';

  /// `{capacity}` join a public waiting room or open a new one (auto-ready).
  static const quick = 'quick';

  /// `{e: 0..5}` show an emote above your buddy (throttled).
  static const emote = 'emote';

  /// `{c: number}` latency probe; answered with [pong] echoing `c`.
  static const ping = 'ping';

  // server -> client

  /// `{id, ping: true}` reply to hello (`ping` = server answers [ping]).
  static const welcome = 'welcome';

  /// `{c}` echo of a [ping].
  static const pong = 'pong';

  /// `{rooms: [RoomSummary]}` lobby list.
  static const rooms = 'rooms';

  /// `{room: RoomDetails}` state of the room you are in.
  static const room = 'room';

  /// `{from, e}` somebody's emote.
  static const emoteFrom = 'emoted';

  /// `{slot}` a player left the running match.
  static const left = 'left';

  /// `{seed, cap, teams, you, names, skins}` match begins.
  static const start = 'start';

  /// World snapshot (see `snapshot.dart`).
  static const snapshot = 's';

  /// `{winner, team}` match finished (null = draw).
  static const end = 'end';

  /// `{code}` request rejected, see [ErrorCode].
  static const error = 'error';
}

/// Reasons a request is rejected.
enum ErrorCode {
  /// Unknown or malformed message.
  badRequest,

  /// Client speaks another protocol version.
  versionMismatch,

  /// Room does not exist any more.
  roomNotFound,

  /// Room has no free slot.
  roomFull,

  /// Match already running.
  inProgress,

  /// Missing or wrong password.
  wrongPassword,

  /// Too many wrong passwords; wait a bit.
  tooManyAttempts,

  /// Server room limit reached.
  serverFull;

  /// Parses [s] (unknown values map to [badRequest]).
  static ErrorCode parse(Object? s) =>
      values.firstWhere((e) => e.name == s, orElse: () => badRequest);
}

/// Lifecycle of a room.
enum RoomPhase {
  /// Waiting for players / ready.
  lobby,

  /// Everyone is ready; the match starts when the countdown ends.
  countdown,

  /// Match running.
  playing;

  /// Parses [s].
  static RoomPhase parse(Object? s) =>
      values.firstWhere((e) => e.name == s, orElse: () => lobby);
}

/// Validates a room shape: 2..4 players, teams only with 4 (2v2).
bool validRoomShape(int capacity, bool teams) =>
    capacity >= 2 && capacity <= 4 && (!teams || capacity == 4);

/// One room as shown in the room list.
class RoomSummary {
  /// Creates a summary.
  const RoomSummary({
    required this.id,
    required this.name,
    required this.capacity,
    required this.teams,
    required this.locked,
    required this.players,
    required this.phase,
  });

  /// Parses JSON.
  factory RoomSummary.fromJson(Map<String, dynamic> j) => RoomSummary(
        id: j['id'] as String,
        name: j['name'] as String,
        capacity: j['cap'] as int,
        teams: j['teams'] as bool,
        locked: j['locked'] as bool,
        players: j['n'] as int,
        phase: RoomPhase.parse(j['phase']),
      );

  /// Room id.
  final String id;

  /// Display name.
  final String name;

  /// Max players (2..4).
  final int capacity;

  /// 2v2 teams.
  final bool teams;

  /// Password protected.
  final bool locked;

  /// Current player count.
  final int players;

  /// Phase.
  final RoomPhase phase;

  /// Whether a new player could join right now.
  bool get joinable => players < capacity && phase == RoomPhase.lobby;

  /// JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cap': capacity,
        'teams': teams,
        'locked': locked,
        'n': players,
        'phase': phase.name,
      };
}

/// A player sitting in a room slot.
class RoomMember {
  /// Creates a member.
  const RoomMember({required this.name, required this.ready, this.you = false});

  /// Parses JSON.
  factory RoomMember.fromJson(Map<String, dynamic> j) => RoomMember(
        name: j['name'] as String,
        ready: j['ready'] as bool,
        you: j['you'] as bool? ?? false,
      );

  /// Display name.
  final String name;

  /// Pressed ready.
  final bool ready;

  /// This member is the receiving client.
  final bool you;

  /// JSON.
  Map<String, dynamic> toJson() => {'name': name, 'ready': ready, if (you) 'you': true};
}

/// Full state of the room the client is in.
class RoomDetails {
  /// Creates details.
  const RoomDetails({
    required this.id,
    required this.name,
    required this.capacity,
    required this.teams,
    required this.locked,
    required this.slots,
    required this.phase,
    this.countdown,
  });

  /// Parses JSON.
  factory RoomDetails.fromJson(Map<String, dynamic> j) => RoomDetails(
        id: j['id'] as String,
        name: j['name'] as String,
        capacity: j['cap'] as int,
        teams: j['teams'] as bool,
        locked: j['locked'] as bool,
        slots: [
          for (final s in j['slots'] as List)
            s == null ? null : RoomMember.fromJson((s as Map).cast<String, dynamic>()),
        ],
        phase: RoomPhase.parse(j['phase']),
        countdown: (j['cd'] as num?)?.toDouble(),
      );

  /// Room id.
  final String id;

  /// Display name.
  final String name;

  /// Max players.
  final int capacity;

  /// 2v2 teams (team of slot i is `i % 2`).
  final bool teams;

  /// Password protected.
  final bool locked;

  /// Members by slot (length == [capacity]); null = free.
  final List<RoomMember?> slots;

  /// Phase.
  final RoomPhase phase;

  /// Seconds until start while [phase] is [RoomPhase.countdown].
  final double? countdown;

  /// Slot of the receiving client, or -1.
  int get mySlot => slots.indexWhere((m) => m?.you ?? false);

  /// Number of occupied slots.
  int get filled => slots.where((m) => m != null).length;

  /// JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cap': capacity,
        'teams': teams,
        'locked': locked,
        'slots': [for (final m in slots) m?.toJson()],
        'phase': phase.name,
        if (countdown != null) 'cd': countdown,
      };
}

/// Trims [s] to at most [max] characters and strips control characters.
String cleanText(Object? s, int max) {
  if (s is! String) return '';
  final t = s.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
  return t.length > max ? t.substring(0, max) : t;
}
