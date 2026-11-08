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
  String get howTime =>
      'Story levels are timed (a little shorter later on) and you have 3 lives.';

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

  @override
  String get wardrobe => 'Wardrobe';

  @override
  String get achievements => 'Achievements';

  @override
  String worldN(int n) {
    return 'World $n';
  }

  @override
  String starsCount(int n) {
    return '$n stars';
  }

  @override
  String get bossLevel => 'BOSS';

  @override
  String levelStart(int n) {
    return 'Level $n';
  }

  @override
  String get mapName0 => 'Neon Arena';

  @override
  String get mapName1 => 'Jungle Ruins';

  @override
  String get mapName2 => 'Desert Dunes';

  @override
  String get mapName3 => 'Frozen Peak';

  @override
  String get mapName4 => 'Lava Forge';

  @override
  String get mapName5 => 'Deep Ocean';

  @override
  String get mapName6 => 'Cosmic Station';

  @override
  String get worldStory0 =>
      'The buddies wake up in a neon training arena. Time to learn the ropes!';

  @override
  String get worldStory1 =>
      'Ancient ruins hide crates of treasure — and angry robots.';

  @override
  String get worldStory2 =>
      'Hot sand, long shadows. The robots never sleep here.';

  @override
  String get worldStory3 => 'A frozen peak. Slippery nerves, sharp blasts.';

  @override
  String get worldStory4 => 'The forge burns day and night. Watch your step!';

  @override
  String get worldStory5 => 'Deep below the waves, the robots built a base.';

  @override
  String get worldStory6 =>
      'The last station in space. Nothing can stop the buddies now.';

  @override
  String get worldStory7 =>
      'The jungle again — but the robots came back stronger.';

  @override
  String get worldStory8 => 'The dunes shift, the robots multiply.';

  @override
  String get worldStory9 => 'The final stretch. Become the Blast Buddy legend!';

  @override
  String achievementUnlocked(String name) {
    return 'Achievement unlocked: $name';
  }

  @override
  String get starsEarnedLabel => 'Stars earned';

  @override
  String get quickMatch => 'Quick match';

  @override
  String get quick1v1 => '1 vs 1';

  @override
  String get quick4 => '4-player free-for-all';

  @override
  String get quickHint =>
      'Find a match now. You start as soon as the room is full.';

  @override
  String get joinByCode => 'Join by code';

  @override
  String get enterCode => 'Room code';

  @override
  String roomCode(String code) {
    return 'Room code: $code';
  }

  @override
  String get copyCode => 'Copy code';

  @override
  String get codeCopied => 'Code copied';

  @override
  String playerLeftMatch(String name) {
    return '$name left the match';
  }

  @override
  String get emote => 'Emote';

  @override
  String get rematch => 'Play again';

  @override
  String get roomNotFoundMsg => 'No room with that code.';

  @override
  String get floatingStick => 'Floating joystick';

  @override
  String get floatingStickHint => 'The stick appears where you touch.';

  @override
  String get leftHanded => 'Left-handed layout';

  @override
  String get botDifficulty => 'Bot difficulty';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyNormal => 'Normal';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get dailyArena => 'Daily arena';

  @override
  String get dailyArenaHint => 'Everyone plays the same arena today.';

  @override
  String get wardrobeHat => 'Hat';

  @override
  String get wardrobeFace => 'Face';

  @override
  String get wardrobeColor => 'Colour';

  @override
  String starsToUnlock(int n) {
    return '$n stars to unlock';
  }

  @override
  String yourStars(int n) {
    return 'Your stars: $n';
  }

  @override
  String get hatName0 => 'None';

  @override
  String get hatName1 => 'Cap';

  @override
  String get hatName2 => 'Party hat';

  @override
  String get hatName3 => 'Cowboy hat';

  @override
  String get hatName4 => 'Crown';

  @override
  String get hatName5 => 'Wizard hat';

  @override
  String get hatName6 => 'Halo';

  @override
  String get hatName7 => 'Horns';

  @override
  String get faceName0 => 'Classic';

  @override
  String get faceName1 => 'Happy';

  @override
  String get faceName2 => 'Cool';

  @override
  String get faceName3 => 'Angry';

  @override
  String get faceName4 => 'Wink';

  @override
  String get faceName5 => 'Star eyes';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get stat_kills => 'Enemies defeated';

  @override
  String get stat_blocks => 'Crates destroyed';

  @override
  String get stat_bombs => 'Bombs placed';

  @override
  String get stat_wins => 'Battle wins';

  @override
  String get stat_onlineWins => 'Online wins';

  @override
  String get stat_levels => 'Levels cleared';

  @override
  String get stat_bosses => 'Bosses beaten';

  @override
  String get stat_stars => 'Stars';

  @override
  String get stat_powerups => 'Power-ups collected';

  @override
  String get stat_perfect => 'Three-star levels';

  @override
  String get ach_firstBlood => 'First blood';

  @override
  String achDesc_firstBlood(int n) {
    return 'Defeat $n enemy';
  }

  @override
  String get ach_firstWin => 'First victory';

  @override
  String achDesc_firstWin(int n) {
    return 'Win $n battle';
  }

  @override
  String get ach_bomber => 'Bomber';

  @override
  String achDesc_bomber(int n) {
    return 'Place $n bombs';
  }

  @override
  String get ach_demolition => 'Demolition crew';

  @override
  String achDesc_demolition(int n) {
    return 'Destroy $n crates';
  }

  @override
  String get ach_collector => 'Collector';

  @override
  String achDesc_collector(int n) {
    return 'Collect $n power-ups';
  }

  @override
  String get ach_chapter => 'Chapter one';

  @override
  String achDesc_chapter(int n) {
    return 'Clear $n levels';
  }

  @override
  String get ach_stars30 => 'Star gazer';

  @override
  String achDesc_stars30(int n) {
    return 'Collect $n stars';
  }

  @override
  String get ach_exterminator => 'Exterminator';

  @override
  String achDesc_exterminator(int n) {
    return 'Defeat $n enemies';
  }

  @override
  String get ach_champion => 'Champion';

  @override
  String achDesc_champion(int n) {
    return 'Win $n battles';
  }

  @override
  String get ach_online1 => 'Online debut';

  @override
  String achDesc_online1(int n) {
    return 'Win $n online match';
  }

  @override
  String get ach_boss1 => 'Boss slayer';

  @override
  String achDesc_boss1(int n) {
    return 'Beat $n boss';
  }

  @override
  String get ach_perfectionist => 'Perfectionist';

  @override
  String achDesc_perfectionist(int n) {
    return 'Get three stars on $n levels';
  }

  @override
  String get ach_explorer => 'Explorer';

  @override
  String achDesc_explorer(int n) {
    return 'Clear $n levels';
  }

  @override
  String get ach_online10 => 'Online ace';

  @override
  String achDesc_online10(int n) {
    return 'Win $n online matches';
  }

  @override
  String get ach_bosses4 => 'Boss master';

  @override
  String achDesc_bosses4(int n) {
    return 'Beat all $n bosses';
  }

  @override
  String get ach_legend => 'Legend';

  @override
  String achDesc_legend(int n) {
    return 'Clear all $n levels';
  }

  @override
  String get powerDetonator => 'Detonator';

  @override
  String get powerGhost => 'Ghost';

  @override
  String get howDetonator =>
      'Detonator: use the blast button (key E) to set off all your bombs at once.';

  @override
  String get howGhost => 'Ghost: walk through crates for a few seconds.';

  @override
  String get howBoss =>
      'Every 25th level ends with a boss. Hit it several times!';

  @override
  String get howStars =>
      'Earn up to 3 stars per level: no hits taken and plenty of time left. Stars unlock hats, faces and colours.';

  @override
  String get detonateButton => 'Detonate bombs';
}
