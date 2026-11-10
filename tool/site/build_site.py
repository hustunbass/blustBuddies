#!/usr/bin/env python3
"""Builds the static support / marketing / privacy site into site/.

    python3 tool/site/build_site.py "you@example.com" "Your Name"

The pages are plain HTML (no build step); host the `site/` folder anywhere
(GitHub Pages, Netlify, ...). The privacy page is generated from
store/privacy_policy.md.
"""
import html
import os
import re
import shutil
import sys

from PIL import Image

EMAIL = sys.argv[1] if len(sys.argv) > 1 else '[EMAIL]'
NAME = sys.argv[2] if len(sys.argv) > 2 else '[DEVELOPER NAME]'
OUT = 'site'

CSS = """
:root{--bg:#1b2238;--bg2:#232c4a;--fg:#f3e9e6;--muted:#b9b4c6;--peach:#ffb4a2;--gold:#ffc93c}
*{box-sizing:border-box}
body{margin:0;background:linear-gradient(160deg,#3a2678,#161c34 60%) fixed;color:var(--fg);
font:17px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif}
a{color:var(--peach)}
header,main,footer{max-width:880px;margin:0 auto;padding:0 20px}
header{display:flex;justify-content:space-between;align-items:center;padding-top:22px;padding-bottom:10px}
header a.logo{font-weight:800;font-size:22px;color:#fff;text-decoration:none}
nav a{margin-left:18px;text-decoration:none;color:var(--fg)}
h1{font-size:clamp(38px,8vw,64px);line-height:1.05;margin:28px 0 8px;color:#fff}
h1 em{color:var(--gold);font-style:normal;display:block}
h2{margin-top:38px;color:#fff}
h3{color:var(--gold)}
.lead{font-size:20px;color:var(--muted);max-width:620px}
.card{background:rgba(255,255,255,.06);border-radius:18px;padding:18px 22px;margin:14px 0}
.shots{display:flex;gap:14px;overflow-x:auto;padding:12px 0 18px}
.shots img{height:440px;border-radius:22px;box-shadow:0 10px 30px rgba(0,0,0,.45)}
.btn{display:inline-block;background:var(--peach);color:#4a1d10;font-weight:700;padding:12px 24px;border-radius:999px;text-decoration:none}
.soon{color:var(--muted);margin-left:12px}
ul{padding-left:22px}
footer{padding-top:30px;padding-bottom:50px;color:var(--muted);font-size:14px}
.lang{color:var(--muted)}
"""

SHELL = """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title}</title><meta name="description" content="{desc}">
<style>{css}</style></head><body>
<header><a class="logo" href="index.html">Boom Pals</a>
<nav><a href="index.html">Home</a><a href="support.html">Support</a><a href="privacy.html">Privacy</a></nav></header>
<main>{body}</main>
<footer>&copy; 2026 {name}</footer>
</body></html>
"""


def page(fn, title, desc, body):
    with open(os.path.join(OUT, fn), 'w', encoding='utf-8') as f:
        f.write(SHELL.format(title=html.escape(title), desc=html.escape(desc), css=CSS, body=body, name=html.escape(NAME)))


def shots():
    os.makedirs(os.path.join(OUT, 'img'), exist_ok=True)
    out = []
    for lang_dir, tag in (('en', 'en'),):
        for n in ('01_menu', '02_battle', '03_room', '04_levels', '05_wardrobe'):
            src = f'store/screenshots/iphone-6.3/{lang_dir}/{n}.png'
            if not os.path.exists(src):
                continue
            im = Image.open(src).convert('RGB')
            im = im.resize((330, int(330 * im.height / im.width)), Image.LANCZOS)
            dst = f'img/{tag}_{n}.jpg'
            im.save(os.path.join(OUT, dst), quality=86)
            out.append(dst)
    return out


def md_to_html(md):
    out, in_list = [], False
    for raw in md.splitlines():
        line = raw.rstrip()
        if in_list and not line.startswith('* '):
            out.append('</ul>')
            in_list = False
        if not line or line == '---':
            continue
        if line.startswith('# '):
            out.append(f'<h1 style="font-size:36px">{inline(line[2:])}</h1>')
        elif line.startswith('## '):
            out.append(f'<h2>{inline(line[3:])}</h2>')
        elif line.startswith('* '):
            if not in_list:
                out.append('<ul>')
                in_list = True
            out.append(f'<li>{inline(line[2:])}</li>')
        else:
            out.append(f'<p>{inline(line)}</p>')
    if in_list:
        out.append('</ul>')
    return '\n'.join(out)


def inline(t):
    t = html.escape(t)
    t = re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)', r'<a href="\2">\1</a>', t)
    t = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', t)
    t = re.sub(r'_([^_]+)_', r'<em>\1</em>', t)
    return t


