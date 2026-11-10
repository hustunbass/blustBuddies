#!/usr/bin/env python3
"""Landscape key art for App Store Connect (header and search-result assets).

    python3 tool/shots/make_art.py <raw_dir> <out_dir>

Uses a real gameplay capture (<raw_dir>/iphone_en/battle_3.png) in a card and
draws the app's three robots as vector shapes.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

AVENIR = '/System/Library/Fonts/Avenir Next.ttc'
HEAVY, MEDIUM = 8, 5
NAVY_TOP, NAVY_BOT = (62, 40, 128), (22, 28, 52)
GOLD, WHITE = (255, 201, 60), (255, 255, 255)
ROBOTS = [(41, 182, 246), (240, 98, 146), (102, 187, 106)]  # blue, pink, green

# (width, height, folder, file)
OUTPUTS = [
    (5244, 2950, 'header', 'header_5244x2950.png'),
    (3840, 1646, 'header', 'header_3840x1646.png'),
    (3840, 2560, 'search-result', 'search_3840x2560.png'),
    (1920, 1280, 'search-result', 'search_1920x1280.png'),
]


def font(size, weight):
    return ImageFont.truetype(AVENIR, int(size), index=weight)


def gradient(w, h):
    img = Image.new('RGB', (w, h))
    d = ImageDraw.Draw(img)
    for x in range(w):
        t = min(1, x / w * 0.8 + 0.0)
        d.line([(x, 0), (x, h)], fill=tuple(int(NAVY_TOP[i] + (NAVY_BOT[i] - NAVY_TOP[i]) * t) for i in range(3)))
    return img


def glow(img):
    w, h = img.size
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for fx, fy, fr, col in [(0.08, 0.10, 0.45, (255, 120, 100, 80)), (0.80, 0.85, 0.50, (90, 130, 255, 70)),
                            (0.95, 0.10, 0.30, (170, 90, 255, 70))]:
        r = int(h * fr)
        cx, cy = int(w * fx), int(h * fy)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)
    layer = layer.filter(ImageFilter.GaussianBlur(h * 0.10))
    return Image.alpha_composite(img.convert('RGBA'), layer)


def robot(d, color):
    s = 4
    big = d * s
    im = Image.new('RGBA', (big, int(big * 1.30)), (0, 0, 0, 0))
    g = ImageDraw.Draw(im)
    top = int(big * 0.22)
    # shadow
    g.ellipse([big * 0.12, top + big * 0.92, big * 0.88, top + big * 1.06], fill=(0, 0, 0, 90))
    # body
    g.ellipse([0, top, big, top + big], fill=color + (255,))
    g.arc([big * 0.06, top + big * 0.06, big * 0.94, top + big * 0.94], 200, 300, fill=(255, 255, 255, 80), width=int(big * 0.03))
    # visor
    vw, vh = big * 0.72, big * 0.32
    vx, vy = (big - vw) / 2, top + big * 0.30
    g.rounded_rectangle([vx, vy, vx + vw, vy + vh], vh / 2, fill=(245, 245, 250, 255))
    for ex in (-0.17, 0.17):
        cx, cy, r = big / 2 + ex * big, vy + vh / 2, big * 0.05
        g.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(40, 40, 55, 255))
    # antenna
    ax = big / 2
    g.line([ax, top + big * 0.02, ax, top - big * 0.14], fill=(190, 195, 205, 255), width=int(big * 0.04))
    r = big * 0.06
    g.ellipse([ax - r, top - big * 0.14 - r, ax + r, top - big * 0.14 + r], fill=(255, 82, 82, 255))
    return im.resize((d, int(d * 1.30)), Image.LANCZOS)


def rounded_mask(size, radius):
    s = 4
    m = Image.new('L', (size[0] * s, size[1] * s), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] * s - 1, size[1] * s - 1], radius * s, fill=255)
    return m.resize(size, Image.LANCZOS)


TEXT = {
    'en': ('Bomber Party', ('Drop bombs. Chain explosions.', 'Beat your friends.')),
    'tr': ('Bomba Partisi', ('Bomba bırak. Zincirleme patlamalar.', 'Arkadaşlarını yen.')),
}


def card(raw, height, lang):
    """Gameplay card: HUD + arena of a real capture, rounded and tilted."""
    shot = Image.open(os.path.join(raw, f'iphone_{lang}', 'battle_3.png')).convert('RGB')
    crop = shot.crop((0, 175, shot.width, 1500))  # HUD + arena, no joystick
    w = int(height * crop.width / crop.height)
    crop = crop.resize((w, height), Image.LANCZOS)
    r = int(height * 0.06)
    pad = int(height * 0.025)
    body = Image.new('RGBA', (w + 2 * pad, height + 2 * pad), (0, 0, 0, 0))
    body.paste(Image.new('RGBA', body.size, (16, 16, 24, 255)), (0, 0), rounded_mask(body.size, r + pad))
    body.paste(crop, (pad, pad), rounded_mask(crop.size, r))
    return body


def compose(raw, W, H, lang):
    img = glow(gradient(W, H))
    d = ImageDraw.Draw(img)

    # right: tilted gameplay card
    wide = W / H > 2
    ch = int(H * (0.62 if wide else 0.56))
    c = card(raw, ch, lang)
    tilt = c.rotate(-5, resample=Image.BICUBIC, expand=True)
    cx = int(W * (0.745 if wide else 0.775) - tilt.width / 2)
    cy = int(H * 0.52 - tilt.height / 2)
    sh = Image.new('RGBA', img.size, (0, 0, 0, 0))
    sh.paste(Image.new('RGBA', tilt.size, (0, 0, 0, 170)), (cx + int(H * 0.02), cy + int(H * 0.035)), tilt.split()[3])
    img = Image.alpha_composite(img, sh.filter(ImageFilter.GaussianBlur(H * 0.03)))
    img.alpha_composite(tilt, (cx, cy))

    # left: title block
    d = ImageDraw.Draw(img)
    left = int(W * 0.065)
    fs = H * 0.20
    ft = font(fs, HEAVY)
    while d.textlength('Boom Pals', font=ft) > W * 0.46:
        fs -= 4
        ft = font(fs, HEAVY)
    y = int(H * 0.17)
    d.text((left + 6, y + 8), 'Boom Pals', font=ft, fill=(0, 0, 0, 100))
    d.text((left, y), 'Boom Pals', font=ft, fill=WHITE)
    y += int(fs * 1.12)
    fg = font(fs * 0.50, HEAVY)
    d.text((left, y), TEXT[lang][0], font=fg, fill=GOLD)
    y += int(fs * 0.62)
    fm = font(fs * 0.25, MEDIUM)
    for line in TEXT[lang][1]:
        d.text((left, y), line, font=fm, fill=(255, 226, 218))
        y += int(fs * 0.34)

    # robots
    rd = int(H * (0.17 if wide else 0.19))
    ry = int(H * (0.69 if wide else 0.62))
    for i, col in enumerate(ROBOTS):
        r = robot(rd, col)
        img.alpha_composite(r, (left + i * int(rd * 1.28), ry + (i % 2) * int(rd * 0.06)))
    return img.convert('RGB')


def main():
    raw, out = sys.argv[1], sys.argv[2]
    for lang in TEXT:
        for w, h, folder, name in OUTPUTS:
            os.makedirs(os.path.join(out, lang, folder), exist_ok=True)
            img = compose(raw, w, h, lang)
            assert img.size == (w, h)
            img.save(os.path.join(out, lang, folder, name), optimize=True)
            print('wrote', lang, folder, name)


if __name__ == '__main__':
    main()
