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
  String get howMove => 'Joystick ile hareket et.';

  @override
  String get howBomb =>
      'Bomba butonuyla bomba bırak. 3 saniye sonra artı şeklinde patlar.';

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
  String get cancel => 'Vazgeç';

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
  String get powerDetonator => 'Patlatıcı';

  @override
  String get powerGhost => 'Hayalet';

  @override
  String get howDetonator =>
      'Patlatıcı: tüm bombalarını aynı anda patlatmak için patlat düğmesine bas.';

  @override
  String get howGhost => 'Hayalet: birkaç saniye sandıkların içinden geç.';

  @override
  String get howBoss =>
      'Her 25. bölümde bir patron var. Ona birkaç kez isabet ettir!';

  @override
  String get howStars =>
      'Bölüm başına en fazla 3 yıldız kazan: hızlı bitir ve olabildiğince az hasar al. 2 yıldız bir isabete izin verir, 3 yıldız hatasız ve bol süreyle bitirmeyi ister. Her yeni yıldız coin kazandırır.';

  @override
  String get detonateButton => 'Bombaları patlat';

  @override
  String get coin => 'Coin';

  @override
  String get earnCoin => 'Bedava Coin';

  @override
  String get shopTitle => 'Coin mağazası';

  @override
  String get shopHint =>
      'Coin ile şapka, yüz, renk, emoji ve ekstra can alabilirsin. Güç satışı yok: güçlendirmeler asla satılmaz.';

  @override
  String get adNotReady =>
      'Şu an gösterilecek reklam yok. Birazdan tekrar dene.';

  @override
  String rewardGot(int n) {
    return '+$n Coin!';
  }

  @override
  String get notEnoughCoin => 'Yeterli Coin yok';

  @override
  String get storeSoon => 'Mağaza henüz bağlı değil.';

  @override
  String coinAmount(int n) {
    return '$n Coin';
  }

  @override
  String get pkgSpark => 'Kıvılcım';

  @override
  String get pkgFuse => 'Fitil';

  @override
  String get pkgDynamite => 'Dinamit';

  @override
  String get pkgDepot => 'Bomba deposu';

  @override
  String get mostPopular => 'EN POPÜLER';

  @override
  String get bestValue => 'EN İYİ DEĞER';

  @override
  String bonusPercent(int n) {
    return '%$n bonus';
  }

  @override
  String get removeAds => 'Reklamları kaldır';

  @override
  String get removeAdsDesc => 'Banner ve geçiş reklamları kalkar.';

  @override
  String unlockFor(int n) {
    return '$n Coin karşılığında açılsın mı?';
  }

  @override
  String get buy => 'Satın al';

  @override
  String get watchAd => 'Reklam izle';

  @override
  String get close => 'Kapat';

  @override
  String get livesOutTitle => 'Canların bitti';

  @override
  String livesOutBody(String time) {
    return 'Her hikaye denemesi 1 can harcar; kazanırsan geri alırsın. Yeni can $time sonra geliyor.';
  }

  @override
  String get livesRefillAd => 'Reklam izle: +1 can';

  @override
  String livesRefillCoins(int n) {
    return '1 can al · $n coin';
  }

  @override
  String get livesWait => 'Bekleyeceğim';

  @override
  String livesChipLabel(int n, int max) {
    return '$max candan $n tanesi';
  }

  @override
  String get achSeries_kills => 'Yok Edici';

  @override
  String achStat_kills(int n) {
    return '$n düşman yen';
  }

  @override
  String get achSeries_blocks => 'Yıkım Ekibi';

  @override
  String achStat_blocks(int n) {
    return '$n sandık yık';
  }

  @override
  String get achSeries_bombs => 'Bombacı';

  @override
  String achStat_bombs(int n) {
    return '$n bomba koy';
  }

  @override
  String get achSeries_powerups => 'Koleksiyoncu';

  @override
  String achStat_powerups(int n) {
    return '$n güçlendirme topla';
  }

  @override
  String get achSeries_levels => 'Kaşif';

  @override
  String achStat_levels(int n) {
    return '$n bölüm bitir';
  }

  @override
  String get achSeries_stars => 'Yıldız Avcısı';

  @override
  String achStat_stars(int n) {
    return '$n yıldız topla';
  }

  @override
  String get achSeries_perfect => 'Mükemmeliyetçi';

  @override
  String achStat_perfect(int n) {
    return '$n bölümde üç yıldız al';
  }

  @override
  String get achSeries_bosses => 'Patron Avcısı';

  @override
  String achStat_bosses(int n) {
    return '$n patronu yen';
  }

  @override
  String get achSeries_wins => 'Şampiyon';

  @override
  String achStat_wins(int n) {
    return '$n savaş kazan';
  }

  @override
  String get achSeries_onlineWins => 'Online Usta';

  @override
  String achStat_onlineWins(int n) {
    return '$n online maç kazan';
  }

  @override
  String get achSeries_onlineGames => 'Online Müdavim';

  @override
  String achStat_onlineGames(int n) {
    return '$n online maç oyna';
  }

  @override
  String get achSeries_games => 'Kıdemli';

  @override
  String achStat_games(int n) {
    return '$n oyun oyna';
  }

  @override
  String get achSeries_emotes => 'Geveze';

  @override
  String achStat_emotes(int n) {
    return '$n emoji gönder';
  }

  @override
  String get achSeries_ads => 'Destekçi';

  @override
  String achStat_ads(int n) {
    return '$n ödüllü reklam izle';
  }

  @override
  String get achSeries_owned => 'Şık Buddy';

  @override
  String achStat_owned(int n) {
    return '$n gardırop eşyasına sahip ol';
  }

  @override
  String get achSeries_invites => 'Davetçi';

  @override
  String achStat_invites(int n) {
    return '$n arkadaşını davet et';
  }

  @override
  String get achSeries_streak => 'Seri Ustası';

  @override
  String achStat_streak(int n) {
    return 'Üst üste $n gün oyna';
  }

  @override
  String get achClaim => 'Topla';

  @override
  String get achClaimAll => 'Hepsini topla';

  @override
  String get achReady => 'Toplanmaya hazır';

  @override
  String get achInProgress => 'Devam eden';

  @override
  String get achDone => 'Tamamlanan';

  @override
  String achReward(int n) {
    return '$n coin';
  }

  @override
  String get wardrobeEmotes => 'Emojiler';

  @override
  String boostWatchAd(int n) {
    return 'Reklam izle: $n bombayla başla';
  }

  @override
  String boostReady(int n) {
    return 'Sıradaki maçın $n bombayla başlayacak';
  }

  @override
  String boostBadge(int n) {
    return '$n bombayla başlıyor';
  }

  @override
  String get editName => 'Adı düzenle';

  @override
  String get randomName => 'Rastgele ad';

  @override
  String get save => 'Kaydet';

  @override
  String nameRule(int min, int max) {
    return '$min–$max harf, rakam, boşluk, _ . -';
  }

  @override
  String get nameInvalid => 'Bu ad kullanılamaz.';

  @override
  String get accountGuest => 'Misafir hesabı';

  @override
  String get accountApple => 'Apple ile giriş yapıldı';

  @override
  String get accountGoogle => 'Google ile giriş yapıldı';

  @override
  String get starterTitle => 'Başlangıç paketi';

  @override
  String starterBody(int coins) {
    return '$coins coin + tüm canlar dolu';
  }

  @override
  String starterEnds(String time) {
    return '$time sonra bitiyor';
  }

  @override
  String firstBuyBonus(int n) {
    return 'İlk alım: +$n bonus coin';
  }

  @override
  String get storeUnavailable => 'Mağaza şu an kullanılamıyor.';

  @override
  String get productMissing => 'Bu ürün henüz satışta değil.';

  @override
  String get purchaseFailed => 'Satın alma başarısız. Ücret alınmadı.';

  @override
  String get restorePurchases => 'Satın alımları geri yükle';

  @override
  String get purchasesRestored => 'Satın alımlar geri yükleniyor…';

  @override
  String get adsRemovedThanks => 'Reklamlar kaldırıldı. Teşekkürler!';

  @override
  String get purchased => 'Satın alındı';

  @override
  String get daily => 'Günlük';

  @override
  String get dailyLoginTitle => 'Günlük ödül';

  @override
  String dayN(int n) {
    return '$n. gün';
  }

  @override
  String streakDays(int n) {
    return '$n günlük seri';
  }

  @override
  String get dailyQuests => 'Bugünün görevleri';

  @override
  String dailyAllDone(int n) {
    return 'Tüm görevler tamam: +$n coin';
  }

  @override
  String get dailyComeBack => 'Alındı – yarın tekrar gel';

  @override
  String get dailyReset => 'Her gün gece yarısı yeni görevler gelir.';

  @override
  String quickParty(int n) {
    return '$n kişilik parti';
  }

  @override
  String get controlsTitle => 'Kontrolleri düzenle';

  @override
  String get controlsHint =>
      'Joystick\'i ve bomba butonunu başparmaklarının rahat ettiği yere sürükle.';

  @override
  String get controlsReset => 'Sıfırla';

  @override
  String get controlsDone => 'Bitti';

  @override
  String get achievementToastTitle => 'Başarım kazanıldı';

  @override
  String get howRules => 'Kurallar';

  @override
  String get howPowerUps => 'Güçlendirmeler';

  @override
  String get quickDuelDesc => 'Hızlı ve gergin bir düello';

  @override
  String get quickBrawlDesc => 'Klasik dörtlü kapışma';

  @override
  String get quickPartyDesc => 'Yedi kişiye kadar kaos';

  @override
  String get shopPacks => 'Coin paketleri';

  @override
  String get firstBuyNote => 'İlk paketin bonus kazandırır.';

  @override
  String firstBuyChip(int n) {
    return '+$n bonus coin';
  }

  @override
  String get hatName8 => 'Bere';

  @override
  String get hatName9 => 'Aşçı şapkası';

  @override
  String get hatName10 => 'Korsan şapkası';

  @override
  String get hatName11 => 'Viking miğferi';

  @override
  String get hatName12 => 'Kedi kulağı';

  @override
  String get hatName13 => 'Tavşan kulağı';

  @override
  String get hatName14 => 'Silindir şapka';

  @override
  String get hatName15 => 'Papatya';

  @override
  String get hatName16 => 'Kulaklık';

  @override
  String get hatName17 => 'Pervaneli şapka';

  @override
  String get hatName18 => 'Noel şapkası';

  @override
  String get hatName19 => 'Ninja bandı';

  @override
  String get hatName20 => 'Alev saç';

  @override
  String get hatName21 => 'Soytarı şapkası';

  @override
  String get hatName22 => 'Defne çelengi';

  @override
  String get hatName23 => 'Gökkuşağı afro';

  @override
  String get faceName6 => 'Uykulu';

  @override
  String get faceName7 => 'Şaşkın';

  @override
  String get faceName8 => 'Kalpli gözler';

  @override
  String get faceName9 => 'Komik';

  @override
  String get faceName10 => 'Robot vizörü';

  @override
  String get faceName11 => 'Tek gözlü';

  @override
  String get tutTitle0 => 'Hareket';

  @override
  String get tutBody0 => 'Joystick\'i sürükleyip parlayan noktaya git.';

  @override
  String get tutTitle1 => 'Bomba bırak';

  @override
  String get tutBody1 => 'Sandığın hemen yanında dur ve bomba butonuna bas.';

  @override
  String get tutTitle2 => 'Kaç!';

  @override
  String get tutBody2 =>
      'Bomba 3 saniye sonra artı şeklinde patlar. Çizgisinden çık!';

  @override
  String get tutTitle3 => 'Güçlendirme!';

  @override
  String get tutBody3 =>
      'Sandıklar güçlendirme saklar. Almak için üstünden geç.';

  @override
  String get tutTitle4 => 'Düşmanı yen';

  @override
  String get tutBody4 =>
      'Yaklaşmasını bekle, bomba bırak ve kaç. Kendi patlamana yakalanma!';

  @override
  String get tutTitle5 => 'Hazırsın!';

  @override
  String get tutBody5 =>
      'Tüm düşmanları yen, sonra çıkış kapısına gir. Her bölümde 3 yıldıza kadar kazan.';

  @override
  String get tutTooFar =>
      'Biraz uzak kaldı. Sandığın hemen yanında tekrar dene.';

  @override
  String get tutSkip => 'Atla';

  @override
  String get tutDoneStart => 'Hikayeye başla';

  @override
  String get welcomeTitle => 'Hoş geldin, buddy!';

  @override
  String welcomeBody(int n) {
    return 'Temel bilgileri bir dakikadan kısa sürede öğren ve $n coin kazan.';
  }

  @override
  String get welcomeStart => 'Hadi başlayalım';

  @override
  String get welcomeSkip => 'Sonra';

  @override
  String get howToTutorial => 'Öğreticiyi oyna';
}