def main():
    shutil.rmtree(OUT, ignore_errors=True)
    os.makedirs(OUT)
    imgs = shots()
    gallery = '<div class="shots">' + ''.join(f'<img src="{i}" alt="Boom Pals screenshot">' for i in imgs) + '</div>'

    index = f"""
<h1>Boom Pals<em>Bomber Party</em></h1>
<p class="lead">Drop bombs, chain explosions and outsmart the robots. A fast, colourful arcade maze game for you and up to 6 friends online.</p>
<p><span class="btn">Coming soon to the App Store</span></p>
{gallery}
<h2>Features</h2>
<div class="card"><ul>
<li>100 story levels in 10 worlds, 3-star ratings and a boss every 25 levels</li>
<li>Battle bots (easy, normal, hard), 2 vs 2 teams and a daily arena</li>
<li>Online battles for up to 7 players: Quick match, room codes, password rooms and emotes</li>
<li>Rejoin a running online match if your connection drops</li>
<li>Wardrobe with hats, faces and colours, daily quests and achievements</li>
<li>7 power-ups: extra bombs, longer blasts, speed, shield, bomb kick, detonator and ghost</li>
<li>English and Turkish</li>
</ul></div>
<p>Free to play, with ads and optional in-app purchases. Story and bot battles work offline.</p>

<h2 id="tr">Türkçe</h2>
<p class="lead">Bomba bırak, zincirleme patlamalar yap ve robotları alt et. Hızlı ve renkli bir arcade labirent oyunu: tek başına ya da 7 kişiye kadar çevrimiçi arkadaşlarınla.</p>
<div class="card"><ul>
<li>10 dünyada 100 hikaye bölümü, 3 yıldız puanı ve her 25 bölümde bir patron</li>
<li>Botlara karşı savaş (kolay, normal, zor), 2'ye 2 takım ve günün arenası</li>
<li>7 oyuncuya kadar çevrimiçi savaş: Hızlı maç, oda kodu, şifreli oda ve emojiler</li>
<li>Bağlantın koparsa çevrimiçi maça geri dön</li>
<li>Gardırop, günlük görevler ve başarımlar; 7 güçlendirme</li>
</ul></div>
<p>Ücretsizdir; reklam ve isteğe bağlı uygulama içi satın alımlar içerir. Hikaye ve bot savaşları çevrimdışı çalışır.</p>
<p><a href="support.html">Support / Destek</a> &middot; <a href="privacy.html">Privacy / Gizlilik</a></p>
"""
    page('index.html', 'Boom Pals: Bomber Party', 'Fast, colourful arcade maze game. Drop bombs, chain explosions and battle friends online.', index)

    support = f"""
<h1 style="font-size:40px">Support</h1>
<p class="lead">Need help with Boom Pals? Write to <a href="mailto:{EMAIL}">{EMAIL}</a> and we will answer as soon as we can. Please include your device model, iOS version and what happened.</p>
<h2>Frequently asked questions</h2>
<div class="card"><h3>How do I restore my purchases?</h3>
<p>Open the shop (cart button on the main menu) and tap <strong>Restore purchases</strong>. This brings back "Remove ads". Coins are consumable and cannot be restored by the store.</p></div>
<div class="card"><h3>Where is my progress stored?</h3>
<p>Progress, coins and cosmetics are stored on your device only. Deleting the app removes them unless your device backup restores the app data. Use the same device backup when switching phones.</p></div>
<div class="card"><h3>Online mode does not connect or takes a long time.</h3>
<p>The game server may need up to a minute to wake up if nobody played for a while; the app shows "Waking up the server". If it still fails, check your internet connection and try again.</p></div>
<div class="card"><h3>My connection dropped during an online match.</h3>
<p>Stay in the match screen: the game tries to reconnect for about 25 seconds and your pal keeps its seat for 30 seconds.</p></div>
<div class="card"><h3>I want to remove ads.</h3>
<p>Buy <strong>Remove ads</strong> in the shop. Optional rewarded ads (for coins and bonuses) stay available.</p></div>
<div class="card"><h3>I was charged but did not receive my coins.</h3>
<p>Restart the app and open the shop once; the store delivers pending purchases. If coins are still missing, email us the order number from Apple's receipt.</p></div>
<h2 id="tr">Destek (Türkçe)</h2>
<p>Yardıma mı ihtiyacın var? <a href="mailto:{EMAIL}">{EMAIL}</a> adresine yaz; cihaz modelini, iOS sürümünü ve olanı belirt. Satın alımları geri yüklemek için mağazadaki <strong>Satın alımları geri yükle</strong> düğmesini kullan. İlerleme ve jetonlar yalnızca cihazında saklanır. Çevrimiçi bağlantı bir dakikaya kadar uyanma süresi gerektirebilir; kopma durumunda oyun yaklaşık 25 saniye yeniden bağlanmayı dener.</p>
"""
    page('support.html', 'Boom Pals Support', 'Help, FAQ and contact for Boom Pals.', support)

    policy = open('store/privacy_policy.md', encoding='utf-8').read()
    policy = policy.replace('[DEVELOPER NAME] — [EMAIL]', f'{NAME} — {EMAIL}').replace('[GELİŞTİRİCİ ADI] — [E-POSTA]', f'{NAME} — {EMAIL}')
    en, tr = policy.split('\n---\n', 1)
    body = md_to_html(en) + '<hr id="tr" style="border-color:#ffffff22;margin:40px 0">' + md_to_html(tr)
    page('privacy.html', 'Boom Pals Privacy Policy', 'Privacy policy for Boom Pals.', body)
    # AdMob: authorises Google to sell this app's ads (publisher id from lib/core/ads/ad_config.dart).
    with open(os.path.join(OUT, 'app-ads.txt'), 'w') as f:
        f.write('google.com, pub-9207046302495275, DIRECT, f08c47fec0942fa0\n')
    print('built', OUT, sorted(os.listdir(OUT)))


main()
