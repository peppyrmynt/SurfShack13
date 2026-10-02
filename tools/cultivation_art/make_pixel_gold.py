"""Crisp pixel-art Golden Bell, Dharma Idol and Buddha's Palm (64x64)."""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from pixel import save_dmi, harden, outline, soft_glow, compose
from PIL import Image, ImageDraw

OUT = 'surfshack13/icons/cultivation/'
GOLD = (236, 186, 64)
GOLD_LIGHT = (255, 226, 132)
GOLD_PALE = (255, 244, 196)
GOLD_DARK = (168, 112, 28)
GOLD_DEEP = (110, 66, 16)
LINE = (88, 50, 12, 255)

def rgba(c, a=255):
    return c + (a,)

# ---------------- Golden Bell (translucent dome, ripple frames) ----------------
def bell(phase):
    im = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    body_alpha = 120
    # bell silhouette: knob, shoulder, flared lip
    shape = [(22, 14), (42, 14), (46, 20), (48, 42), (54, 54), (10, 54), (16, 42), (18, 20)]
    d.polygon(shape, fill=rgba(GOLD, body_alpha))
    d.rectangle((28, 6, 36, 14), fill=rgba(GOLD, 170))
    d.ellipse((26, 3, 38, 10), outline=rgba(GOLD_DARK, 230))
    # bands
    for y in (22, 34, 46):
        half = 15 + (y - 22) * 0.35
        d.line((32 - half, y, 32 + half, y), fill=rgba(GOLD_DARK, 200))
    # studs
    for x in range(22, 44, 5):
        d.point((x, 27), fill=rgba(GOLD_PALE, 230)); d.point((x, 28), fill=rgba(GOLD_DARK, 200))
    # lip
    d.line((10, 54, 54, 54), fill=rgba(GOLD_DARK, 240), width=2)
    # moving shine band
    sy = 16 + int(36 * phase)
    half = 13 + (sy - 16) * 0.35
    d.line((32 - half, sy, 32 + half, sy), fill=rgba(GOLD_PALE, 170))
    d.line((32 - half + 2, sy + 1, 32 + half - 2, sy + 1), fill=rgba(GOLD_LIGHT, 110))
    # left edge highlight
    d.line((19, 20, 17, 42), fill=rgba(GOLD_PALE, 180))
    # outline (keep it crisp but over a translucent body)
    for (x1, y1), (x2, y2) in zip(shape, shape[1:] + shape[:1]):
        d.line((x1, y1, x2, y2), fill=rgba(GOLD_DEEP, 255))
    glow = soft_glow((64, 64), [('polygon', shape)], (255, 214, 90), 3, int(70 + 50 * (math.sin(phase * 2 * math.pi) + 1) / 2))
    return compose(glow, im)

# ---------------- Dharma Idol (seated Buddha, rotating sunburst halo) ----------------
def idol(phase):
    body = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(body)
    # lotus base
    for i, x in enumerate(range(8, 56, 8)):
        d.pieslice((x - 1, 50, x + 9, 62), 180, 360, fill=rgba((222, 118, 140) if i % 2 else (236, 150, 170)))
    d.rectangle((7, 56, 57, 62), fill=rgba((196, 96, 120)))
    # crossed legs and robe
    d.ellipse((10, 40, 54, 58), fill=rgba(GOLD))
    d.arc((14, 44, 50, 56), 200, 340, fill=rgba(GOLD_DARK))
    # torso
    d.polygon([(23, 22), (41, 22), (47, 46), (17, 46)], fill=rgba(GOLD))
    d.line((24, 24, 40, 44), fill=rgba(GOLD_DARK))
    d.line((40, 24, 45, 44), fill=rgba(GOLD_LIGHT))
    # hands in dhyana mudra
    d.ellipse((24, 40, 40, 47), fill=rgba(GOLD_LIGHT))
    d.arc((24, 40, 40, 47), 0, 180, fill=rgba(GOLD_DARK))
    # head
    d.rectangle((29, 19, 35, 23), fill=rgba(GOLD))
    d.ellipse((24, 7, 40, 23), fill=rgba(GOLD))
    d.ellipse((28, 2, 36, 10), fill=rgba(GOLD_DARK))
    for p in ((30, 4), (33, 4), (31, 6), (34, 7), (29, 7)):
        d.point(p, fill=rgba(GOLD))
    # ears
    d.rectangle((22, 12, 24, 21), fill=rgba(GOLD)); d.rectangle((40, 12, 42, 21), fill=rgba(GOLD))
    # serene face
    d.line((27, 15, 30, 15), fill=rgba(GOLD_DEEP)); d.line((34, 15, 37, 15), fill=rgba(GOLD_DEEP))
    d.point((32, 11), fill=rgba(GOLD_PALE))
    d.line((30, 19, 34, 19), fill=rgba(GOLD_DEEP))
    # face highlight
    d.line((26, 10, 26, 18), fill=rgba(GOLD_LIGHT))
    body = outline(harden(body), LINE)
    # halo with rotating rays
    halo = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    cx, cy = 32, 22
    for k in range(16):
        a = math.radians(k * 22.5 + phase * 22.5)
        hd.line((cx + math.cos(a) * 13, cy + math.sin(a) * 13, cx + math.cos(a) * 21, cy + math.sin(a) * 21), fill=rgba(GOLD_LIGHT, 170 if k % 2 else 110), width=2)
    hd.ellipse((cx - 13, cy - 13, cx + 13, cy + 13), outline=rgba(GOLD_PALE, 220), width=2)
    glow = soft_glow((64, 64), [('ellipse', (8, 0, 56, 46))], (255, 210, 100), 4, 90)
    glow.alpha_composite(halo)
    return compose(glow, body)

