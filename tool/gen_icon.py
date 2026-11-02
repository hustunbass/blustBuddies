"""Draws the original Blast Buddies app icon and splash logo (CC0).

Run: python3 tool/gen_icon.py   (needs Pillow)
"""
import os
from PIL import Image, ImageChops, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'images')
os.makedirs(OUT, exist_ok=True)
S = 1024


def buddy(d, cx, cy, r, color):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)
    d.rounded_rectangle([cx - r * .65, cy - r * .45, cx + r * .65, cy + r * .25],
                        radius=r * .3, fill=(236, 239, 241))
    for dx in (-.25, .25):
        e = r * .11
        d.ellipse([cx + r * dx - e, cy - r * .12 - e, cx + r * dx + e, cy - r * .12 + e],
                  fill=(38, 50, 56))
    d.line([cx, cy - r, cx, cy - r * 1.35], fill=(207, 216, 220), width=int(r * .08))
    e = r * .13
    d.ellipse([cx - e, cy - r * 1.35 - e, cx + e, cy - r * 1.35 + e], fill=(255, 82, 82))


def icon(transparent_bg):
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0) if transparent_bg else (27, 34, 56, 255))
    d = ImageDraw.Draw(img)
    # bomb
    d.ellipse([S * .24, S * .4, S * .76, S * .92], fill=(38, 50, 56))
    d.ellipse([S * .33, S * .5, S * .43, S * .6], fill=(120, 140, 150))
    d.line([S * .62, S * .42, S * .7, S * .3], fill=(188, 170, 164), width=22)
    d.ellipse([S * .66, S * .22, S * .78, S * .34], fill=(255, 112, 67))
    buddy(d, S * .5, S * .64, S * .2, (41, 182, 246))
    return ImageChops.offset(img, 0, -int(S * .1))


icon(False).save(os.path.join(OUT, 'app_icon.png'))
# Adaptive foreground: keep content in the central safe zone.
fg = Image.new('RGBA', (S, S), (0, 0, 0, 0))
small = icon(True).resize((int(S * .62), int(S * .62)), Image.LANCZOS)
fg.paste(small, (int(S * .19), int(S * .19)), small)
fg.save(os.path.join(OUT, 'app_icon_foreground.png'))
fg.save(os.path.join(OUT, 'splash_logo.png'))
