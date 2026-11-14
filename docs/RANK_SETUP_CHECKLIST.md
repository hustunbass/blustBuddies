# Rank sistemi: senden istenenler (sırayla)

Bu listeyi yukarıdan aşağı yap. Her maddenin yanında **bana ne vereceğin** yazıyor.
Gizli anahtarları (service key, secret) bana yazma: onları doğrudan Render
paneline gir. Bana sadece "Bana ver" yazan açık değerleri ver.

## 1. Supabase (veritabanı + giriş altyapısı)
- [ ] https://supabase.com adresinde hesap aç, **New project** oluştur.
  - Bölge: **Europe (Frankfurt)** (oyun sunucusuyla aynı bölge, hızlı olur).
  - Veritabanı şifresini bir yere kaydet (bana gerekmiyor).
- [ ] **SQL Editor**'ü aç, [supabase/schema.sql](../supabase/schema.sql) dosyasının tamamını yapıştırıp **Run** de.
- [ ] Projenin sayfasında üstteki **Connect** butonuna bas:
  - **Project URL** (`https://xxxx.supabase.co`) → *Bana ver.*
  - **Publishable key** (`sb_publishable_...`, eski adıyla anon key) → *Bana ver.* (herkese açık anahtar, uygulamaya da konacak)
- [ ] Soldan **Settings → API Keys** → "Publishable and secret API keys" sekmesi:
  - **Secret key** (`sb_secret_...`, eski adıyla service_role) → *Bana verme.* Sadece 6. adımda Render'a gireceksin.
- Not: Panelde "Settings → API" diye ayrı sayfa artık yok. Eski `eyJ...` anahtarları "Legacy" sekmesinde, yenilerini kullanıyoruz.

## 2. Google ile giriş
- [ ] https://console.cloud.google.com → proje seç ya da oluştur.
- [ ] **APIs & Services → OAuth consent screen**: External, uygulama adı *Boom Pals*, destek e-postan, gizlilik politikası: `https://boompals.hakan9007.workers.dev/privacy`.
- [ ] **Credentials → Create credentials → OAuth client ID** ile üç tane oluştur:
  1. **Web application** → *Bana ver:* Client ID. Client secret'ı sadece Supabase'e gireceksin (3. adım).
  2. **iOS**, bundle id `com.hustunbas.blastbuddies` → *Bana ver:* iOS Client ID ve `REVERSED_CLIENT_ID` değeri.
  3. **Android**, package `com.hustunbas.blastbuddies`, **SHA-1** parmak izi ister (bkz. 4. adım). *Bana ver:* Android Client ID.

## 3. Supabase'te sağlayıcıları aç
- [ ] **Authentication → Providers → Google**: aç, Web Client ID ve secret'ı gir. **"Skip nonce checks"** seçeneğini **aç** (uygulama Google'dan nonce'suz token alıyor).
- [ ] **Authentication → Providers → Email**: **kapat** (uygulamada e-posta girişi yok; açık kalırsa API üzerinden sahte hesap açılabilir).
- [ ] **Authentication → Providers → Apple**: aç; **Client IDs** alanına bundle id'yi yaz: `com.hustunbas.blastbuddies` (iOS'ta uygulama içi giriş için yeterli).
- [ ] **Authentication → URL Configuration → Redirect URLs**: `com.hustunbas.blastbuddies://login-callback` ekle.

## 4. Apple ile giriş
- [ ] https://developer.apple.com → **Identifiers → App IDs → com.hustunbas.blastbuddies** → **Sign in with Apple** yeteneğini işaretle, kaydet.
- [ ] Gerekirse provisioning profilini yenile (Xcode otomatik imzalıyorsa kendiliğinden olur).
- Not: Google girişi sunduğumuz için Apple **Sign in with Apple**'ı da zorunlu tutuyor. İkisi de olacak.

## 5. Android imzalama anahtarı (zaten eksikti, Google için de gerekli)
- [ ] Upload keystore oluştur (bir kez):
  `keytool -genkey -v -keystore ~/boompals-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`
  Şifreleri ve dosyayı güvenli yerde sakla, **kaybedersen Play'e güncelleme veremezsin**.
- [ ] SHA-1 parmak izini al: `keytool -list -v -keystore ~/boompals-upload.jks -alias upload` → bunu 2. adımdaki Android client'a gir. Play Console'da **App signing** SHA-1'ini de aynı şekilde ekle (ikisi ayrı client olabilir).
- [ ] *Bana ver:* keystore'un **yolu** (şifreyi yazma). `key.properties` dosyasını ben bağlarım, şifreleri sen o dosyaya yazarsın.

## 6. Sunucu (Render)
- [ ] Render panelinde `blast-buddies-eu` servisi → **Environment** → şu üç değişkeni ekle:
  - `SUPABASE_URL` = Project URL
  - `SUPABASE_ANON_KEY` = publishable key
  - `SUPABASE_SERVICE_KEY` = secret key (`sb_secret_...`)  ← sadece buraya
- [ ] Servisi yeniden deploy et. Log'da `ranked play: ON (Supabase)` yazmalı.
- [ ] **Karar ver:** ücretsiz plan uyuyor, ilk bağlantıda ~1 dk uyanma süresi rank'lı maçta kötü deneyim. Aylık yaklaşık 7 $ olan Starter plana geçmek rank için önerilir.

## 7. Yayın (rank güncellemesi çıkmadan önce)
- [ ] App Store Connect **App Privacy**: hesap kimliği (e-posta, kullanıcı id) ve oyun sonuçları eklenecek. Metni ben hazırlarım, sen forma girersin.
- [ ] Play Console **Data safety**: aynı şekilde.
- [ ] Gizlilik politikası güncellemesi: taslağı ben yazarım, sen onaylarsın.
- [ ] Apple review notları: ranked için test hesabı yerine "Sign in with Apple ile test edilebilir, hesapsız oynanabilir" notu yazarım.

## Durum
- [x] Supabase projesi, şema, Project URL ve publishable key tamam (bana verdin).
- [x] Uygulamada Apple/Google giriş kodu yazıldı (branch `feature/ranked`). Apple, Supabase'te Apple sağlayıcısı açılınca çalışır. Google, aşağıdaki Client ID'ler gelince açılır (o zamana kadar Google butonu görünmez).

## Bana vereceklerin (özet)
1. ~~Supabase Project URL~~ (alındı)
2. ~~Supabase publishable key~~ (alındı)
3. Google **Web Client ID**
4. Google **iOS Client ID** + **REVERSED_CLIENT_ID**
5. Google **Android Client ID**
6. Android upload keystore'un **yolu**
7. Render'da planı yükseltip yükseltmeyeceğin (evet/hayır)

Hepsini bir kerede göndermen gerekmiyor. 1 ve 2'yi alınca uygulama tarafındaki
girişi yazmaya başlayabilirim.