# ---------------- Buddha's Palm (crisp, with dharma wheel) ----------------
def palm(color=GOLD, light=GOLD_LIGHT, dark=GOLD_DARK, line=LINE, wheel=True):
    body = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(body)
    # palm block
    d.rounded_rectangle((14, 26, 48, 58), 8, fill=rgba(color))
    # fingers
    for x, top in ((15, 9), (23, 4), (31, 3), (39, 7)):
        d.rounded_rectangle((x, top, x + 7, 32), 3, fill=rgba(color))
        d.line((x + 1, top + 3, x + 1, 30), fill=rgba(light))
        d.line((x, top + 12, x + 7, top + 12), fill=rgba(dark))
    # thumb
    d.rounded_rectangle((44, 30, 58, 40), 4, fill=rgba(color))
    d.line((46, 31, 56, 31), fill=rgba(light))
    # palm crease and shading
    d.arc((18, 34, 40, 54), 200, 330, fill=rgba(dark))
    d.line((15, 30, 15, 54), fill=rgba(light))
    if wheel:
        d.ellipse((24, 38, 38, 52), outline=rgba(GOLD_PALE))
        d.ellipse((29, 43, 33, 47), fill=rgba(GOLD_PALE))
        for k in range(8):
            a = math.radians(k * 45)
            d.line((31 + math.cos(a) * 2, 45 + math.sin(a) * 2, 31 + math.cos(a) * 6, 45 + math.sin(a) * 6), fill=rgba(GOLD_PALE))
    return outline(harden(body), line)

def palm_glow():
    body = palm()
    glow = soft_glow((64, 64), [('ellipse', (6, 0, 60, 62))], (255, 214, 90), 4, 120)
    return compose(glow, body)

def palm_shadow():
    shadow = palm(color=(0, 0, 0), light=(0, 0, 0), dark=(0, 0, 0), line=(0, 0, 0, 255), wheel=False)
    px = shadow.load()
    for y in range(64):
        for x in range(64):
            if px[x, y][3]:
                px[x, y] = (0, 0, 0, 255)
    return shadow

# Rewrite cultivation_effects_64.dmi, keeping water_bubble and void_rift from the old file
old = Image.open(OUT + 'cultivation_effects_64.dmi')
desc = old.info.get('Description', '')
def old_frames(state_name):
    # walk the DMI description to find frame indexes
    idx = 0
    cols = old.width // 64
    for block in desc.split('state = ')[1:]:
        name = block.split('"')[1]
        frames = int(block.split('frames = ')[1].split('\n')[0])
        if name == state_name:
            return [old.crop(((i % cols) * 64, (i // cols) * 64, (i % cols) * 64 + 64, (i // cols) * 64 + 64)) for i in range(idx, idx + frames)]
        idx += frames
    raise KeyError(state_name)

water = old_frames('water_bubble')
void = old_frames('void_rift')
save_dmi(OUT + 'cultivation_effects_64.dmi', [
    ('golden_bell', [bell(i / 8) for i in range(8)], 1),
    ('water_bubble', water, 2),
    ('buddha_palm', [palm_glow()], 1),
    ('buddha_palm_shadow', [palm_shadow()], 1),
    ('void_rift', void, 1),
], (64, 64))
save_dmi(OUT + 'dharma_idol.dmi', [('dharma_idol', [idol(i / 4) for i in range(4)], 2)], (64, 64))

if len(sys.argv) > 1:
    prev = Image.new('RGBA', (64 * 6, 64), (60, 62, 70, 255))
    for i, f in enumerate([bell(0), bell(0.5), idol(0), idol(0.5), palm_glow(), palm_shadow()]):
        prev.alpha_composite(f, (64 * i, 0))
    prev.resize((prev.width * 3, prev.height * 3), Image.NEAREST).save(sys.argv[1])
print('ok')
