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
  /// **'You have 3 minutes per level and 3 lives.'**
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
