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
  String get botPlayers => 'Botlar';

  @override
  String get startBattle => 'Savaşı başlat';

  @override
  String get battleHint =>
      'Sen ve 1-3 bot savaşırsınız. Arkadaşlarınla farklı cihazlardan oynamak için Çevrimiçi modunu kullan.';

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
  String get howTime =>
      'Hikaye bölümleri süreli (ilerledikçe biraz kısalır) ve 3 canın var.';

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

  @override
  String get wardrobe => 'Gardırop';

  @override
  String get achievements => 'Başarımlar';

  @override
  String worldN(int n) {
    return 'Dünya $n';
  }

  @override
  String starsCount(int n) {
    return '$n yıldız';
  }

  @override
  String get bossLevel => 'PATRON';

  @override
  String levelStart(int n) {
    return 'Bölüm $n';
  }

  @override
  String get mapName0 => 'Neon Arena';

  @override
  String get mapName1 => 'Orman Harabeleri';

  @override
  String get mapName2 => 'Çöl Kumulları';

  @override
  String get mapName3 => 'Buzul Zirvesi';

  @override
  String get mapName4 => 'Lav Demirhanesi';

  @override
  String get mapName5 => 'Derin Okyanus';

  @override
  String get mapName6 => 'Uzay İstasyonu';

  @override
  String get worldStory0 =>
      'Buddy\'ler neon bir eğitim arenasında uyanıyor. İpleri öğrenme zamanı!';

  @override
  String get worldStory1 =>
      'Antik harabelerde hazine sandıkları ve kızgın robotlar saklı.';

  @override
  String get worldStory2 =>
      'Sıcak kum, uzun gölgeler. Robotlar burada hiç uyumuyor.';

  @override
  String get worldStory3 =>
      'Buzla kaplı bir zirve. Gergin sinirler, keskin patlamalar.';

  @override
  String get worldStory4 => 'Demirhane gece gündüz yanıyor. Adımına dikkat!';

  @override
  String get worldStory5 => 'Dalgaların altında robotlar bir üs kurmuş.';

  @override
  String get worldStory6 =>
      'Uzaydaki son istasyon. Artık Buddy\'leri hiçbir şey durduramaz.';

  @override
  String get worldStory7 => 'Yine orman — ama robotlar daha güçlü döndü.';

  @override
  String get worldStory8 => 'Kumullar kayıyor, robotlar çoğalıyor.';

  @override
  String get worldStory9 => 'Son etap. Blast Buddy efsanesi ol!';

  @override
  String achievementUnlocked(String name) {
    return 'Başarım kazanıldı: $name';
  }

  @override
  String get starsEarnedLabel => 'Kazanılan yıldız';

  @override
  String get quickMatch => 'Hızlı maç';

  @override
  String get quick1v1 => '1\'e 1';

  @override
  String get quick4 => '4 kişilik herkes tek';

  @override
  String get quickHint => 'Hemen bir maç bul. Oda dolunca başlarsın.';

  @override
  String get joinByCode => 'Kodla katıl';

  @override
  String get enterCode => 'Oda kodu';

  @override
  String roomCode(String code) {
    return 'Oda kodu: $code';
  }

  @override
  String get copyCode => 'Kodu kopyala';

  @override
  String get codeCopied => 'Kod kopyalandı';

  @override
  String playerLeftMatch(String name) {
    return '$name maçtan ayrıldı';
  }

  @override
  String get emote => 'İfade';

  @override
  String get rematch => 'Tekrar oyna';

  @override
  String get roomNotFoundMsg => 'Bu kodla bir oda yok.';

  @override
  String get floatingStick => 'Serbest joystick';

  @override
  String get floatingStickHint => 'Joystick dokunduğun yerde belirir.';

  @override
  String get leftHanded => 'Solak düzeni';

  @override
  String get botDifficulty => 'Bot zorluğu';

  @override
  String get difficultyEasy => 'Kolay';

  @override
  String get difficultyNormal => 'Normal';

  @override
  String get difficultyHard => 'Zor';

  @override
  String get dailyArena => 'Günün arenası';

  @override
  String get dailyArenaHint => 'Bugün herkes aynı arenada oynuyor.';

  @override
  String get wardrobeHat => 'Şapka';

  @override
  String get wardrobeFace => 'Yüz';

  @override
  String get wardrobeColor => 'Renk';

  @override
  String starsToUnlock(int n) {
    return 'Açmak için $n yıldız';
  }

  @override
  String yourStars(int n) {
    return 'Yıldızların: $n';
  }

  @override
  String get hatName0 => 'Yok';

  @override
  String get hatName1 => 'Kasket';

  @override
  String get hatName2 => 'Parti şapkası';

  @override
  String get hatName3 => 'Kovboy şapkası';

  @override
  String get hatName4 => 'Taç';

  @override
  String get hatName5 => 'Büyücü şapkası';

  @override
  String get hatName6 => 'Hale';

  @override
  String get hatName7 => 'Boynuz';

  @override
  String get faceName0 => 'Klasik';

  @override
  String get faceName1 => 'Mutlu';

  @override
  String get faceName2 => 'Havalı';

  @override
  String get faceName3 => 'Kızgın';

  @override
  String get faceName4 => 'Göz kırpan';

  @override
  String get faceName5 => 'Yıldız göz';

  @override
  String get statsTitle => 'İstatistikler';

  @override
  String get stat_kills => 'Yenilen düşman';

  @override
  String get stat_blocks => 'Patlatılan sandık';

  @override
  String get stat_bombs => 'Konan bomba';

  @override
  String get stat_wins => 'Savaş galibiyeti';

  @override
  String get stat_onlineWins => 'Çevrimiçi galibiyet';

  @override
  String get stat_levels => 'Geçilen bölüm';

  @override
  String get stat_bosses => 'Yenilen patron';

  @override
  String get stat_stars => 'Yıldız';

  @override
  String get stat_powerups => 'Toplanan güçlendirme';

  @override
  String get stat_perfect => 'Üç yıldızlı bölüm';

  @override
  String get ach_firstBlood => 'İlk kan';

  @override
  String achDesc_firstBlood(int n) {
    return '$n düşman yen';
  }

  @override
  String get ach_firstWin => 'İlk zafer';

  @override
  String achDesc_firstWin(int n) {
    return '$n savaş kazan';
  }

  @override
  String get ach_bomber => 'Bombacı';

  @override
  String achDesc_bomber(int n) {
    return '$n bomba koy';
  }

  @override
  String get ach_demolition => 'Yıkım ekibi';

  @override
  String achDesc_demolition(int n) {
    return '$n sandık patlat';
  }

  @override
  String get ach_collector => 'Koleksiyoncu';

  @override
  String achDesc_collector(int n) {
    return '$n güçlendirme topla';
  }

  @override
  String get ach_chapter => 'Birinci bölüm';

  @override
  String achDesc_chapter(int n) {
    return '$n bölüm geç';
  }

  @override
  String get ach_stars30 => 'Yıldız avcısı';

  @override
  String achDesc_stars30(int n) {
    return '$n yıldız topla';
  }

  @override
  String get ach_exterminator => 'Yok edici';

  @override
  String achDesc_exterminator(int n) {
    return '$n düşman yen';
  }

  @override
  String get ach_champion => 'Şampiyon';

  @override
  String achDesc_champion(int n) {
    return '$n savaş kazan';
  }

  @override
  String get ach_online1 => 'Çevrimiçi ilk';

  @override
  String achDesc_online1(int n) {
    return '$n çevrimiçi maç kazan';
  }

  @override
  String get ach_boss1 => 'Patron avcısı';

  @override
  String achDesc_boss1(int n) {
    return '$n patron yen';
  }

  @override
  String get ach_perfectionist => 'Mükemmeliyetçi';

  @override
  String achDesc_perfectionist(int n) {
    return '$n bölümde üç yıldız al';
  }

  @override
  String get ach_explorer => 'Kaşif';

  @override
  String achDesc_explorer(int n) {
    return '$n bölüm geç';
  }

  @override
  String get ach_online10 => 'Çevrimiçi usta';

  @override
  String achDesc_online10(int n) {
    return '$n çevrimiçi maç kazan';
  }

  @override
  String get ach_bosses4 => 'Patron ustası';

  @override
  String achDesc_bosses4(int n) {
    return '$n patronun hepsini yen';
  }

  @override
  String get ach_legend => 'Efsane';

  @override
  String achDesc_legend(int n) {
    return '$n bölümün hepsini geç';
  }

  @override
  String get powerDetonator => 'Patlatıcı';

  @override
  String get powerGhost => 'Hayalet';

  @override
  String get howDetonator =>
      'Patlatıcı: tüm bombalarını aynı anda patlatmak için patlat düğmesine (E tuşu) bas.';

  @override
  String get howGhost => 'Hayalet: birkaç saniye sandıkların içinden geç.';

  @override
  String get howBoss =>
      'Her 25. bölümde bir patron var. Ona birkaç kez isabet ettir!';

  @override
  String get howStars =>
      'Bölüm başına en fazla 3 yıldız kazan: hasar almadan ve bol süreyle bitir. Yıldızlar şapka, yüz ve renk açar.';

  @override
  String get detonateButton => 'Bombaları patlat';
}
