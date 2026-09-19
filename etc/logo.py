# Quest Accept logo: the quest giver's gold "!" on a rolled parchment scroll,
# with a green check badge at the corner for the hand-in. Drawn at 4x and
# downsampled.
#
# Writes into ../assets:
#   logo.png  1024x1024, project art (repo-only, not shipped)
#   logo.tga  64x64 addon-list icon (## IconTexture in the .toc)
# TGA because the classic clients load it on every build; PNG garbled.
import os
from PIL import Image, ImageDraw, ImageFilter, ImageChops

OUT = 1024
S = 4
W = OUT * S
ASSETS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")

def P(x, y):  # design coords in 0..1024 -> canvas
    return (x * S, y * S)

def glow(size, shapes, color, blur):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for kind, args in shapes:
        getattr(d, kind)(*args, fill=color)
    return layer.filter(ImageFilter.GaussianBlur(blur * S))

def lighter(col, k):
    return tuple(min(255, int(c + (255 - c) * k)) for c in col)

def darker(col, k):
    return tuple(int(c * (1 - k)) for c in col)

img = Image.new("RGBA", (W, W), (0, 0, 0, 0))

# --- background: rounded square, deep forest green with a lighter core
grad = Image.radial_gradient("L").resize((W, W))            # 0 center -> 255 edge
inner = Image.new("RGBA", (W, W), (40, 82, 52, 255))
outer = Image.new("RGBA", (W, W), (12, 30, 20, 255))
bg = Image.composite(outer, inner, grad)
mask = Image.new("L", (W, W), 0)
ImageDraw.Draw(mask).rounded_rectangle([P(0, 0), P(1024, 1024)], radius=190 * S, fill=255)
bg.putalpha(mask)
img.alpha_composite(bg)

# --- scroll: a parchment sheet with a rolled tube top and bottom
PARCH = (232, 210, 160)
ROLL = (206, 176, 120)
sl, sr = 252, 772          # sheet edges
st, sb = 236, 812          # sheet top/bottom (under the rolls)
img.alpha_composite(glow((W, W), [("rectangle", ([P(sl - 10, st - 20), P(sr + 10, sb + 40)],))], (0, 0, 0, 160), 30))
d = ImageDraw.Draw(img)
d.rectangle([P(sl, st), P(sr, sb)], fill=PARCH)
# soft shading down the sheet's edges
shade = Image.new("RGBA", (W, W), (0, 0, 0, 0))
sd = ImageDraw.Draw(shade)
sd.rectangle([P(sl, st), P(sl + 40, sb)], fill=(120, 90, 50, 70))
sd.rectangle([P(sr - 40, st), P(sr, sb)], fill=(120, 90, 50, 70))
shade = shade.filter(ImageFilter.GaussianBlur(14 * S))
img.alpha_composite(shade)
d = ImageDraw.Draw(img)
# faint ruled lines, as on a quest text page
for ly in range(430, 760, 46):
    d.line([P(sl + 70, ly), P(sr - 70, ly)], fill=(160, 130, 80, 80), width=4 * S)
# rolls, a little wider than the sheet, with an end cap each side
for cy in (st, sb):
    box = [P(sl - 36, cy - 44), P(sr + 36, cy + 44)]
    img.alpha_composite(glow((W, W), [("rounded_rectangle", (box,))], (0, 0, 0, 120), 10))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(box, radius=44 * S, fill=ROLL)
    d.rounded_rectangle([P(sl - 36, cy - 44), P(sr + 36, cy - 14)], radius=20 * S, fill=lighter(ROLL, 0.25))
    d.rounded_rectangle([P(sl - 36, cy + 16), P(sr + 36, cy + 44)], radius=20 * S, fill=darker(ROLL, 0.2))
    for cx in (sl - 36, sr + 36):
        d.ellipse([P(cx - 30, cy - 44), P(cx + 30, cy + 44)], fill=darker(ROLL, 0.35), outline=lighter(ROLL, 0.2), width=5 * S)
        d.ellipse([P(cx - 12, cy - 18), P(cx + 12, cy + 18)], fill=darker(ROLL, 0.55))

# --- the "!": the quest-available marker, gold with a warm glow
GOLD = (255, 209, 64)
ex, top, bot = 512, 300, 690
bar = [P(ex - 46, top), P(ex + 46, bot - 130)]
dot = [P(ex - 52, bot - 90), P(ex + 52, bot + 14)]
img.alpha_composite(glow((W, W), [("rounded_rectangle", (bar,)), ("ellipse", (dot,))], (255, 190, 40, 170), 34))
d = ImageDraw.Draw(img)
# outline in dark brown so it reads on the parchment, then the fill
o = 12
d.rounded_rectangle([P(ex - 46 - o, top - o), P(ex + 46 + o, bot - 130 + o)], radius=(46 + o) * S, fill=(92, 60, 20, 255))
d.ellipse([P(ex - 52 - o, bot - 90 - o), P(ex + 52 + o, bot + 14 + o)], fill=(92, 60, 20, 255))
d.rounded_rectangle(bar, radius=46 * S, fill=GOLD)
d.ellipse(dot, fill=GOLD)
# highlight strip down the left of the bar and a glint on the dot
d.rounded_rectangle([P(ex - 30, top + 16), P(ex - 8, bot - 150)], radius=11 * S, fill=lighter(GOLD, 0.5))
d.ellipse([P(ex - 34, bot - 76), P(ex - 6, bot - 48)], fill=lighter(GOLD, 0.6))

# --- check badge: green disc in a gold ring, a tick, for the turn-in
bx, by, br = 780, 760, 130
img.alpha_composite(glow((W, W), [("ellipse", ([P(bx - br, by - br), P(bx + br, by + br)],))], (60, 200, 90, 150), 28))
d = ImageDraw.Draw(img)
d.ellipse([P(bx - br, by - br), P(bx + br, by + br)], fill=(38, 140, 66, 255), outline=(255, 226, 150, 255), width=12 * S)
d.line([P(bx - 62, by + 4), P(bx - 16, by + 52), P(bx + 66, by - 52)], fill=(255, 255, 255, 255), width=30 * S, joint="curve")
for cx, cy in ((bx - 62, by + 4), (bx - 16, by + 52), (bx + 66, by - 52)):
    d.ellipse([P(cx - 15, cy - 15), P(cx + 15, cy + 15)], fill=(255, 255, 255, 255))

final = img.resize((OUT, OUT), Image.LANCZOS)
final.save(os.path.join(ASSETS, "logo.png"))

# uncompressed 32-bit, top-left origin, same layout as the stock icons
final.resize((64, 64), Image.LANCZOS).save(os.path.join(ASSETS, "logo.tga"), format="TGA", rle=False, orientation=-1)
print("ok")
