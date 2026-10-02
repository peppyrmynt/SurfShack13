"""32px effect sprites: orbiting sword, sword qi crescent (animated), sword qi impact (animated)."""
from PIL import Image, ImageDraw, PngImagePlugin, ImageFilter
import math, sys

OUT = 'surfshack13/icons/cultivation/'
B = 128

def dmi(path, states, size=(32, 32)):
    w, h = size
    flat = []
    desc = f"# BEGIN DMI\nversion = 4.0\n\twidth = {w}\n\theight = {h}\n"
    for name, frames, delay in states:
        desc += f'state = "{name}"\n\tdirs = 1\n\tframes = {len(frames)}\n'
        if len(frames) > 1:
            desc += "\tdelay = " + ",".join([str(delay)] * len(frames)) + "\n"
        flat += frames
    desc += "# END DMI\n"
    cols = min(len(flat), 16)
    rows = math.ceil(len(flat) / cols)
    sheet = Image.new('RGBA', (w * cols, h * rows), (0, 0, 0, 0))
    for i, im in enumerate(flat):
        sheet.paste(im, ((i % cols) * w, (i // cols) * h))
    info = PngImagePlugin.PngInfo()
    info.add_text("Description", desc, zip=True)
    sheet.save(path, format="PNG", pnginfo=info)

def glow(im, color, box, blur=6, alpha=110):
    g = Image.new('RGBA', im.size, (0, 0, 0, 0))
    ImageDraw.Draw(g).ellipse(box, fill=color + (alpha,))
    im.alpha_composite(g.filter(ImageFilter.GaussianBlur(blur)))

def orbit_sword():
    im = Image.new('RGBA', (B, B), (0, 0, 0, 0))
    glow(im, (190, 220, 255), (40, 10, 88, 118), blur=6, alpha=110)
    d = ImageDraw.Draw(im)
    d.polygon([(64, 8), (72, 84), (56, 84)], fill=(220, 230, 245, 255), outline=(120, 130, 150, 255))
    d.line((64, 12, 64, 82), fill=(255, 255, 255, 255), width=2)
    d.rectangle((46, 84, 82, 92), fill=(190, 150, 60, 255))
    d.rectangle((60, 92, 68, 116), fill=(110, 40, 30, 255))
    return im.resize((32, 32), Image.LANCZOS)

def crescent(phase):
    """A thin crescent of cutting qi facing north (the projectile rotates it), with soft trailing streaks."""
    im = Image.new('RGBA', (B, B), (0, 0, 0, 0))
    cx, cy = 64, 92
    outer, inner = 58, 44
    pts_out = [(cx + math.cos(math.radians(a)) * outer, cy - math.sin(math.radians(a)) * outer * 0.9) for a in range(15, 166, 5)]
    pts_in = [(cx + math.cos(math.radians(a)) * inner, cy - 6 - math.sin(math.radians(a)) * inner * 0.75) for a in range(165, 14, -5)]
    shape = pts_out + pts_in
    halo = Image.new('RGBA', (B, B), (0, 0, 0, 0))
    ImageDraw.Draw(halo).polygon(shape, fill=(140, 200, 255, int(150 + 80 * phase)))
    im.alpha_composite(halo.filter(ImageFilter.GaussianBlur(7)))
    d = ImageDraw.Draw(im)
    d.polygon(shape, fill=(200, 232, 255, 255))
    d.line(pts_out, fill=(255, 255, 255, 255), width=5)
    # streaks fading behind the blade
    streaks = Image.new('RGBA', (B, B), (0, 0, 0, 0))
    sd = ImageDraw.Draw(streaks)
    for x, top, l in ((34, 70, 30), (64, 60, 44), (94, 70, 30)):
        for k in range(l):
            alpha = int((1 - k / l) * (110 + 60 * phase))
            sd.point((x, top + k), fill=(190, 225, 255, alpha))
            sd.point((x + 1, top + k), fill=(190, 225, 255, alpha))
    im.alpha_composite(streaks.filter(ImageFilter.GaussianBlur(1)))
    return im.resize((32, 32), Image.LANCZOS)

def impact(i, n):
    im = Image.new('RGBA', (B, B), (0, 0, 0, 0))
    t = i / (n - 1)
    r = 20 + 44 * t
    a = int(255 * (1 - t))
    glow(im, (190, 230, 255), (64 - r, 64 - r, 64 + r, 64 + r), blur=8, alpha=int(a * 0.6))
    d = ImageDraw.Draw(im)
    for k in range(6):
        ang = k * math.pi / 3 + 0.3
        d.line((64 + math.cos(ang) * r * 0.4, 64 + math.sin(ang) * r * 0.4, 64 + math.cos(ang) * r, 64 + math.sin(ang) * r), fill=(255, 255, 255, a), width=5)
    d.line((30 + 40 * t, 98 - 70 * t, 98 - 10 * t, 30 + 10 * t), fill=(255, 255, 255, a), width=6)
    return im.resize((32, 32), Image.LANCZOS)

sys.path.insert(0, __import__('os').path.dirname(__file__))
from pixel import harden, outline, soft_glow, compose

def thorn_sword(phase):
    """A thorny wooden blade with a bright metal edge, pointing north (projectiles rotate it)."""
    im = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    wood, wood_dark, wood_light = (120, 82, 40, 255), (74, 48, 22, 255), (170, 124, 66, 255)
    edge, leaf = (226, 240, 220, 255), (96, 190, 80, 255)
    # blade
    d.polygon([(16, 4), (18, 9), (18, 22), (14, 22), (14, 9)], fill=wood)
    d.line((15, 7, 15, 21), fill=wood_light)
    d.line((17, 8, 17, 21), fill=wood_dark)
    d.line((16, 4, 16, 8), fill=edge)
    # thorns along both sides
    for y in (10, 14, 18):
        d.point((13, y), fill=wood_dark); d.point((12, y - 1), fill=wood_dark)
        d.point((19, y + 2), fill=wood_dark); d.point((20, y + 1), fill=wood_dark)
    # leafy guard and short hilt
    d.line((12, 22, 20, 22), fill=leaf)
    d.point((11, 21), fill=leaf); d.point((21, 21), fill=leaf)
    d.rectangle((15, 23, 16, 27), fill=wood_dark)
    body = outline(harden(im), (30, 24, 14, 255))
    glow = soft_glow((32, 32), [('ellipse', (11, 2, 21, 28))], (140, 230, 120), 2, int(70 + 50 * phase))
    out = compose(glow, body)
    if phase > 0.5:
        ImageDraw.Draw(out).point((16, 5), fill=(255, 255, 255, 255))
    return out

def splinters(i, n):
    im = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    t = i / (n - 1)
    a = int(255 * (1 - t))
    for k in range(7):
        ang = k * 2 * math.pi / 7 + 0.4
        r1, r2 = 2 + 9 * t, 5 + 11 * t
        d.line((16 + math.cos(ang) * r1, 16 + math.sin(ang) * r1, 16 + math.cos(ang) * r2, 16 + math.sin(ang) * r2), fill=(150, 104, 52, a), width=2)
    for k in range(4):
        ang = k * math.pi / 2 + t * 2
        d.point((16 + math.cos(ang) * (4 + 10 * t), 16 + math.sin(ang) * (4 + 10 * t)), fill=(110, 200, 90, a))
    return im

states = [
    ('orbit_sword', [orbit_sword()], 1),
    ('sword_qi', [crescent((math.sin(i / 4 * 2 * math.pi) + 1) / 2) for i in range(4)], 1),
    ('sword_qi_impact', [impact(i, 5) for i in range(5)], 1),
    ('thorn_sword', [thorn_sword(i / 4) for i in range(4)], 1),
    ('thorn_splinters', [splinters(i, 5) for i in range(5)], 1),
]
dmi(OUT + 'cultivation_effects.dmi', states)
if len(sys.argv) > 1:
    prev = Image.new('RGBA', (32 * 10, 32), (34, 32, 44, 255))
    x = 0
    for _, frames, _ in states:
        for f in frames:
            prev.alpha_composite(f, (x, 0)); x += 32
    prev.resize((prev.width * 3, prev.height * 3), Image.NEAREST).save(sys.argv[1])
print('ok')
