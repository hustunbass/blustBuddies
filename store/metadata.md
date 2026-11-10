# Store metadata

Working title in code/bundle id: `blast_buddies` / `com.hustunbas.blastbuddies`.
Store name: **Boom Pals**. Check that the name is free in App Store Connect and
Play Console before creating the listing, and search USPTO / TÜRKPATENT for
"BOOM PALS" in class 9 (games). Do not use third-party trademarks (e.g.
"Bomberman") in name, subtitle, keywords or description. Another game called
"Blast Buddies" exists, so never use that name or its look.

## Apple App Store

| Field | EN | TR |
|---|---|---|
| Name (30) | Boom Pals: Bomber Party | Boom Pals: Bomba Partisi |
| Subtitle (30) | Online arcade maze for friends | Arkadaşlarla çevrimiçi labirent |
| Keywords (100) | `bomb,multiplayer,battle,robots,casual,pvp,strategy,classic,retro,explosion,crates,blast` | `bomba,patlama,çok oyunculu,eğlence,robot,arcade,strateji,klasik,retro,sandık,2 kişilik,savaş` |
| Promotional text (170) | Drop bombs, chain explosions and outsmart the robots! Battle friends online with up to 7 players. | Bomba bırak, zincirleme patlamalar yap ve robotları alt et! Arkadaşlarınla 7 kişiye kadar çevrimiçi savaş. |

Name, subtitle and keywords are indexed together: do not repeat a word across
them. **Category:** Games → Arcade (secondary: Action). **Price:** Free.

**What's New** (not asked for the first release, 1.0.0; use it from the first update on)
- EN: Rejoin your online match if the connection drops, smoother online play, plus a refreshed economy, daily quests, wardrobe and tutorial.
- TR: Bağlantın koparsa çevrimiçi maça geri dönebilirsin, daha akıcı çevrimiçi oyun, ayrıca yenilenen ekonomi, günlük görevler, gardırop ve öğretici.

**Description (EN)**
```
Boom Pals is a fast, colourful arcade game. Guide your round little pal through a maze of crates, drop bombs, grab power-ups and clear every enemy robot before time runs out.

• 100 story levels in 10 worlds with a gentle difficulty curve, 3-star ratings and a boss every 25 levels
• Battle mode: take on 1-3 bots (easy, normal, hard), play 2 vs 2 teams or try the daily arena
• Online battle with friends on their own devices: create a room (optional password), hit Quick match or share a room code. Play 1v1, 2v2 or free-for-all with up to 7 players, and send emotes
• Rejoin a running online match if your connection drops
• Wardrobe: collect hats, faces and colours for your pal
• Daily quests, achievements and statistics
• 7 power-ups: extra bombs, longer blasts, speed, shield, bomb kick, detonator and ghost
• Chain reactions, smooth movement and a joystick you can move and resize
• Available in English and Turkish

Boom Pals is free to play. It contains ads and optional in-app purchases (coin packs, a starter pack and a one-time "Remove ads"). Story and bot battles work offline.
```

**Description (TR)**
```
Boom Pals hızlı ve renkli bir arcade oyunudur. Yuvarlak pal'ini sandık dolu labirentte yönlendir, bomba bırak, güçlendirmeleri topla ve süre dolmadan tüm robot düşmanları temizle.

• 10 dünyada 100 hikaye bölümü, yumuşak zorluk eğrisi, 3 yıldız puanı ve her 25 bölümde bir patron
• Savaş modu: 1-3 bota karşı (kolay, normal, zor), 2'ye 2 takım ya da günün arenası
• Çevrimiçi savaş: arkadaşlarınla kendi cihazlarından; oda kur (isteğe bağlı şifre), Hızlı maç'a bas ya da oda kodu paylaş. 1'e 1, 2'ye 2 veya 7 kişiye kadar herkes tek, ayrıca emoji gönder
• Bağlantın koparsa çevrimiçi maça geri dön
• Gardırop: pal'in için şapka, yüz ve renk topla
• Günlük görevler, başarımlar ve istatistikler
• 7 güçlendirme: ekstra bomba, uzun patlama, hız, kalkan, bomba tekmeleme, patlatıcı ve hayalet
• Zincirleme patlamalar, akıcı hareket, taşıyıp boyutlandırabildiğin joystick
• İngilizce ve Türkçe

Boom Pals ücretsizdir. Reklam ve isteğe bağlı uygulama içi satın alımlar içerir (jeton paketleri, başlangıç paketi ve tek seferlik "Reklamları kaldır"). Hikaye ve bot savaşları çevrimdışı çalışır.
```

