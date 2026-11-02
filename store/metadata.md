# Store metadata (draft)

## Google Play

**Title (30):** Blast Buddies
**Short description (80, en):** Drop bombs, blast crates and outsmart robots in this arcade maze battle!
**Short description (80, tr):** Bomba bırak, sandıkları patlat, robotları alt et: arcade labirent savaşı!

**Full description (en)**
Blast Buddies is a fast, colourful arcade game for one to four players.
Guide your round little buddy through a maze of crates, drop bombs, grab
power-ups and clear every enemy robot before time runs out.

* 12 story levels with rising difficulty: wanderers, chasers and speedsters
* Battle mode: you against 1-3 bots, optional 2 vs 2 teams
* Online battle with friends on their own devices: create a room (optional
  password) for 1v1, 2v2, 3 or 4 player free-for-all, ready up and fight
* Power-ups: extra bombs, longer blasts, speed, shield, bomb kick
* Chain reactions, smooth movement, virtual joystick or keyboard controls
* Available in English and Turkish. No ads, no tracking; story and bot
  battles work offline.

**Full description (tr)**
Blast Buddies bir ile dört oyuncu için hızlı ve renkli bir arcade oyunudur.
Yuvarlak buddy'ni sandık dolu labirentte yönlendir, bomba bırak, güçlendirmeleri
topla ve süre dolmadan tüm robot düşmanları temizle.

* Zorluğu artan 12 hikaye bölümü: gezginler, kovalayanlar ve hızlılar
* Savaş modu: 1-3 bota karşı, istersen 2'ye 2 takım
* Çevrimiçi savaş: arkadaşlarınla kendi cihazlarından; oda kur (isteğe bağlı
  şifre), 1'e 1, 2'ye 2, 3 ya da 4 kişilik herkes tek, hazır ol ve savaş
* Güçlendirmeler: ekstra bomba, uzun patlama, hız, kalkan, bomba tekmeleme
* Zincirleme patlamalar, akıcı hareket, sanal joystick veya klavye
* İngilizce ve Türkçe. Reklam yok, takip yok; hikaye ve bot savaşları
  çevrimdışı çalışır.

**Category:** Games > Arcade  **Content rating:** Everyone 10+ (cartoon violence)
**Data safety:** no data collected or shared (online display name and inputs
are only relayed in real time to other players in the room, not stored).
**Graphics needed:** 512x512 icon (`assets/images/app_icon.png`), 1024x500 feature graphic, 2-8 phone screenshots.

## Apple App Store

**Name:** Blast Buddies  **Subtitle (30):** Bomb maze arcade for friends
**Keywords:** arcade,bomb,maze,multiplayer,online,party,robots,retro,battle,friends
**Promotional text:** Drop bombs, chain explosions and outsmart the robots!
**Description:** same as the Google Play full description.
**Age rating:** 9+ (cartoon/fantasy violence, infrequent/mild)
**Privacy ("App Privacy"):** Data Not Collected. The online display name and
game inputs are processed only in real time and kept in server memory for the
duration of the connection, which Apple does not count as "collected".
**App Review notes:** "Online mode connects to our game server
(wss://blast-buddies-eu.onrender.com). The server may need up to a
minute to wake up on first connect; the app shows 'Waking up the server'. To
test a match, create a 2-player room on one device and join it from a second
device (or simulator). Story and Battle (vs bots) work offline."
Do not use third-party trademarks (e.g. "Bomberman") in name, keywords or
description.
**Support URL / Privacy URL:** _to be filled in_ (host `privacy_policy.md`).
**Screenshots:** 6.7" and 5.5" iPhone sets, 12.9" iPad if iPad is supported.

## Release checklist
- Set final bundle id / applicationId (currently `com.hustunbas.blastbuddies`).
- Create an upload keystore and configure Android signing; configure iOS signing team.
- Replace placeholder audio, update `assets/CREDITS.md`.
- `flutter build appbundle` / `flutter build ipa`.
