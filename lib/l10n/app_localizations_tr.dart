// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Blast Buddies';

  @override
  String get storyMode => 'Hikaye';

  @override
  String get battleMode => 'Savaş';

  @override
  String get howToPlay => 'Nasıl Oynanır';

  @override
  String get settings => 'Ayarlar';

  @override
  String get selectLevel => 'Bölüm Seç';

  @override
  String levelN(int n) {
    return 'Bölüm $n';
  }

  @override
  String get levelLocked => 'Kilitli';

  @override
  String bestScore(int score) {
    return 'En yüksek skor: $score';
  }

  @override
  String get lives => 'Can';

  @override
  String get score => 'Skor';

  @override
  String get time => 'Süre';

  @override
  String get enemiesLeft => 'Düşman';

  @override
  String get pause => 'Duraklat';

  @override
  String get paused => 'Duraklatıldı';

  @override
  String get resume => 'Devam et';

  @override
  String get restart => 'Yeniden başla';

  @override
  String get mainMenu => 'Ana menü';

  @override
  String get gameOver => 'Oyun bitti';

  @override
  String get levelComplete => 'Bölüm geçildi!';

  @override
  String get allLevelsDone => 'Tüm bölümleri bitirdin!';

  @override
  String get nextLevel => 'Sonraki bölüm';

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String finalScore(int score) {
    return 'Skor: $score';
  }

  @override
  String playerWins(int n) {
    return 'Oyuncu $n kazandı!';
  }

  @override
  String get draw => 'Berabere!';

  @override
  String get playAgain => 'Tekrar oyna';

  @override
  String get sound => 'Ses efektleri';

  @override
  String get music => 'Müzik';

  @override
  String get vibration => 'Titreşim';

  @override
  String get controlSize => 'Kontrol boyutu';

  @override
  String get battleSetup => 'Savaş kurulumu';

  @override
  String get humanPlayers => 'İnsan oyuncular';

  @override
  String get botPlayers => 'Botlar';

  @override
  String get startBattle => 'Savaşı başlat';

  @override
  String get battleHint =>
      'Masaüstünde 1-4. oyuncular aynı klavyeyi paylaşır; telefonda 1. oyuncu dokunmatik kontrolleri kullanır.';

  @override
  String playerN(int n) {
    return 'O$n';
  }

  @override
  String get joystick => 'Hareket joystick\'i';

  @override
  String get bombButton => 'Bomba bırak';

  @override
  String get howMove => 'Joystick (ok tuşları / WASD) ile hareket et.';

  @override
  String get howBomb =>
      'Bomba butonuyla (Boşluk) bomba bırak. 3 saniye sonra artı şeklinde patlar.';

  @override
  String get howBlocks =>
      'Patlama sandıkları yıkar ama çelik duvarlarda durur. Bombalar birbirini tetikler.';

  @override
  String get howEnemies =>
      'Çıkış kapısını açmak için tüm düşmanları yen, sonra kapıya gir. Kovalayanlara ve hızlılara dikkat!';

  @override
  String get howShield => 'Kalkan: birkaç saniye seni korur.';

  @override
  String get powerBomb => 'Fazladan bomba';

  @override
  String get powerRange => 'Daha uzun patlama';

  @override
  String get powerSpeed => 'Hız artışı';

  @override
  String get powerShield => 'Kalkan';

  @override
  String get powerKick => 'Bomba tekmeleme';

  @override
  String get howBattle =>
      'Savaş: ayakta kalan son buddy kazanır. Arkadaşlarınla ya da botlarla oyna.';

  @override
  String get howTime => 'Her bölümde 3 dakikan ve 3 canın var.';

  @override
  String get back => 'Geri';

  @override
  String get language => 'Dil, cihaz ayarlarını izler.';

  @override
  String get onlineMode => 'Çevrimiçi';

  @override
  String get onlineTitle => 'Çevrimiçi savaş';

  @override
  String get yourName => 'Adın';

  @override
  String get serverAddress => 'Özel sunucu adresi';

  @override
  String get serverHint => 'Boş bırak: varsayılan sunucu';

  @override
  String get advanced => 'Gelişmiş';

  @override
  String get serverWaking => 'Sunucu uyanıyor, bu bir dakika kadar sürebilir…';

  @override
  String get onlineHint =>
      'Adını yaz ve bağlan. Oda kurabilir ya da arkadaşlarının kurduğu odalara katılabilirsin.';

  @override
  String get connect => 'Bağlan';

  @override
  String get disconnect => 'Bağlantıyı kes';

  @override
  String get connectFailed => 'Sunucuya bağlanılamadı.';

  @override
  String get connectionLost => 'Bağlantı koptu.';

  @override
  String get rooms => 'Odalar';

  @override
  String get noRooms => 'Henüz oda yok. Bir tane kur!';

  @override
  String get createRoom => 'Oda kur';

  @override
  String get roomName => 'Oda adı';

  @override
  String get playerCount => 'Oyuncu sayısı';

  @override
  String get teamsLabel => 'Takımlı (2’ye 2)';

  @override
  String get passwordOptional => 'Şifre (isteğe bağlı)';

  @override
  String get password => 'Şifre';

  @override
  String get create => 'Kur';

  @override
  String get join => 'Katıl';

  @override
  String get cancel => 'İptal';

  @override
  String get modeDuel => '1’e 1';

  @override
  String get modeTeams => '2’ye 2';

  @override
  String modeFfa(int n) {
    return '$n kişi, herkes tek';
  }

  @override
  String get inGame => 'Oyunda';

  @override
  String get readyLabel => 'Hazır';

  @override
  String get notReady => 'Hazır değil';

  @override
  String get imReady => 'Hazırım!';

  @override
  String get cancelReady => 'Hazırı geri al';

  @override
  String waitingForPlayers(int n, int cap) {
    return 'Oyuncular bekleniyor… ($n/$cap)';
  }

  @override
  String get waitingForReady => 'Herkesin hazır olması bekleniyor…';

  @override
  String startsIn(int n) {
    return '$n sn içinde başlıyor…';
  }

  @override
  String get leaveRoom => 'Odadan çık';

  @override
  String get emptySlot => 'Boş yer';

  @override
  String youTag(String name) {
    return '$name (sen)';
  }

  @override
  String teamN(int n) {
    return 'Takım $n';
  }

  @override
  String teamWins(int n) {
    return 'Takım $n kazandı!';
  }

  @override
  String nameWins(String name) {
    return '$name kazandı!';
  }

  @override
  String get backToRoom => 'Odaya dön';

  @override
  String get leaveMatch => 'Maçtan çık';

  @override
  String get leaveMatchQuestion => 'Maçtan çıkılsın mı?';

  @override
  String get errWrongPassword => 'Yanlış şifre.';

  @override
  String get errRoomFull => 'Oda dolu.';

  @override
  String get errRoomNotFound => 'Oda artık yok.';

  @override
  String get errInProgress => 'Maç zaten başladı.';

  @override
  String get errTooManyAttempts =>
      'Çok fazla hatalı deneme. Bir dakika sonra tekrar dene.';

  @override
  String get errServerFull => 'Sunucu dolu.';

  @override
  String get errVersion => 'Uygulama ve sunucu sürümleri uyumsuz.';

  @override
  String get errGeneric => 'İstek reddedildi.';
}
