import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Blast Buddies'**
  String get appTitle;

  /// No description provided for @storyMode.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get storyMode;

  /// No description provided for @battleMode.
  ///
  /// In en, this message translates to:
  /// **'Battle'**
  String get battleMode;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get howToPlay;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @selectLevel.
  ///
  /// In en, this message translates to:
  /// **'Select Level'**
  String get selectLevel;

  /// No description provided for @levelN.
  ///
  /// In en, this message translates to:
  /// **'Level {n}'**
  String levelN(int n);

  /// No description provided for @levelLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get levelLocked;

  /// No description provided for @bestScore.
  ///
  /// In en, this message translates to:
  /// **'Best score: {score}'**
  String bestScore(int score);

  /// No description provided for @lives.
  ///
  /// In en, this message translates to:
  /// **'Lives'**
  String get lives;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @enemiesLeft.
  ///
  /// In en, this message translates to:
  /// **'Enemies'**
  String get enemiesLeft;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get mainMenu;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get gameOver;

  /// No description provided for @levelComplete.
  ///
  /// In en, this message translates to:
  /// **'Level complete!'**
  String get levelComplete;

  /// No description provided for @allLevelsDone.
  ///
  /// In en, this message translates to:
  /// **'You cleared every level!'**
  String get allLevelsDone;

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next level'**
  String get nextLevel;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @finalScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String finalScore(int score);

  /// No description provided for @playerWins.
  ///
  /// In en, this message translates to:
  /// **'Player {n} wins!'**
  String playerWins(int n);

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw!'**
  String get draw;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get sound;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @controlSize.
  ///
  /// In en, this message translates to:
  /// **'Control size'**
  String get controlSize;

  /// No description provided for @battleSetup.
  ///
  /// In en, this message translates to:
  /// **'Battle setup'**
  String get battleSetup;

  /// No description provided for @botPlayers.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get botPlayers;

  /// No description provided for @startBattle.
  ///
  /// In en, this message translates to:
  /// **'Start battle'**
  String get startBattle;

  /// No description provided for @battleHint.
  ///
  /// In en, this message translates to:
  /// **'You battle 1-3 bots. To play with friends on other devices, use Online mode.'**
  String get battleHint;

  /// No description provided for @playerN.
  ///
  /// In en, this message translates to:
  /// **'P{n}'**
  String playerN(int n);

  /// No description provided for @joystick.
  ///
  /// In en, this message translates to:
  /// **'Movement joystick'**
  String get joystick;

  /// No description provided for @bombButton.
  ///
  /// In en, this message translates to:
  /// **'Drop bomb'**
  String get bombButton;

  /// No description provided for @howMove.
  ///
  /// In en, this message translates to:
  /// **'Move with the joystick (arrow keys / WASD).'**
  String get howMove;

  /// No description provided for @howBomb.
  ///
  /// In en, this message translates to:
  /// **'Drop a bomb with the bomb button (Space). It explodes after 3 seconds in a plus shape.'**
  String get howBomb;

  /// No description provided for @howBlocks.
  ///
  /// In en, this message translates to:
  /// **'Blasts destroy crates but stop at steel walls. Bombs set off other bombs.'**
  String get howBlocks;

  /// No description provided for @howEnemies.
  ///
  /// In en, this message translates to:
  /// **'Defeat every enemy to open the exit door, then step on it. Watch out for chasers and speedsters!'**
  String get howEnemies;

  /// No description provided for @howShield.
  ///
  /// In en, this message translates to:
  /// **'Shield: protects you for a few seconds.'**
  String get howShield;

  /// No description provided for @powerBomb.
  ///
  /// In en, this message translates to:
  /// **'Extra bomb'**
  String get powerBomb;

  /// No description provided for @powerRange.
  ///
  /// In en, this message translates to:
  /// **'Longer blasts'**
  String get powerRange;

  /// No description provided for @powerSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed up'**
  String get powerSpeed;

  /// No description provided for @powerShield.
  ///
  /// In en, this message translates to:
  /// **'Shield'**
  String get powerShield;

  /// No description provided for @powerKick.
  ///
  /// In en, this message translates to:
  /// **'Bomb kick'**
  String get powerKick;

  /// No description provided for @howBattle.
  ///
  /// In en, this message translates to:
  /// **'Battle: last buddy standing wins. Play with friends or bots.'**
  String get howBattle;

  /// No description provided for @howTime.
  ///
  /// In en, this message translates to:
  /// **'Story levels are timed (a little shorter later on) and you have 3 lives.'**
  String get howTime;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language follows your device settings.'**
  String get language;

  /// No description provided for @onlineMode.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineMode;

  /// No description provided for @onlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Online battle'**
  String get onlineTitle;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @serverAddress.
  ///
  /// In en, this message translates to:
  /// **'Custom server address'**
  String get serverAddress;

  /// No description provided for @serverHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for the default server'**
  String get serverHint;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @serverWaking.
  ///
  /// In en, this message translates to:
  /// **'Waking up the server, this can take about a minute…'**
  String get serverWaking;

  /// No description provided for @onlineHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name and connect. Create a room or join one your friends created.'**
  String get onlineHint;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @connectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server.'**
  String get connectFailed;

  /// No description provided for @connectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost.'**
  String get connectionLost;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @noRooms.
  ///
  /// In en, this message translates to:
  /// **'No rooms yet. Create one!'**
  String get noRooms;

  /// No description provided for @createRoom.
  ///
  /// In en, this message translates to:
  /// **'Create room'**
  String get createRoom;

  /// No description provided for @roomName.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get roomName;

  /// No description provided for @playerCount.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get playerCount;

  /// No description provided for @teamsLabel.
  ///
  /// In en, this message translates to:
  /// **'Teams (2 vs 2)'**
  String get teamsLabel;

  /// No description provided for @passwordOptional.
  ///
  /// In en, this message translates to:
  /// **'Password (optional)'**
  String get passwordOptional;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @modeDuel.
  ///
  /// In en, this message translates to:
  /// **'1 vs 1'**
  String get modeDuel;

  /// No description provided for @modeTeams.
  ///
  /// In en, this message translates to:
  /// **'2 vs 2'**
  String get modeTeams;

  /// No description provided for @modeFfa.
  ///
  /// In en, this message translates to:
  /// **'{n} players, free-for-all'**
  String modeFfa(int n);

  /// No description provided for @inGame.
  ///
  /// In en, this message translates to:
  /// **'In game'**
  String get inGame;

  /// No description provided for @readyLabel.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get readyLabel;

  /// No description provided for @notReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get notReady;

  /// No description provided for @imReady.
  ///
  /// In en, this message translates to:
  /// **'Ready!'**
  String get imReady;

  /// No description provided for @cancelReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get cancelReady;

  /// No description provided for @waitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for players… ({n}/{cap})'**
  String waitingForPlayers(int n, int cap);

  /// No description provided for @waitingForReady.
  ///
  /// In en, this message translates to:
  /// **'Waiting for everyone to be ready…'**
  String get waitingForReady;

  /// No description provided for @startsIn.
  ///
  /// In en, this message translates to:
  /// **'Starting in {n}…'**
  String startsIn(int n);

  /// No description provided for @leaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get leaveRoom;

  /// No description provided for @emptySlot.
  ///
  /// In en, this message translates to:
  /// **'Empty slot'**
  String get emptySlot;

  /// No description provided for @youTag.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String youTag(String name);

  /// No description provided for @teamN.
  ///
  /// In en, this message translates to:
  /// **'Team {n}'**
  String teamN(int n);

  /// No description provided for @teamWins.
  ///
  /// In en, this message translates to:
  /// **'Team {n} wins!'**
  String teamWins(int n);

  /// No description provided for @nameWins.
  ///
  /// In en, this message translates to:
  /// **'{name} wins!'**
  String nameWins(String name);

  /// No description provided for @backToRoom.
  ///
  /// In en, this message translates to:
  /// **'Back to room'**
  String get backToRoom;

  /// No description provided for @leaveMatch.
  ///
  /// In en, this message translates to:
  /// **'Leave match'**
  String get leaveMatch;

  /// No description provided for @leaveMatchQuestion.
  ///
  /// In en, this message translates to:
  /// **'Leave the match?'**
  String get leaveMatchQuestion;

  /// No description provided for @errWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get errWrongPassword;

  /// No description provided for @errRoomFull.
  ///
  /// In en, this message translates to:
  /// **'The room is full.'**
  String get errRoomFull;

  /// No description provided for @errRoomNotFound.
  ///
  /// In en, this message translates to:
  /// **'The room no longer exists.'**
  String get errRoomNotFound;

  /// No description provided for @errInProgress.
  ///
  /// In en, this message translates to:
  /// **'The match has already started.'**
  String get errInProgress;

  /// No description provided for @errTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong attempts. Try again in a minute.'**
  String get errTooManyAttempts;

  /// No description provided for @errServerFull.
  ///
  /// In en, this message translates to:
  /// **'The server is full.'**
  String get errServerFull;

  /// No description provided for @errVersion.
  ///
  /// In en, this message translates to:
  /// **'App and server versions do not match.'**
  String get errVersion;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Request rejected.'**
  String get errGeneric;

  /// No description provided for @wardrobe.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe'**
  String get wardrobe;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @worldN.
  ///
  /// In en, this message translates to:
  /// **'World {n}'**
  String worldN(int n);

  /// No description provided for @starsCount.
  ///
  /// In en, this message translates to:
  /// **'{n} stars'**
  String starsCount(int n);

  /// No description provided for @bossLevel.
  ///
  /// In en, this message translates to:
  /// **'BOSS'**
  String get bossLevel;

  /// No description provided for @levelStart.
  ///
  /// In en, this message translates to:
  /// **'Level {n}'**
  String levelStart(int n);

  /// No description provided for @mapName0.
  ///
  /// In en, this message translates to:
  /// **'Neon Arena'**
  String get mapName0;

  /// No description provided for @mapName1.
  ///
  /// In en, this message translates to:
  /// **'Jungle Ruins'**
  String get mapName1;

  /// No description provided for @mapName2.
  ///
  /// In en, this message translates to:
  /// **'Desert Dunes'**
  String get mapName2;

  /// No description provided for @mapName3.
  ///
  /// In en, this message translates to:
  /// **'Frozen Peak'**
  String get mapName3;

  /// No description provided for @mapName4.
  ///
  /// In en, this message translates to:
  /// **'Lava Forge'**
  String get mapName4;

  /// No description provided for @mapName5.
  ///
  /// In en, this message translates to:
  /// **'Deep Ocean'**
  String get mapName5;

  /// No description provided for @mapName6.
  ///
  /// In en, this message translates to:
  /// **'Cosmic Station'**
  String get mapName6;

  /// No description provided for @worldStory0.
  ///
  /// In en, this message translates to:
  /// **'The buddies wake up in a neon training arena. Time to learn the ropes!'**
  String get worldStory0;

  /// No description provided for @worldStory1.
  ///
  /// In en, this message translates to:
  /// **'Ancient ruins hide crates of treasure — and angry robots.'**
  String get worldStory1;

  /// No description provided for @worldStory2.
  ///
  /// In en, this message translates to:
  /// **'Hot sand, long shadows. The robots never sleep here.'**
  String get worldStory2;

  /// No description provided for @worldStory3.
  ///
  /// In en, this message translates to:
  /// **'A frozen peak. Slippery nerves, sharp blasts.'**
  String get worldStory3;

  /// No description provided for @worldStory4.
  ///
  /// In en, this message translates to:
  /// **'The forge burns day and night. Watch your step!'**
  String get worldStory4;

  /// No description provided for @worldStory5.
  ///
  /// In en, this message translates to:
  /// **'Deep below the waves, the robots built a base.'**
  String get worldStory5;

  /// No description provided for @worldStory6.
  ///
  /// In en, this message translates to:
  /// **'The last station in space. Nothing can stop the buddies now.'**
  String get worldStory6;

  /// No description provided for @worldStory7.
  ///
  /// In en, this message translates to:
  /// **'The jungle again — but the robots came back stronger.'**
  String get worldStory7;

  /// No description provided for @worldStory8.
  ///
  /// In en, this message translates to:
  /// **'The dunes shift, the robots multiply.'**
  String get worldStory8;

  /// No description provided for @worldStory9.
  ///
  /// In en, this message translates to:
  /// **'The final stretch. Become the Blast Buddy legend!'**
  String get worldStory9;

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked: {name}'**
  String achievementUnlocked(String name);

  /// No description provided for @starsEarnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Stars earned'**
  String get starsEarnedLabel;

  /// No description provided for @quickMatch.
  ///
  /// In en, this message translates to:
  /// **'Quick match'**
  String get quickMatch;

  /// No description provided for @quick1v1.
  ///
  /// In en, this message translates to:
  /// **'1 vs 1'**
  String get quick1v1;

  /// No description provided for @quick4.
  ///
  /// In en, this message translates to:
  /// **'4-player free-for-all'**
  String get quick4;

  /// No description provided for @quickHint.
  ///
  /// In en, this message translates to:
  /// **'Find a match now. You start as soon as the room is full.'**
  String get quickHint;

  /// No description provided for @joinByCode.
  ///
  /// In en, this message translates to:
  /// **'Join by code'**
  String get joinByCode;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Room code'**
  String get enterCode;

  /// No description provided for @roomCode.
  ///
  /// In en, this message translates to:
  /// **'Room code: {code}'**
  String roomCode(String code);

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @playerLeftMatch.
  ///
  /// In en, this message translates to:
  /// **'{name} left the match'**
  String playerLeftMatch(String name);

  /// No description provided for @emote.
  ///
  /// In en, this message translates to:
  /// **'Emote'**
  String get emote;

  /// No description provided for @rematch.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get rematch;

  /// No description provided for @roomNotFoundMsg.
  ///
  /// In en, this message translates to:
  /// **'No room with that code.'**
  String get roomNotFoundMsg;

  /// No description provided for @floatingStick.
  ///
  /// In en, this message translates to:
  /// **'Floating joystick'**
  String get floatingStick;

  /// No description provided for @floatingStickHint.
  ///
  /// In en, this message translates to:
  /// **'The stick appears where you touch.'**
  String get floatingStickHint;

  /// No description provided for @leftHanded.
  ///
  /// In en, this message translates to:
  /// **'Left-handed layout'**
  String get leftHanded;

  /// No description provided for @botDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Bot difficulty'**
  String get botDifficulty;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get difficultyNormal;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @dailyArena.
  ///
  /// In en, this message translates to:
  /// **'Daily arena'**
  String get dailyArena;

  /// No description provided for @dailyArenaHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone plays the same arena today.'**
  String get dailyArenaHint;

  /// No description provided for @wardrobeHat.
  ///
  /// In en, this message translates to:
  /// **'Hat'**
  String get wardrobeHat;

  /// No description provided for @wardrobeFace.
  ///
  /// In en, this message translates to:
  /// **'Face'**
  String get wardrobeFace;

  /// No description provided for @wardrobeColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get wardrobeColor;

  /// No description provided for @starsToUnlock.
  ///
  /// In en, this message translates to:
  /// **'{n} stars to unlock'**
  String starsToUnlock(int n);

  /// No description provided for @yourStars.
  ///
  /// In en, this message translates to:
  /// **'Your stars: {n}'**
  String yourStars(int n);

  /// No description provided for @hatName0.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get hatName0;

  /// No description provided for @hatName1.
  ///
  /// In en, this message translates to:
  /// **'Cap'**
  String get hatName1;

  /// No description provided for @hatName2.
  ///
  /// In en, this message translates to:
  /// **'Party hat'**
  String get hatName2;

  /// No description provided for @hatName3.
  ///
  /// In en, this message translates to:
  /// **'Cowboy hat'**
  String get hatName3;

  /// No description provided for @hatName4.
  ///
  /// In en, this message translates to:
  /// **'Crown'**
  String get hatName4;

  /// No description provided for @hatName5.
  ///
  /// In en, this message translates to:
  /// **'Wizard hat'**
  String get hatName5;

  /// No description provided for @hatName6.
  ///
  /// In en, this message translates to:
  /// **'Halo'**
  String get hatName6;

  /// No description provided for @hatName7.
  ///
  /// In en, this message translates to:
  /// **'Horns'**
  String get hatName7;

  /// No description provided for @faceName0.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get faceName0;

  /// No description provided for @faceName1.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get faceName1;

  /// No description provided for @faceName2.
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get faceName2;

  /// No description provided for @faceName3.
  ///
  /// In en, this message translates to:
  /// **'Angry'**
  String get faceName3;

  /// No description provided for @faceName4.
  ///
  /// In en, this message translates to:
  /// **'Wink'**
  String get faceName4;

  /// No description provided for @faceName5.
  ///
  /// In en, this message translates to:
  /// **'Star eyes'**
  String get faceName5;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @stat_kills.
  ///
  /// In en, this message translates to:
  /// **'Enemies defeated'**
  String get stat_kills;

  /// No description provided for @stat_blocks.
  ///
  /// In en, this message translates to:
  /// **'Crates destroyed'**
  String get stat_blocks;

  /// No description provided for @stat_bombs.
  ///
  /// In en, this message translates to:
  /// **'Bombs placed'**
  String get stat_bombs;

  /// No description provided for @stat_wins.
  ///
  /// In en, this message translates to:
  /// **'Battle wins'**
  String get stat_wins;

  /// No description provided for @stat_onlineWins.
  ///
  /// In en, this message translates to:
  /// **'Online wins'**
  String get stat_onlineWins;

  /// No description provided for @stat_levels.
  ///
  /// In en, this message translates to:
  /// **'Levels cleared'**
  String get stat_levels;

  /// No description provided for @stat_bosses.
  ///
  /// In en, this message translates to:
  /// **'Bosses beaten'**
  String get stat_bosses;

  /// No description provided for @stat_stars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get stat_stars;

  /// No description provided for @stat_powerups.
  ///
  /// In en, this message translates to:
  /// **'Power-ups collected'**
  String get stat_powerups;

  /// No description provided for @stat_perfect.
  ///
  /// In en, this message translates to:
  /// **'Three-star levels'**
  String get stat_perfect;

  /// No description provided for @ach_firstBlood.
  ///
  /// In en, this message translates to:
  /// **'First blood'**
  String get ach_firstBlood;

  /// No description provided for @achDesc_firstBlood.
  ///
  /// In en, this message translates to:
  /// **'Defeat {n} enemy'**
  String achDesc_firstBlood(int n);

  /// No description provided for @ach_firstWin.
  ///
  /// In en, this message translates to:
  /// **'First victory'**
  String get ach_firstWin;

  /// No description provided for @achDesc_firstWin.
  ///
  /// In en, this message translates to:
  /// **'Win {n} battle'**
  String achDesc_firstWin(int n);

  /// No description provided for @ach_bomber.
  ///
  /// In en, this message translates to:
  /// **'Bomber'**
  String get ach_bomber;

  /// No description provided for @achDesc_bomber.
  ///
  /// In en, this message translates to:
  /// **'Place {n} bombs'**
  String achDesc_bomber(int n);

  /// No description provided for @ach_demolition.
  ///
  /// In en, this message translates to:
  /// **'Demolition crew'**
  String get ach_demolition;

  /// No description provided for @achDesc_demolition.
  ///
  /// In en, this message translates to:
  /// **'Destroy {n} crates'**
  String achDesc_demolition(int n);

  /// No description provided for @ach_collector.
  ///
  /// In en, this message translates to:
  /// **'Collector'**
  String get ach_collector;

  /// No description provided for @achDesc_collector.
  ///
  /// In en, this message translates to:
  /// **'Collect {n} power-ups'**
  String achDesc_collector(int n);

  /// No description provided for @ach_chapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter one'**
  String get ach_chapter;

  /// No description provided for @achDesc_chapter.
  ///
  /// In en, this message translates to:
  /// **'Clear {n} levels'**
  String achDesc_chapter(int n);

  /// No description provided for @ach_stars30.
  ///
  /// In en, this message translates to:
  /// **'Star gazer'**
  String get ach_stars30;

  /// No description provided for @achDesc_stars30.
  ///
  /// In en, this message translates to:
  /// **'Collect {n} stars'**
  String achDesc_stars30(int n);

  /// No description provided for @ach_exterminator.
  ///
  /// In en, this message translates to:
  /// **'Exterminator'**
  String get ach_exterminator;

  /// No description provided for @achDesc_exterminator.
  ///
  /// In en, this message translates to:
  /// **'Defeat {n} enemies'**
  String achDesc_exterminator(int n);

  /// No description provided for @ach_champion.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get ach_champion;

  /// No description provided for @achDesc_champion.
  ///
  /// In en, this message translates to:
  /// **'Win {n} battles'**
  String achDesc_champion(int n);

  /// No description provided for @ach_online1.
  ///
  /// In en, this message translates to:
  /// **'Online debut'**
  String get ach_online1;

  /// No description provided for @achDesc_online1.
  ///
  /// In en, this message translates to:
  /// **'Win {n} online match'**
  String achDesc_online1(int n);

  /// No description provided for @ach_boss1.
  ///
  /// In en, this message translates to:
  /// **'Boss slayer'**
  String get ach_boss1;

  /// No description provided for @achDesc_boss1.
  ///
  /// In en, this message translates to:
  /// **'Beat {n} boss'**
  String achDesc_boss1(int n);

  /// No description provided for @ach_perfectionist.
  ///
  /// In en, this message translates to:
  /// **'Perfectionist'**
  String get ach_perfectionist;

  /// No description provided for @achDesc_perfectionist.
  ///
  /// In en, this message translates to:
  /// **'Get three stars on {n} levels'**
  String achDesc_perfectionist(int n);

  /// No description provided for @ach_explorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get ach_explorer;

  /// No description provided for @achDesc_explorer.
  ///
  /// In en, this message translates to:
  /// **'Clear {n} levels'**
  String achDesc_explorer(int n);

  /// No description provided for @ach_online10.
  ///
  /// In en, this message translates to:
  /// **'Online ace'**
  String get ach_online10;

  /// No description provided for @achDesc_online10.
  ///
  /// In en, this message translates to:
  /// **'Win {n} online matches'**
  String achDesc_online10(int n);

  /// No description provided for @ach_bosses4.
  ///
  /// In en, this message translates to:
  /// **'Boss master'**
  String get ach_bosses4;

  /// No description provided for @achDesc_bosses4.
  ///
  /// In en, this message translates to:
  /// **'Beat all {n} bosses'**
  String achDesc_bosses4(int n);

  /// No description provided for @ach_legend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get ach_legend;

  /// No description provided for @achDesc_legend.
  ///
  /// In en, this message translates to:
  /// **'Clear all {n} levels'**
  String achDesc_legend(int n);

  /// No description provided for @powerDetonator.
  ///
  /// In en, this message translates to:
  /// **'Detonator'**
  String get powerDetonator;

  /// No description provided for @powerGhost.
  ///
  /// In en, this message translates to:
  /// **'Ghost'**
  String get powerGhost;

  /// No description provided for @howDetonator.
  ///
  /// In en, this message translates to:
  /// **'Detonator: use the blast button (key E) to set off all your bombs at once.'**
  String get howDetonator;

  /// No description provided for @howGhost.
  ///
  /// In en, this message translates to:
  /// **'Ghost: walk through crates for a few seconds.'**
  String get howGhost;

  /// No description provided for @howBoss.
  ///
  /// In en, this message translates to:
  /// **'Every 25th level ends with a boss. Hit it several times!'**
  String get howBoss;

  /// No description provided for @howStars.
  ///
  /// In en, this message translates to:
  /// **'Earn up to 3 stars per level: no hits taken and plenty of time left. Stars unlock hats, faces and colours.'**
  String get howStars;

  /// No description provided for @detonateButton.
  ///
  /// In en, this message translates to:
  /// **'Detonate bombs'**
  String get detonateButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