**Age rating:** 9+ (cartoon/fantasy violence, infrequent/mild; no chat, no
user-generated content, no gambling).

**App Privacy:** Data is collected because of Google AdMob; tracking = Yes (ATT).
Declare, per Google's AdMob guidance (re-check it before submitting): Device ID,
Advertising Data, Product Interaction and Coarse Location for third-party
advertising / analytics (linked, used for tracking); Crash/Performance/Other
diagnostics for app functionality (not linked, no tracking). The online display
name, look and game input are only relayed in real time and kept in server
memory while connected, which Apple does not count as collected. Purchases are
handled by Apple; the app stores no purchase history on a server.

**In-app purchases**

| Product ID | Type | Display name (EN / TR) | Price (TR) |
|---|---|---|---|
| `coin_500` | Consumable | 500 Coins / 500 Jeton | ₺29,99 |
| `coin_1500` | Consumable | 1500 Coins / 1500 Jeton | ₺69,99 |
| `coin_4000` | Consumable | 4000 Coins / 4000 Jeton | ₺149,99 |
| `coin_10000` | Consumable | 10000 Coins / 10000 Jeton | ₺329,99 |
| `starter_pack` | Consumable | Starter Pack / Başlangıç Paketi | ₺39,99 |
| `remove_ads` | Non-consumable | Remove Ads / Reklamları Kaldır | ₺99,99 |

Pick the nearest Apple price point. Each product needs a review screenshot.

**App Review notes**
```
No account is needed. Story and Battle (vs bots) work offline.

Online mode connects to our game server (wss://blast-buddies-eu.onrender.com). The server is on a free hosting plan and may need up to a minute to wake up on first connect; the app shows "Waking up the server" meanwhile. To test a match: tap Online -> Connect, create a 2-player room on one device and join it from a second device or simulator, then tap Ready on both. "Quick match" with two devices works too.

Ads: Google AdMob (banners in menus, an interstitial after story levels, optional rewarded ads). The app shows the App Tracking Transparency prompt and Google's consent form (UMP). Players can decline and still play.

In-app purchases: coin packs, a one-time starter pack and a non-consumable "Remove ads" (with Restore purchases in the shop). Online emotes are preset emoji only; there is no free-text chat or user-generated content.
```
Open `https://blast-buddies-eu.onrender.com/health` shortly before submitting so
the server is awake.

**Export compliance:** `ITSAppUsesNonExemptEncryption = false` (HTTPS/WSS only).
**IDFA:** Yes, to serve ads; no install or ad-action attribution.
**Support URL:** https://boompals.hakan9007.workers.dev/support
**Marketing URL:** https://boompals.hakan9007.workers.dev/
**Privacy Policy URL:** https://boompals.hakan9007.workers.dev/privacy
(Static site in `site/`, built by `tool/site/build_site.py`, hosted on Cloudflare;
`app-ads.txt` for AdMob is served from the same root.)
**Screenshots:** 6.9" iPhone (1320×2868) and 13" iPad (2064×2752); the app
supports both.

## Google Play

**Title (30):** Boom Pals: Bomber Party
**Short description (80, en):** Drop bombs, blast crates and outsmart robots in this arcade maze battle!
**Short description (80, tr):** Bomba bırak, sandıkları patlat, robotları alt et: arcade labirent savaşı!
**Full description:** same as the App Store description.
**Category:** Games > Arcade  **Content rating:** Everyone 10+ (cartoon violence)
**Data safety:** declares AdMob data (device or other IDs, app interactions,
approximate location, crash logs/diagnostics) for advertising/analytics; the
online display name and inputs are only relayed in real time.
**Graphics needed:** 512x512 icon (`assets/images/app_icon.png`), 1024x500
feature graphic, 2-8 phone screenshots.

## Release checklist
- Confirm the name "Boom Pals" is free (stores, USPTO, TÜRKPATENT, domain).
- Set final bundle id / applicationId if you do not want
  `com.hustunbas.blastbuddies` (it cannot change after the first upload).
- Create an upload keystore and configure Android signing; configure iOS signing team.
- Android AdMob: real app id in `AndroidManifest.xml` and units in `AdConfig.androidUnits`.
- Create the IAP products in both consoles and test purchase and restore.
- Privacy policy is published at the URL above; rebuild and redeploy `site/` after
  changing `store/privacy_policy.md`.
- Replace placeholder audio, update `assets/CREDITS.md`.
- Deploy the latest server before submitting.
- `flutter build appbundle` / `flutter build ipa`.
