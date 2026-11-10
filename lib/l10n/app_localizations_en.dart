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
  String get howMove => 'Move with the joystick.';

  @override
  String get howBomb =>
      'Drop a bomb with the bomb button. It explodes after 3 seconds in a plus shape.';

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
  String get reconnecting => 'Reconnecting…';

  @override
  String playerAway(String name) {
    return '$name lost connection';
  }

  @override
  String playerBack(String name) {
    return '$name is back';
  }

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
  String get powerDetonator => 'Detonator';

  @override
  String get powerGhost => 'Ghost';

  @override
  String get howDetonator =>
      'Detonator: use the blast button to set off all your bombs at once.';

  @override
  String get howGhost => 'Ghost: walk through crates for a few seconds.';

  @override
  String get howBoss =>
      'Every 25th level ends with a boss. Hit it several times!';

  @override
  String get howStars =>
      'Earn up to 3 stars per level: finish fast and take as few hits as possible. 2 stars allow one hit, 3 stars need a flawless run and lots of time left. Every new star pays coins.';

  @override
  String get detonateButton => 'Detonate bombs';

  @override
  String get coin => 'Coin';

  @override
  String get earnCoin => 'Free Coin';

  @override
  String get shopTitle => 'Coin shop';

  @override
  String get shopHint =>
      'Coins buy hats, faces, colours, emotes and extra lives. No pay-to-win: power-ups are never for sale.';

  @override
  String get adNotReady => 'No ad available right now. Try again in a moment.';

  @override
  String rewardGot(int n) {
    return '+$n Coin!';
  }

  @override
  String get notEnoughCoin => 'Not enough Coin';

  @override
  String get storeSoon => 'Store is not connected yet.';

  @override
  String coinAmount(int n) {
    return '$n Coin';
  }

  @override
  String get pkgSpark => 'Spark';

  @override
  String get pkgFuse => 'Fuse';

  @override
  String get pkgDynamite => 'Dynamite';

  @override
  String get pkgDepot => 'Bomb depot';

  @override
  String get mostPopular => 'MOST POPULAR';

  @override
  String get bestValue => 'BEST VALUE';

  @override
  String bonusPercent(int n) {
    return '+$n% bonus';
  }

  @override
  String get removeAds => 'Remove ads';

  @override
  String get removeAdsDesc => 'No more banners or pop-up ads.';

  @override
  String unlockFor(int n) {
    return 'Unlock for $n Coin?';
  }

  @override
  String get buy => 'Buy';

  @override
  String get watchAd => 'Watch ad';

  @override
  String get close => 'Close';

  @override
  String get livesOutTitle => 'Out of lives';

  @override
  String livesOutBody(String time) {
    return 'Every story attempt costs a life; you get it back when you win. A new life arrives in $time.';
  }

  @override
  String get livesRefillAd => 'Watch ad: +1 life';

  @override
  String livesRefillCoins(int n) {
    return 'Buy 1 life · $n coins';
  }

  @override
  String get livesWait => 'I\'ll wait';

  @override
  String livesChipLabel(int n, int max) {
    return '$n of $max lives';
  }

  @override
  String get achSeries_kills => 'Exterminator';

  @override
  String achStat_kills(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Defeat $n enemies',
      one: 'Defeat 1 enemy',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_blocks => 'Demolition crew';

  @override
  String achStat_blocks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Destroy $n crates',
      one: 'Destroy 1 crate',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_bombs => 'Bomber';

  @override
  String achStat_bombs(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Place $n bombs',
      one: 'Place 1 bomb',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_powerups => 'Collector';

  @override
  String achStat_powerups(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Collect $n power-ups',
      one: 'Collect 1 power-up',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_levels => 'Explorer';

  @override
  String achStat_levels(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Clear $n levels',
      one: 'Clear 1 level',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_stars => 'Star gazer';

  @override
  String achStat_stars(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Collect $n stars',
      one: 'Collect 1 star',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_perfect => 'Perfectionist';

  @override
  String achStat_perfect(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Get three stars on $n levels',
      one: 'Get three stars on 1 level',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_bosses => 'Boss slayer';

  @override
  String achStat_bosses(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Beat $n bosses',
      one: 'Beat 1 boss',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_wins => 'Champion';

  @override
  String achStat_wins(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Win $n battles',
      one: 'Win 1 battle',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_onlineWins => 'Online ace';

  @override
  String achStat_onlineWins(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Win $n online matches',
      one: 'Win 1 online match',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_onlineGames => 'Online regular';

  @override
  String achStat_onlineGames(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Play $n online matches',
      one: 'Play 1 online match',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_games => 'Veteran';

  @override
  String achStat_games(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Play $n games',
      one: 'Play 1 game',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_emotes => 'Chatterbox';

  @override
  String achStat_emotes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Send $n emotes',
      one: 'Send 1 emote',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_ads => 'Supporter';

  @override
  String achStat_ads(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Watch $n reward ads',
      one: 'Watch 1 reward ad',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_owned => 'Fashionista';

  @override
  String achStat_owned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Own $n wardrobe items',
      one: 'Own 1 wardrobe item',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_invites => 'Recruiter';

  @override
  String achStat_invites(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Invite $n friends',
      one: 'Invite 1 friend',
    );
    return '$_temp0';
  }

  @override
  String get achSeries_streak => 'Streak keeper';

  @override
  String achStat_streak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Play $n days in a row',
      one: 'Play 1 day in a row',
    );
    return '$_temp0';
  }

  @override
  String get achClaim => 'Claim';

  @override
  String get achClaimAll => 'Claim all';

  @override
  String get achReady => 'Ready to claim';

  @override
  String get achInProgress => 'In progress';

  @override
  String get achDone => 'Completed';

  @override
  String achReward(int n) {
    return '$n coins';
  }

  @override
  String get wardrobeEmotes => 'Emotes';

  @override
  String boostWatchAd(int n) {
    return 'Watch ad: start with $n bombs';
  }

  @override
  String boostReady(int n) {
    return 'Your next match starts with $n bombs';
  }

  @override
  String boostBadge(int n) {
    return 'starts with $n bombs';
  }

  @override
  String get editName => 'Edit name';

  @override
  String get randomName => 'Random name';

  @override
  String get save => 'Save';

  @override
  String nameRule(int min, int max) {
    return '$min–$max letters, numbers, spaces, _ . -';
  }

  @override
  String get nameInvalid => 'This name is not allowed.';

  @override
  String get accountGuest => 'Guest account';

  @override
  String get accountApple => 'Signed in with Apple';

  @override
  String get accountGoogle => 'Signed in with Google';

  @override
  String get starterTitle => 'Starter pack';

  @override
  String starterBody(int coins) {
    return '$coins coins + all lives refilled';
  }

  @override
  String starterEnds(String time) {
    return 'Ends in $time';
  }

  @override
  String firstBuyBonus(int n) {
    return 'First purchase: +$n bonus coins';
  }

  @override
  String get storeUnavailable => 'The store is not available right now.';

  @override
  String get productMissing => 'This product is not available yet.';

  @override
  String get purchaseFailed => 'Purchase failed. You were not charged.';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get purchasesRestored => 'Restoring purchases…';

  @override
  String get adsRemovedThanks => 'Ads removed. Thank you!';

  @override
  String get purchased => 'Purchased';

  @override
  String get daily => 'Daily';

  @override
  String get dailyLoginTitle => 'Daily reward';

  @override
  String dayN(int n) {
    return 'Day $n';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String get dailyQuests => 'Today\'s quests';

  @override
  String dailyAllDone(int n) {
    return 'All quests done: +$n coins';
  }

  @override
  String get dailyComeBack => 'Collected – come back tomorrow';

  @override
  String get dailyReset => 'New quests every day at midnight.';

  @override
  String quickParty(int n) {
    return '$n-player party';
  }

  @override
  String get controlsTitle => 'Customize controls';

  @override
  String get controlsHint =>
      'Drag the joystick and the bomb button to where your thumbs feel best.';

  @override
  String get controlsReset => 'Reset';

  @override
  String get controlsDone => 'Done';

  @override
  String get achievementToastTitle => 'Achievement unlocked';

  @override
  String get howRules => 'Rules';

  @override
  String get howPowerUps => 'Power-ups';

  @override
  String get quickDuelDesc => 'A fast, tense duel';

  @override
  String get quickBrawlDesc => 'The classic four-way brawl';

  @override
  String get quickPartyDesc => 'Chaos with up to seven buddies';

  @override
  String get shopPacks => 'Coin packs';

  @override
  String get firstBuyNote => 'Your first pack pays a bonus.';

  @override
  String firstBuyChip(int n) {
    return '+$n bonus coins';
  }

  @override
  String get hatName8 => 'Beanie';

  @override
  String get hatName9 => 'Chef hat';

  @override
  String get hatName10 => 'Pirate hat';

  @override
  String get hatName11 => 'Viking helmet';

  @override
  String get hatName12 => 'Cat ears';

  @override
  String get hatName13 => 'Bunny ears';

  @override
  String get hatName14 => 'Top hat';

  @override
  String get hatName15 => 'Daisy';

  @override
  String get hatName16 => 'Headphones';

  @override
  String get hatName17 => 'Propeller cap';

  @override
  String get hatName18 => 'Santa hat';

  @override
  String get hatName19 => 'Ninja band';

  @override
  String get hatName20 => 'Flame hair';

  @override
  String get hatName21 => 'Jester hat';

  @override
  String get hatName22 => 'Laurel wreath';

  @override
  String get hatName23 => 'Rainbow afro';

  @override
  String get faceName6 => 'Sleepy';

  @override
  String get faceName7 => 'Surprised';

  @override
  String get faceName8 => 'Heart eyes';

  @override
  String get faceName9 => 'Silly';

  @override
  String get faceName10 => 'Robot visor';

  @override
  String get faceName11 => 'Cyclops';

  @override
  String get tutTitle0 => 'Move';

  @override
  String get tutBody0 => 'Drag the joystick to the glowing spot.';

  @override
  String get tutTitle1 => 'Drop a bomb';

  @override
  String get tutBody1 => 'Stand next to the crate and tap the bomb button.';

  @override
  String get tutTitle2 => 'Run!';

  @override
  String get tutBody2 =>
      'The bomb explodes after 3 seconds in a plus shape. Get out of its line!';

  @override
  String get tutTitle3 => 'Power-up!';

  @override
  String get tutBody3 => 'Crates hide power-ups. Walk over it to collect it.';

  @override
  String get tutTitle4 => 'Beat the enemy';

  @override
  String get tutBody4 =>
      'Wait for it to come close, drop a bomb and run. Don\'t get caught in your own blast!';

  @override
  String get tutTitle5 => 'You\'re ready!';

  @override
  String get tutBody5 =>
      'Defeat every enemy, then step on the exit door. Earn up to 3 stars on each level.';

  @override
  String get tutTooFar =>
      'That was too far away. Try again right next to the crate.';

  @override
  String get tutSkip => 'Skip';

  @override
  String get tutDoneStart => 'Start the story';

  @override
  String get welcomeTitle => 'Welcome, buddy!';

  @override
  String welcomeBody(int n) {
    return 'Learn the basics in under a minute and get $n coins.';
  }

  @override
  String get welcomeStart => 'Let\'s go';

  @override
  String get welcomeSkip => 'Maybe later';

  @override
  String get howToTutorial => 'Play the tutorial';
}
