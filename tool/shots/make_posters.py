#!/usr/bin/env python3
"""Builds the App Store poster screenshots from raw simulator captures.

Raw captures come from `tool/shots/shots_main.dart` (see capture notes in
store/screenshots/README.md). Output goes to store/screenshots/<device>/<lang>/.

    python3 tool/shots/make_posters.py <raw_dir> <out_dir>

<raw_dir> contains iphone_en, iphone_tr, ipad_en, ipad_tr with the PNGs the
capture script produced.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

AVENIR = '/System/Library/Fonts/Avenir Next.ttc'
HEAVY, MEDIUM = 8, 5

# Brand colours (see lib/core/theme.dart): navy base, peach buttons, gold coins.
NAVY_TOP = (58, 38, 120)
NAVY_BOT = (22, 28, 52)
PEACH = (255, 180, 162)
GOLD = (255, 201, 60)
WHITE = (255, 255, 255)

DEVICES = {
    # name: (poster size, screenshot size, device width share, bezel share, corner share)
    'iphone-6.9': ((1320, 2868), 'iphone', 0.80, 0.014, 0.125),
    'iphone-6.3': ((1206, 2622), 'iphone', 0.80, 0.014, 0.125),
    'ipad-13': ((2064, 2752), 'ipad', 0.80, 0.020, 0.052),
}

# (raw file, headline lines, highlighted line index, subline) per language.
POSTERS = {
    'en': [
        ('menu', ['Drop bombs.', 'Beat the bots!'], 1, 'Fast, colourful arcade fun'),
        ('battle_3', ['Chain reactions.', 'Wild blasts!'], 1, 'Smooth, explosive action'),
        ('room', ['Battle up to', '7 friends online'], 1, 'Quick match, room codes and emotes'),
        ('levels', ['100 levels', 'in 10 worlds'], 1, 'Earn 3 stars and beat the bosses'),
        ('wardrobe', ['Dress up', 'your pal'], 1, 'Hats, faces and colours to collect'),
        ('daily', ['Daily quests', '& rewards'], 1, 'Come back every day for coins'),
        ('teams_1', ['2 vs 2', 'team battles'], 1, 'Play with bots or with friends'),
    ],
    'tr': [
        ('menu', ['Bomba bırak,', 'botları yen!'], 1, 'Hızlı ve renkli arcade eğlencesi'),
        ('battle_3', ['Zincirleme', 'patlamalar!'], 1, 'Akıcı ve patlayıcı aksiyon'),
        ('room', ['7 arkadaşınla', 'çevrimiçi savaş'], 1, 'Hızlı maç, oda kodu ve emojiler'),
        ('levels', ['10 dünyada', '100 bölüm'], 1, '3 yıldız topla, patronları yen'),
        ('wardrobe', ["Pal'ini", 'giydir'], 1, 'Şapka, yüz ve renk topla'),
        ('daily', ['Günlük görevler', 've ödüller'], 1, 'Her gün gel, jeton kazan'),
        ('teams_1', ["2'ye 2", 'takım savaşı'], 1, 'Botlarla ya da arkadaşlarınla oyna'),
    ],
}


def font(size, weight):
    return ImageFont.truetype(AVENIR, int(size), index=weight)


def gradient(w, h):
    img = Image.new('RGB', (w, h))
    px = ImageDraw.Draw(img)
    for y in range(h):
        t = y / (h - 1)
        px.line([(0, y), (w, y)], fill=tuple(int(NAVY_TOP[i] + (NAVY_BOT[i] - NAVY_TOP[i]) * t) for i in range(3)))
    return img


def decorate(img, seed):
    """Soft glow blobs so the background is not flat."""
    w, h = img.size
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    spots = [(0.12, 0.14, 0.34, (255, 120, 100, 70)), (0.92, 0.30, 0.30, (120, 90, 255, 80)),
             (0.50, 0.62, 0.50, (60, 160, 255, 45))]
    for k, (fx, fy, fr, col) in enumerate(spots):
        cx, cy = int(w * fx), int(h * fy)
        r = int(w * fr)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)
    layer = layer.filter(ImageFilter.GaussianBlur(w * 0.09))
    return Image.alpha_composite(img.convert('RGBA'), layer)


def rounded_mask(size, radius):
    s = 4
    m = Image.new('L', (size[0] * s, size[1] * s), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] * s - 1, size[1] * s - 1], radius * s, fill=255)
    return m.resize(size, Image.LANCZOS)


def fit_text(draw, text, weight, max_w, start):
    size = start
    while size > 20:
        f = font(size, weight)
        if draw.textlength(text, font=f) <= max_w:
            return f
        size -= 4
    return font(size, weight)


def compose(shot_path, lines, hi, sub, dev):
    (W, H), kind, share, bezel_share, corner_share = DEVICES[dev]
    bg = decorate(gradient(W, H), 1)
    d = ImageDraw.Draw(bg)

    # Headline: both lines share one font size so they look like a block.
    max_w = W * 0.90
    start = W * 0.105
    size = start
    while size > 30 and max(d.textlength(t, font=font(size, HEAVY)) for t in lines) > max_w:
        size -= 4
    fh = font(size, HEAVY)
    y = H * 0.050 if kind == 'iphone' else H * 0.045
    line_h = size * 1.12
    for i, t in enumerate(lines):
        tw = d.textlength(t, font=fh)
        col = GOLD if i == hi else WHITE
        # soft shadow
        d.text(((W - tw) / 2 + 4, y + 6), t, font=fh, fill=(0, 0, 0, 90))
        d.text(((W - tw) / 2, y), t, font=fh, fill=col)
        y += line_h
    fs = fit_text(d, sub, MEDIUM, W * 0.86, size * 0.40)
    sw = d.textlength(sub, font=fs)
    d.text(((W - sw) / 2, y + size * 0.10), sub, font=fs, fill=(255, 226, 218))
    top = int(y + size * 0.10 + fs.size * 1.9)

    # Device: the screenshot in a dark bezel, bleeding off the bottom edge.
    shot = Image.open(shot_path).convert('RGB')
    sw_px = int(W * share)
    sh_px = int(sw_px * shot.height / shot.width)
    shot = shot.resize((sw_px, sh_px), Image.LANCZOS)
    bez = max(8, int(W * bezel_share))
    dev_w, dev_h = sw_px + 2 * bez, sh_px + 2 * bez
    radius = int(sw_px * corner_share)
    body = Image.new('RGBA', (dev_w, dev_h), (0, 0, 0, 0))
    body.paste(Image.new('RGBA', (dev_w, dev_h), (14, 14, 20, 255)), (0, 0), rounded_mask((dev_w, dev_h), radius + bez))
    # thin highlight rim
    rim = Image.new('RGBA', (dev_w, dev_h), (0, 0, 0, 0))
    ImageDraw.Draw(rim).rounded_rectangle([0, 0, dev_w - 1, dev_h - 1], radius + bez, outline=(90, 90, 110, 255), width=max(2, bez // 5))
    body = Image.alpha_composite(body, rim)
    body.paste(shot, (bez, bez), rounded_mask((sw_px, sh_px), radius))

    x = (W - dev_w) // 2
    # shadow
    sh = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([x, top + 30, x + dev_w, top + 30 + dev_h], radius + bez, fill=(0, 0, 0, 150))
    sh = sh.filter(ImageFilter.GaussianBlur(W * 0.025))
    bg = Image.alpha_composite(bg, sh)
    bg.alpha_composite(body, (x, top))
    return bg.convert('RGB')


def main():
    raw, out = sys.argv[1], sys.argv[2]
    for dev, (_, kind, *_rest) in DEVICES.items():
        for lang, posters in POSTERS.items():
            src = os.path.join(raw, f'{kind}_{lang}')
            dst = os.path.join(out, dev, lang)
            os.makedirs(dst, exist_ok=True)
            for n, (name, lines, hi, sub) in enumerate(posters, 1):
                # iPad's bigger arena shows its explosions best a little earlier.
                if kind == 'ipad' and name == 'battle_3':
                    name = 'battle_1'
                path = os.path.join(src, f'{name}.png')
                if not os.path.exists(path):
                    print('missing', path)
                    continue
                img = compose(path, lines, hi, sub, dev)
                target = DEVICES[dev][0]
                assert img.size == target, (img.size, target)
                img.save(os.path.join(dst, f'{n:02d}_{name.split("_")[0]}.png'), optimize=True)
                print('wrote', dev, lang, n)


if __name__ == '__main__':
    main()
