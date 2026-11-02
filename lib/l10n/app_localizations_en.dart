// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Blast Buddies';

  @override
  String get storyMode => 'Story';

  @override
  String get battleMode => 'Battle';

  @override
  String get howToPlay => 'How to Play';

  @override
  String get settings => 'Settings';

  @override
  String get selectLevel => 'Select Level';

  @override
  String levelN(int n) {
    return 'Level $n';
  }

  @override
  String get levelLocked => 'Locked';

  @override
  String bestScore(int score) {
    return 'Best score: $score';
  }

  @override
  String get lives => 'Lives';

  @override
  String get score => 'Score';

  @override
  String get time => 'Time';

  @override
  String get enemiesLeft => 'Enemies';

  @override
  String get pause => 'Pause';

  @override
  String get paused => 'Paused';

  @override
  String get resume => 'Resume';

  @override
  String get restart => 'Restart';

  @override
  String get mainMenu => 'Main menu';

  @override
  String get gameOver => 'Game over';

  @override
  String get levelComplete => 'Level complete!';

  @override
  String get allLevelsDone => 'You cleared every level!';

  @override
  String get nextLevel => 'Next level';

  @override
  String get tryAgain => 'Try again';

  @override
  String finalScore(int score) {
    return 'Score: $score';
  }

  @override
  String playerWins(int n) {
    return 'Player $n wins!';
  }

  @override
  String get draw => 'Draw!';

  @override
  String get playAgain => 'Play again';

  @override
  String get sound => 'Sound effects';

  @override
  String get music => 'Music';

  @override
  String get vibration => 'Vibration';

  @override
  String get controlSize => 'Control size';

  @override
  String get battleSetup => 'Battle setup';

  @override
  String get botPlayers => 'Bots';

  @override
  String get startBattle => 'Start battle';

  @override
  String get battleHint =>
      'You battle 1-3 bots. To play with friends on other devices, use Online mode.';

  @override
  String playerN(int n) {
    return 'P$n';
  }

  @override
  String get joystick => 'Movement joystick';

  @override
  String get bombButton => 'Drop bomb';

  @override
  String get howMove => 'Move with the joystick (arrow keys / WASD).';

  @override
  String get howBomb =>
      'Drop a bomb with the bomb button (Space). It explodes after 3 seconds in a plus shape.';

  @override
  String get howBlocks =>
      'Blasts destroy crates but stop at steel walls. Bombs set off other bombs.';

  @override
  String get howEnemies =>
      'Defeat every enemy to open the exit door, then step on it. Watch out for chasers and speedsters!';

  @override
  String get howShield => 'Shield: protects you for a few seconds.';

  @override
  String get powerBomb => 'Extra bomb';

  @override
  String get powerRange => 'Longer blasts';

  @override
  String get powerSpeed => 'Speed up';

  @override
  String get powerShield => 'Shield';

  @override
  String get powerKick => 'Bomb kick';

  @override
  String get howBattle =>
      'Battle: last buddy standing wins. Play with friends or bots.';

  @override
  String get howTime => 'You have 3 minutes per level and 3 lives.';

  @override
  String get back => 'Back';

  @override
  String get language => 'Language follows your device settings.';

  @override
  String get onlineMode => 'Online';

  @override
  String get onlineTitle => 'Online battle';

  @override
  String get yourName => 'Your name';

  @override
  String get serverAddress => 'Custom server address';

  @override
  String get serverHint => 'Leave empty for the default server';

  @override
  String get advanced => 'Advanced';

  @override
  String get serverWaking =>
      'Waking up the server, this can take about a minute…';

  @override
  String get onlineHint =>
      'Enter your name and connect. Create a room or join one your friends created.';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get connectFailed => 'Could not connect to the server.';

  @override
  String get connectionLost => 'Connection lost.';

  @override
  String get rooms => 'Rooms';

  @override
  String get noRooms => 'No rooms yet. Create one!';

  @override
  String get createRoom => 'Create room';

  @override
  String get roomName => 'Room name';

  @override
  String get playerCount => 'Players';

  @override
  String get teamsLabel => 'Teams (2 vs 2)';

  @override
  String get passwordOptional => 'Password (optional)';

  @override
  String get password => 'Password';

  @override
  String get create => 'Create';

  @override
  String get join => 'Join';

  @override
  String get cancel => 'Cancel';

  @override
  String get modeDuel => '1 vs 1';

  @override
  String get modeTeams => '2 vs 2';

  @override
  String modeFfa(int n) {
    return '$n players, free-for-all';
  }

  @override
  String get inGame => 'In game';

  @override
  String get readyLabel => 'Ready';

  @override
  String get notReady => 'Not ready';

  @override
  String get imReady => 'Ready!';

  @override
  String get cancelReady => 'Not ready';

  @override
  String waitingForPlayers(int n, int cap) {
    return 'Waiting for players… ($n/$cap)';
  }

  @override
  String get waitingForReady => 'Waiting for everyone to be ready…';

  @override
  String startsIn(int n) {
    return 'Starting in $n…';
  }

  @override
  String get leaveRoom => 'Leave room';

  @override
  String get emptySlot => 'Empty slot';

  @override
  String youTag(String name) {
    return '$name (you)';
  }

  @override
  String teamN(int n) {
    return 'Team $n';
  }

  @override
  String teamWins(int n) {
    return 'Team $n wins!';
  }

  @override
  String nameWins(String name) {
    return '$name wins!';
  }

  @override
  String get backToRoom => 'Back to room';

  @override
  String get leaveMatch => 'Leave match';

  @override
  String get leaveMatchQuestion => 'Leave the match?';

  @override
  String get errWrongPassword => 'Wrong password.';

  @override
  String get errRoomFull => 'The room is full.';

  @override
  String get errRoomNotFound => 'The room no longer exists.';

  @override
  String get errInProgress => 'The match has already started.';

  @override
  String get errTooManyAttempts =>
      'Too many wrong attempts. Try again in a minute.';

  @override
  String get errServerFull => 'The server is full.';

  @override
  String get errVersion => 'App and server versions do not match.';

  @override
  String get errGeneric => 'Request rejected.';
}
