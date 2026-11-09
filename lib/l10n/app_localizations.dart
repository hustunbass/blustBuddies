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
  /// **'Move with the joystick.'**
  String get howMove;

  /// No description provided for @howBomb.
  ///
  /// In en, this message translates to:
  /// **'Drop a bomb with the bomb button. It explodes after 3 seconds in a plus shape.'**
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
  /// **'Detonator: use the blast button to set off all your bombs at once.'**
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
  /// **'Earn up to 3 stars per level: finish fast and take as few hits as possible. 2 stars allow one hit, 3 stars need a flawless run and lots of time left. Every new star pays coins.'**
  String get howStars;

  /// No description provided for @detonateButton.
  ///
  /// In en, this message translates to:
  /// **'Detonate bombs'**
  String get detonateButton;

  /// No description provided for @coin.
  ///
  /// In en, this message translates to:
  /// **'Coin'**
  String get coin;

  /// No description provided for @earnCoin.
  ///
  /// In en, this message translates to:
  /// **'Free Coin'**
  String get earnCoin;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Coin shop'**
  String get shopTitle;

  /// No description provided for @shopHint.
  ///
  /// In en, this message translates to:
  /// **'Coins buy hats, faces, colours, emotes and extra lives. No pay-to-win: power-ups are never for sale.'**
  String get shopHint;

  /// No description provided for @adNotReady.
  ///
  /// In en, this message translates to:
  /// **'No ad available right now. Try again in a moment.'**
  String get adNotReady;

  /// No description provided for @rewardGot.
  ///
  /// In en, this message translates to:
  /// **'+{n} Coin!'**
  String rewardGot(int n);

  /// No description provided for @notEnoughCoin.
  ///
  /// In en, this message translates to:
  /// **'Not enough Coin'**
  String get notEnoughCoin;

  /// No description provided for @storeSoon.
  ///
  /// In en, this message translates to:
  /// **'Store is not connected yet.'**
  String get storeSoon;

  /// No description provided for @coinAmount.
  ///
  /// In en, this message translates to:
  /// **'{n} Coin'**
  String coinAmount(int n);

  /// No description provided for @pkgSpark.
  ///
  /// In en, this message translates to:
  /// **'Spark'**
  String get pkgSpark;

  /// No description provided for @pkgFuse.
  ///
  /// In en, this message translates to:
  /// **'Fuse'**
  String get pkgFuse;

  /// No description provided for @pkgDynamite.
  ///
  /// In en, this message translates to:
  /// **'Dynamite'**
  String get pkgDynamite;

  /// No description provided for @pkgDepot.
  ///
  /// In en, this message translates to:
  /// **'Bomb depot'**
  String get pkgDepot;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR'**
  String get mostPopular;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get bestValue;

  /// No description provided for @bonusPercent.
  ///
  /// In en, this message translates to:
  /// **'+{n}% bonus'**
  String bonusPercent(int n);

  /// No description provided for @removeAds.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get removeAds;

  /// No description provided for @removeAdsDesc.
  ///
  /// In en, this message translates to:
  /// **'No more banners or pop-up ads.'**
  String get removeAdsDesc;

  /// No description provided for @unlockFor.
  ///
  /// In en, this message translates to:
  /// **'Unlock for {n} Coin?'**
  String unlockFor(int n);

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch ad'**
  String get watchAd;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @livesOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Out of lives'**
  String get livesOutTitle;

  /// No description provided for @livesOutBody.
  ///
  /// In en, this message translates to:
  /// **'Every story attempt costs a life; you get it back when you win. A new life arrives in {time}.'**
  String livesOutBody(String time);

  /// No description provided for @livesRefillAd.
  ///
  /// In en, this message translates to:
  /// **'Watch ad: +1 life'**
  String get livesRefillAd;

  /// No description provided for @livesRefillCoins.
  ///
  /// In en, this message translates to:
  /// **'Buy 1 life · {n} coins'**
  String livesRefillCoins(int n);

  /// No description provided for @livesWait.
  ///
  /// In en, this message translates to:
  /// **'I\'ll wait'**
  String get livesWait;

  /// No description provided for @livesChipLabel.
  ///
  /// In en, this message translates to:
  /// **'{n} of {max} lives'**
  String livesChipLabel(int n, int max);

  /// No description provided for @achSeries_kills.
  ///
  /// In en, this message translates to:
  /// **'Exterminator'**
  String get achSeries_kills;

  /// No description provided for @achStat_kills.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Defeat 1 enemy} other{Defeat {n} enemies}}'**
  String achStat_kills(int n);

  /// No description provided for @achSeries_blocks.
  ///
  /// In en, this message translates to:
  /// **'Demolition crew'**
  String get achSeries_blocks;

  /// No description provided for @achStat_blocks.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Destroy 1 crate} other{Destroy {n} crates}}'**
  String achStat_blocks(int n);

  /// No description provided for @achSeries_bombs.
  ///
  /// In en, this message translates to:
  /// **'Bomber'**
  String get achSeries_bombs;

  /// No description provided for @achStat_bombs.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Place 1 bomb} other{Place {n} bombs}}'**
  String achStat_bombs(int n);

  /// No description provided for @achSeries_powerups.
  ///
  /// In en, this message translates to:
  /// **'Collector'**
  String get achSeries_powerups;

  /// No description provided for @achStat_powerups.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Collect 1 power-up} other{Collect {n} power-ups}}'**
  String achStat_powerups(int n);

  /// No description provided for @achSeries_levels.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get achSeries_levels;

  /// No description provided for @achStat_levels.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Clear 1 level} other{Clear {n} levels}}'**
  String achStat_levels(int n);

  /// No description provided for @achSeries_stars.
  ///
  /// In en, this message translates to:
  /// **'Star gazer'**
  String get achSeries_stars;

  /// No description provided for @achStat_stars.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Collect 1 star} other{Collect {n} stars}}'**
  String achStat_stars(int n);

  /// No description provided for @achSeries_perfect.
  ///
  /// In en, this message translates to:
  /// **'Perfectionist'**
  String get achSeries_perfect;

  /// No description provided for @achStat_perfect.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Get three stars on 1 level} other{Get three stars on {n} levels}}'**
  String achStat_perfect(int n);

  /// No description provided for @achSeries_bosses.
  ///
  /// In en, this message translates to:
  /// **'Boss slayer'**
  String get achSeries_bosses;

  /// No description provided for @achStat_bosses.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Beat 1 boss} other{Beat {n} bosses}}'**
  String achStat_bosses(int n);

  /// No description provided for @achSeries_wins.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get achSeries_wins;

  /// No description provided for @achStat_wins.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Win 1 battle} other{Win {n} battles}}'**
  String achStat_wins(int n);

  /// No description provided for @achSeries_onlineWins.
  ///
  /// In en, this message translates to:
  /// **'Online ace'**
  String get achSeries_onlineWins;

  /// No description provided for @achStat_onlineWins.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Win 1 online match} other{Win {n} online matches}}'**
  String achStat_onlineWins(int n);

  /// No description provided for @achSeries_onlineGames.
  ///
  /// In en, this message translates to:
  /// **'Online regular'**
  String get achSeries_onlineGames;

  /// No description provided for @achStat_onlineGames.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Play 1 online match} other{Play {n} online matches}}'**
  String achStat_onlineGames(int n);

  /// No description provided for @achSeries_games.
  ///
  /// In en, this message translates to:
  /// **'Veteran'**
  String get achSeries_games;

  /// No description provided for @achStat_games.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Play 1 game} other{Play {n} games}}'**
  String achStat_games(int n);

  /// No description provided for @achSeries_emotes.
  ///
  /// In en, this message translates to:
  /// **'Chatterbox'**
  String get achSeries_emotes;

  /// No description provided for @achStat_emotes.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Send 1 emote} other{Send {n} emotes}}'**
  String achStat_emotes(int n);

  /// No description provided for @achSeries_ads.
  ///
  /// In en, this message translates to:
  /// **'Supporter'**
  String get achSeries_ads;

  /// No description provided for @achStat_ads.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Watch 1 reward ad} other{Watch {n} reward ads}}'**
  String achStat_ads(int n);

  /// No description provided for @achSeries_owned.
  ///
  /// In en, this message translates to:
  /// **'Fashionista'**
  String get achSeries_owned;

  /// No description provided for @achStat_owned.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Own 1 wardrobe item} other{Own {n} wardrobe items}}'**
  String achStat_owned(int n);

  /// No description provided for @achSeries_invites.
  ///
  /// In en, this message translates to:
  /// **'Recruiter'**
  String get achSeries_invites;

  /// No description provided for @achStat_invites.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Invite 1 friend} other{Invite {n} friends}}'**
  String achStat_invites(int n);

  /// No description provided for @achSeries_streak.
  ///
  /// In en, this message translates to:
  /// **'Streak keeper'**
  String get achSeries_streak;

  /// No description provided for @achStat_streak.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Play 1 day in a row} other{Play {n} days in a row}}'**
  String achStat_streak(int n);

  /// No description provided for @achClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get achClaim;

  /// No description provided for @achClaimAll.
  ///
  /// In en, this message translates to:
  /// **'Claim all'**
  String get achClaimAll;

  /// No description provided for @achReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to claim'**
  String get achReady;

  /// No description provided for @achInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get achInProgress;

  /// No description provided for @achDone.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get achDone;

  /// No description provided for @achReward.
  ///
  /// In en, this message translates to:
  /// **'{n} coins'**
  String achReward(int n);

  /// No description provided for @wardrobeEmotes.
  ///
  /// In en, this message translates to:
  /// **'Emotes'**
  String get wardrobeEmotes;

  /// No description provided for @boostWatchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch ad: start with {n} bombs'**
  String boostWatchAd(int n);

  /// No description provided for @boostReady.
  ///
  /// In en, this message translates to:
  /// **'Your next match starts with {n} bombs'**
  String boostReady(int n);

  /// No description provided for @boostBadge.
  ///
  /// In en, this message translates to:
  /// **'starts with {n} bombs'**
  String boostBadge(int n);

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editName;

  /// No description provided for @randomName.
  ///
  /// In en, this message translates to:
  /// **'Random name'**
  String get randomName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @nameRule.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} letters, numbers, spaces, _ . -'**
  String nameRule(int min, int max);

  /// No description provided for @nameInvalid.
  ///
  /// In en, this message translates to:
  /// **'This name is not allowed.'**
  String get nameInvalid;

  /// No description provided for @accountGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest account'**
  String get accountGuest;

  /// No description provided for @accountApple.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Apple'**
  String get accountApple;

  /// No description provided for @accountGoogle.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google'**
  String get accountGoogle;

  /// No description provided for @starterTitle.
  ///
  /// In en, this message translates to:
  /// **'Starter pack'**
  String get starterTitle;

  /// No description provided for @starterBody.
  ///
  /// In en, this message translates to:
  /// **'{coins} coins + all lives refilled'**
  String starterBody(int coins);

  /// No description provided for @starterEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends in {time}'**
  String starterEnds(String time);

  /// No description provided for @firstBuyBonus.
  ///
  /// In en, this message translates to:
  /// **'First purchase: +{n} bonus coins'**
  String firstBuyBonus(int n);

  /// No description provided for @storeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The store is not available right now.'**
  String get storeUnavailable;

  /// No description provided for @productMissing.
  ///
  /// In en, this message translates to:
  /// **'This product is not available yet.'**
  String get productMissing;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. You were not charged.'**
  String get purchaseFailed;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @purchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'Restoring purchases…'**
  String get purchasesRestored;

  /// No description provided for @adsRemovedThanks.
  ///
  /// In en, this message translates to:
  /// **'Ads removed. Thank you!'**
  String get adsRemovedThanks;

  /// No description provided for @purchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get purchased;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @dailyLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily reward'**
  String get dailyLoginTitle;

  /// No description provided for @dayN.
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String dayN(int n);

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1-day streak} other{{n}-day streak}}'**
  String streakDays(int n);

  /// No description provided for @dailyQuests.
  ///
  /// In en, this message translates to:
  /// **'Today\'s quests'**
  String get dailyQuests;

  /// No description provided for @dailyAllDone.
  ///
  /// In en, this message translates to:
  /// **'All quests done: +{n} coins'**
  String dailyAllDone(int n);

  /// No description provided for @dailyComeBack.
  ///
  /// In en, this message translates to:
  /// **'Collected – come back tomorrow'**
  String get dailyComeBack;

  /// No description provided for @dailyReset.
  ///
  /// In en, this message translates to:
  /// **'New quests every day at midnight.'**
  String get dailyReset;

  /// No description provided for @quickParty.
  ///
  /// In en, this message translates to:
  /// **'{n}-player party'**
  String quickParty(int n);

  /// No description provided for @controlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize controls'**
  String get controlsTitle;

  /// No description provided for @controlsHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the joystick and the bomb button to where your thumbs feel best.'**
  String get controlsHint;

  /// No description provided for @controlsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get controlsReset;

  /// No description provided for @controlsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get controlsDone;

  /// No description provided for @achievementToastTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked'**
  String get achievementToastTitle;

  /// No description provided for @howRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get howRules;

  /// No description provided for @howPowerUps.
  ///
  /// In en, this message translates to:
  /// **'Power-ups'**
  String get howPowerUps;

  /// No description provided for @quickDuelDesc.
  ///
  /// In en, this message translates to:
  /// **'A fast, tense duel'**
  String get quickDuelDesc;

  /// No description provided for @quickBrawlDesc.
  ///
  /// In en, this message translates to:
  /// **'The classic four-way brawl'**
  String get quickBrawlDesc;

  /// No description provided for @quickPartyDesc.
  ///
  /// In en, this message translates to:
  /// **'Chaos with up to seven buddies'**
  String get quickPartyDesc;

  /// No description provided for @shopPacks.
  ///
  /// In en, this message translates to:
  /// **'Coin packs'**
  String get shopPacks;

  /// No description provided for @firstBuyNote.
  ///
  /// In en, this message translates to:
  /// **'Your first pack pays a bonus.'**
  String get firstBuyNote;

  /// No description provided for @firstBuyChip.
  ///
  /// In en, this message translates to:
  /// **'+{n} bonus coins'**
  String firstBuyChip(int n);

  /// No description provided for @hatName8.
  ///
  /// In en, this message translates to:
  /// **'Beanie'**
  String get hatName8;

  /// No description provided for @hatName9.
  ///
  /// In en, this message translates to:
  /// **'Chef hat'**
  String get hatName9;

  /// No description provided for @hatName10.
  ///
  /// In en, this message translates to:
  /// **'Pirate hat'**
  String get hatName10;

  /// No description provided for @hatName11.
  ///
  /// In en, this message translates to:
  /// **'Viking helmet'**
  String get hatName11;

  /// No description provided for @hatName12.
  ///
  /// In en, this message translates to:
  /// **'Cat ears'**
  String get hatName12;

  /// No description provided for @hatName13.
  ///
  /// In en, this message translates to:
  /// **'Bunny ears'**
  String get hatName13;

  /// No description provided for @hatName14.
  ///
  /// In en, this message translates to:
  /// **'Top hat'**
  String get hatName14;

  /// No description provided for @hatName15.
  ///
  /// In en, this message translates to:
  /// **'Daisy'**
  String get hatName15;

  /// No description provided for @hatName16.
  ///
  /// In en, this message translates to:
  /// **'Headphones'**
  String get hatName16;

  /// No description provided for @hatName17.
  ///
  /// In en, this message translates to:
  /// **'Propeller cap'**
  String get hatName17;

  /// No description provided for @hatName18.
  ///
  /// In en, this message translates to:
  /// **'Santa hat'**
  String get hatName18;

  /// No description provided for @hatName19.
  ///
  /// In en, this message translates to:
  /// **'Ninja band'**
  String get hatName19;

  /// No description provided for @hatName20.
  ///
  /// In en, this message translates to:
  /// **'Flame hair'**
  String get hatName20;

  /// No description provided for @hatName21.
  ///
  /// In en, this message translates to:
  /// **'Jester hat'**
  String get hatName21;

  /// No description provided for @hatName22.
  ///
  /// In en, this message translates to:
  /// **'Laurel wreath'**
  String get hatName22;

  /// No description provided for @hatName23.
  ///
  /// In en, this message translates to:
  /// **'Rainbow afro'**
  String get hatName23;

  /// No description provided for @faceName6.
  ///
  /// In en, this message translates to:
  /// **'Sleepy'**
  String get faceName6;

  /// No description provided for @faceName7.
  ///
  /// In en, this message translates to:
  /// **'Surprised'**
  String get faceName7;

  /// No description provided for @faceName8.
  ///
  /// In en, this message translates to:
  /// **'Heart eyes'**
  String get faceName8;

  /// No description provided for @faceName9.
  ///
  /// In en, this message translates to:
  /// **'Silly'**
  String get faceName9;

  /// No description provided for @faceName10.
  ///
  /// In en, this message translates to:
  /// **'Robot visor'**
  String get faceName10;

  /// No description provided for @faceName11.
  ///
  /// In en, this message translates to:
  /// **'Cyclops'**
  String get faceName11;

  /// No description provided for @tutTitle0.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get tutTitle0;

  /// No description provided for @tutBody0.
  ///
  /// In en, this message translates to:
  /// **'Drag the joystick to the glowing spot.'**
  String get tutBody0;

  /// No description provided for @tutTitle1.
  ///
  /// In en, this message translates to:
  /// **'Drop a bomb'**
  String get tutTitle1;

  /// No description provided for @tutBody1.
  ///
  /// In en, this message translates to:
  /// **'Stand next to the crate and tap the bomb button.'**
  String get tutBody1;

  /// No description provided for @tutTitle2.
  ///
  /// In en, this message translates to:
  /// **'Run!'**
  String get tutTitle2;

  /// No description provided for @tutBody2.
  ///
  /// In en, this message translates to:
  /// **'The bomb explodes after 3 seconds in a plus shape. Get out of its line!'**
  String get tutBody2;

  /// No description provided for @tutTitle3.
  ///
  /// In en, this message translates to:
  /// **'Power-up!'**
  String get tutTitle3;

  /// No description provided for @tutBody3.
  ///
  /// In en, this message translates to:
  /// **'Crates hide power-ups. Walk over it to collect it.'**
  String get tutBody3;

  /// No description provided for @tutTitle4.
  ///
  /// In en, this message translates to:
  /// **'Beat the enemy'**
  String get tutTitle4;

  /// No description provided for @tutBody4.
  ///
  /// In en, this message translates to:
  /// **'Wait for it to come close, drop a bomb and run. Don\'t get caught in your own blast!'**
  String get tutBody4;

  /// No description provided for @tutTitle5.
  ///
  /// In en, this message translates to:
  /// **'You\'re ready!'**
  String get tutTitle5;

  /// No description provided for @tutBody5.
  ///
  /// In en, this message translates to:
  /// **'Defeat every enemy, then step on the exit door. Earn up to 3 stars on each level.'**
  String get tutBody5;

  /// No description provided for @tutTooFar.
  ///
  /// In en, this message translates to:
  /// **'That was too far away. Try again right next to the crate.'**
  String get tutTooFar;

  /// No description provided for @tutSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutSkip;

  /// No description provided for @tutDoneStart.
  ///
  /// In en, this message translates to:
  /// **'Start the story'**
  String get tutDoneStart;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome, buddy!'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Learn the basics in under a minute and get {n} coins.'**
  String welcomeBody(int n);

  /// No description provided for @welcomeStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get welcomeStart;

  /// No description provided for @welcomeSkip.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get welcomeSkip;

  /// No description provided for @howToTutorial.
  ///
  /// In en, this message translates to:
  /// **'Play the tutorial'**
  String get howToTutorial;
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
