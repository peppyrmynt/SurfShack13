"""Cultivation art v2: richer medallions, animated HUD/core, effect sprites (32/64/96), particle sprites.
Placeholder art generated with Pillow so the code has something to show until an artist replaces it."""
from PIL import Image, ImageDraw, ImageFont, PngImagePlugin, ImageFilter, ImageChops
import math, os

OUT = 'surfshack13/icons/cultivation/'
import sys as _sys, os as _os
_sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from pixel import cjk_font
FONT = cjk_font()
FONT_BOLD = cjk_font(bold=True)

# ---------- DMI writer with animation support ----------
def dmi(path, states, size):
    """states: list of (name, [frames], delay_ticks)"""
    w, h = size
    flat = []
    desc = f"# BEGIN DMI\nversion = 4.0\n\twidth = {w}\n\theight = {h}\n"
    for name, frames, delay in states:
        desc += f'state = "{name}"\n\tdirs = 1\n\tframes = {len(frames)}\n'
        if len(frames) > 1:
            desc += "\tdelay = " + ",".join([str(delay)] * len(frames)) + "\n"
        flat += frames
    desc += "# END DMI\n"
    cols = min(len(flat), max(1, 1024 // w))
    rows = math.ceil(len(flat) / cols)
    sheet = Image.new('RGBA', (w * cols, h * rows), (0, 0, 0, 0))
    for i, im in enumerate(flat):
        sheet.paste(im, ((i % cols) * w, (i // cols) * h))
    info = PngImagePlugin.PngInfo()
    info.add_text("Description", desc, zip=True)
    sheet.save(path, format="PNG", pnginfo=info)
    return sheet

def canvas(w=32, h=None):
    im = Image.new('RGBA', (w, h or w), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)

def glow(im, color, box, blur=2, alpha=150):
    g = Image.new('RGBA', im.size, (0, 0, 0, 0))
    ImageDraw.Draw(g).ellipse(box, fill=color + (alpha,))
    im.alpha_composite(g.filter(ImageFilter.GaussianBlur(blur)))

def radial(size, inner, outer, center=None, radius=None):
    w, h = size
    cx, cy = center or (w / 2, h / 2)
    r = radius or min(w, h) / 2
    im = Image.new('RGBA', size, (0, 0, 0, 0))
    px = im.load()
    for y in range(h):
        for x in range(w):
            t = min(math.hypot(x + 0.5 - cx, y + 0.5 - cy) / r, 1)
            px[x, y] = tuple(int(inner[i] + (outer[i] - inner[i]) * t) for i in range(3)) + (255,)
    return im

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

# ---------- Technique medallions ----------
PALETTE = {
    'gold':    ((92, 60, 10), (246, 200, 80), (255, 246, 200)),
    'metal':   ((52, 58, 72), (196, 206, 222), (255, 255, 255)),
    'water':   ((10, 40, 92), (70, 160, 240), (220, 244, 255)),
    'fire':    ((96, 18, 6), (246, 108, 40), (255, 232, 170)),
    'earth':   ((58, 36, 12), (184, 132, 66), (255, 232, 186)),
    'wood':    ((12, 60, 24), (82, 192, 92), (226, 255, 214)),
    'jade':    ((12, 66, 54), (80, 186, 144), (226, 255, 240)),
    'crimson': ((70, 6, 14), (206, 40, 52), (255, 214, 206)),
    'violet':  ((40, 16, 72), (146, 92, 220), (240, 226, 255)),
    'void':    ((8, 8, 20), (70, 60, 120), (200, 190, 255)),
}

def medallion(char, palette):
    dark, mid, light = PALETTE[palette]
    big = 128  # draw at 4x then downsample for smooth edges
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    disc = radial((big, big), lerp(mid, light, 0.35), lerp(mid, dark, 0.45), center=(big * 0.4, big * 0.35), radius=big * 0.62)
    mask = Image.new('L', (big, big), 0)
    ImageDraw.Draw(mask).ellipse((8, 8, big - 9, big - 9), fill=255)
    im.paste(disc, (0, 0), mask)
    d = ImageDraw.Draw(im)
    d.ellipse((8, 8, big - 9, big - 9), outline=dark + (255,), width=6)
    d.ellipse((16, 16, big - 17, big - 17), outline=light + (170,), width=3)
    # bagua dots around the rim
    for i in range(8):
        a = i * math.pi / 4 - math.pi / 2
        x, y = big / 2 + math.cos(a) * 49, big / 2 + math.sin(a) * 49
        d.ellipse((x - 3.5, y - 3.5, x + 3.5, y + 3.5), fill=light + (230,))
    # top-left gloss
    gloss = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    ImageDraw.Draw(gloss).pieslice((18, 14, big - 30, big - 40), 190, 300, fill=(255, 255, 255, 70))
    im.alpha_composite(gloss.filter(ImageFilter.GaussianBlur(4)))
    # character with glow and shadow
    font = ImageFont.truetype(FONT_BOLD, 66)
    bbox = d.textbbox((0, 0), char, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx, ty = big / 2 - tw / 2 - bbox[0], big / 2 - th / 2 - bbox[1]
    halo = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    ImageDraw.Draw(halo).text((tx, ty), char, font=font, fill=light + (255,))
    im.alpha_composite(halo.filter(ImageFilter.GaussianBlur(5)))
    d = ImageDraw.Draw(im)
    d.text((tx + 3, ty + 4), char, font=font, fill=dark + (255,))
    d.text((tx, ty), char, font=font, fill=(255, 255, 255, 255))
    return im.resize((32, 32), Image.LANCZOS)

TECHNIQUES = {
    'meditate': ('禅', 'violet'), 'breakthrough': ('劫', 'gold'), 'spiritual_sense': ('识', 'violet'),
    'empty_palm': ('掌', 'gold'), 'qinggong': ('轻', 'jade'), 'write_talisman': ('符', 'crimson'),
    'teach': ('师', 'gold'), 'beast_contract': ('兽', 'jade'), 'summon_beast': ('召', 'jade'),
    'acupoint': ('点', 'violet'), 'realm_pressure': ('威', 'gold'),
    'bind_artifact': ('器', 'metal'), 'flying_sword': ('剑', 'metal'), 'sword_qi': ('气', 'metal'), 'sword_riding': ('御', 'metal'),
    'sword_formation': ('阵', 'metal'),
    'still_water_ward': ('护', 'water'), 'calm_heart': ('静', 'water'), 'turtle_breathing': ('龟', 'water'), 'mirror_lake': ('镜', 'water'),
    'kindle': ('燃', 'fire'), 'furnace_burst': ('炉', 'fire'), 'burning_blood': ('血', 'crimson'), 'sea_of_flames': ('焰', 'fire'),
    'rooted_stance': ('根', 'earth'), 'golden_bell': ('钟', 'gold'), 'dharma_idol': ('佛', 'gold'), 'buddha_palm': ('如', 'gold'),
    'spring_mending': ('愈', 'wood'), 'verdant_growth': ('生', 'wood'), 'binding_vines': ('藤', 'wood'), 'spring_revival': ('春', 'wood'),
    'steam_veil': ('雾', 'water'), 'thousand_thorns': ('刺', 'wood'), 'molten_step': ('熔', 'fire'), 'mud_prison': ('泥', 'earth'),
    'void_step': ('虚', 'void'), 'inscribe_formation': ('卦', 'violet'),
    'duel': ('决', 'crimson'), 'yield': ('降', 'metal'), 'found_sect': ('宗', 'gold'), 'sect_transmission': ('传', 'violet'),
    'declare_rivalry': ('仇', 'crimson'), 'imperial_decree': ('令', 'gold'), 'claim_mandate': ('天', 'gold'),
    'lend_qi': ('授', 'jade'), 'cultivation_panel': ('道', 'violet'),
}
dmi(OUT + 'cultivation_actions.dmi', [(k, [medallion(*v)], 1) for k, v in TECHNIQUES.items()], (32, 32))

# ---------- Animated taiji HUD orb ----------
def taiji_frame(angle, ready, pulse):
    big = 128
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    if ready:
        glow(im, (255, 210, 90), (2, 2, big - 3, big - 3), blur=8, alpha=int(150 + 80 * pulse))
    d = ImageDraw.Draw(im)
    d.ellipse((12, 12, big - 13, big - 13), fill=(16, 16, 30, 255), outline=(214, 176, 72, 255), width=6)
    t = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    td = ImageDraw.Draw(t)
    r0, r1 = 20, big - 21
    mid = big / 2
    light, dark = (240, 236, 220, 255), (34, 34, 52, 255)
    td.pieslice((r0, r0, r1, r1), 90, 270, fill=light)
    td.pieslice((r0, r0, r1, r1), 270, 90, fill=dark)
    q = (r1 - r0) / 4
    td.ellipse((mid - q, r0, mid + q, mid), fill=dark)
    td.ellipse((mid - q, mid, mid + q, r1), fill=light)
    td.ellipse((mid - 6, r0 + q - 6, mid + 6, r0 + q + 6), fill=light)
    td.ellipse((mid - 6, r1 - q - 6, mid + 6, r1 - q + 6), fill=dark)
    t = t.rotate(angle, resample=Image.BICUBIC)
    im.alpha_composite(t)
    return im.resize((32, 32), Image.LANCZOS)

FRAMES = 8
dmi(OUT + 'cultivation_hud.dmi', [
    ('qi_display', [taiji_frame(-i * 360 / FRAMES, False, 0) for i in range(FRAMES)], 2),
    ('qi_display_ready', [taiji_frame(-i * 360 / FRAMES, True, (math.sin(i / FRAMES * 2 * math.pi) + 1) / 2) for i in range(FRAMES)], 1),
], (32, 32))

# ---------- Items ----------
def mat():
    big = 128
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((8, 40, 120, 112), fill=(96, 22, 20, 255), outline=(50, 10, 8, 255), width=4)
    d.ellipse((18, 46, 110, 104), fill=(170, 46, 36, 255))
    for i in range(14):
        a = i * 2 * math.pi / 14
        d.line((64 + math.cos(a) * 20, 75 + math.sin(a) * 12, 64 + math.cos(a) * 44, 75 + math.sin(a) * 27), fill=(130, 30, 24, 255), width=3)
    d.ellipse((28, 54, 100, 96), outline=(232, 186, 70, 255), width=4)
    for i in range(8):
        a = i * math.pi / 4
        x, y = 64 + math.cos(a) * 30, 75 + math.sin(a) * 17
        d.line((x - 6, y, x + 6, y), fill=(250, 214, 110, 255), width=3)
    d.ellipse((50, 66, 78, 84), fill=(236, 196, 84, 255), outline=(150, 100, 20, 255), width=2)
    return im.resize((32, 32), Image.LANCZOS)

def manual():
    big = 128
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((28, 14, 104, 114), fill=(30, 64, 46, 255), outline=(12, 26, 18, 255), width=4)
    d.rectangle((34, 18, 100, 110), fill=(44, 94, 66, 255))
    for y in (30, 50, 70, 90):
        d.line((34, y, 40, y), fill=(220, 190, 110, 255), width=3)
    d.line((40, 18, 40, 110), fill=(200, 170, 90, 255), width=2)
    d.rectangle((54, 26, 90, 98), fill=(236, 224, 190, 255), outline=(150, 120, 60, 255), width=2)
    font = ImageFont.truetype(FONT_BOLD, 30)
    for i, ch in enumerate('秘籍'):
        d.text((58, 30 + i * 32), ch, font=font, fill=(150, 20, 20, 255))
    return im.resize((32, 32), Image.LANCZOS)

def ring():
    big = 128
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    glow(im, (120, 90, 200), (36, 20, 92, 76), blur=6, alpha=90)
    d = ImageDraw.Draw(im)
    d.ellipse((34, 50, 94, 110), outline=(150, 112, 36, 255), width=12)
    d.ellipse((38, 54, 90, 106), outline=(240, 200, 90, 255), width=4)
    d.ellipse((48, 26, 80, 58), fill=(24, 22, 36, 255), outline=(170, 130, 40, 255), width=5)
    d.ellipse((56, 32, 66, 42), fill=(150, 140, 220, 200))
    return im.resize((32, 32), Image.LANCZOS)

def dantian():
    big = 128
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    glow(im, (255, 140, 150), (24, 30, 104, 110), blur=6, alpha=90)
    d = ImageDraw.Draw(im)
    d.ellipse((34, 40, 94, 100), fill=(206, 96, 110, 255), outline=(120, 40, 56, 255), width=4)
    d.arc((44, 48, 88, 92), 200, 400, fill=(150, 52, 70, 255), width=4)
    d.ellipse((48, 52, 66, 66), fill=(246, 170, 180, 255))
    return im.resize((32, 32), Image.LANCZOS)

def golden_core(phase):
    big = 128
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    glow(im, (255, 214, 90), (14 - phase * 4, 14 - phase * 4, 114 + phase * 4, 114 + phase * 4), blur=8, alpha=int(110 + phase * 60))
    core = radial((big, big), (255, 250, 210), (196, 128, 20), center=(52, 50), radius=46)
    mask = Image.new('L', (big, big), 0)
    ImageDraw.Draw(mask).ellipse((34, 34, 94, 94), fill=255)
    im.paste(core, (0, 0), mask)
    d = ImageDraw.Draw(im)
    d.ellipse((34, 34, 94, 94), outline=(140, 90, 10, 255), width=3)
    d.ellipse((46, 42, 60, 54), fill=(255, 255, 255, 200))
    return im.resize((32, 32), Image.LANCZOS)

old = Image.open(OUT + 'cultivation_items.dmi')
def old_state(index):
    cols = old.width // 32
    return old.crop(((index % cols) * 32, (index // cols) * 32, (index % cols) * 32 + 32, (index // cols) * 32 + 32))
# existing order: mat manual ring dantian golden_core needles flying_dagger smoke_pellet sect_plaque jade_seal pill_qi pill_foundation pill_tribulation pill_tempering
kept = {name: old_state(i) for i, name in enumerate(['mat', 'manual', 'ring', 'dantian', 'golden_core', 'needles', 'flying_dagger', 'smoke_pellet',
    'sect_plaque', 'jade_seal', 'pill_qi', 'pill_foundation', 'pill_tribulation', 'pill_tempering'])}
core_frames = [golden_core((math.sin(i / 6 * 2 * math.pi) + 1) / 2) for i in range(6)]
dmi(OUT + 'cultivation_items.dmi', [
    ('mat', [mat()], 1), ('manual', [manual()], 1), ('ring', [ring()], 1), ('dantian', [dantian()], 1),
    ('golden_core', core_frames, 2),
] + [(n, [kept[n]], 1) for n in ['needles', 'flying_dagger', 'smoke_pellet', 'sect_plaque', 'jade_seal',
    'pill_qi', 'pill_foundation', 'pill_tribulation', 'pill_tempering']], (32, 32))

# ---------- Particles (small sprites) ----------
def mote(color, r=3):
    im, d = canvas(8)
    glow(im, color, (0, 0, 7, 7), blur=1, alpha=200)
    d = ImageDraw.Draw(im)
    d.ellipse((4 - r / 2, 4 - r / 2, 3 + r / 2, 3 + r / 2), fill=(255, 255, 255, 255))
    return im

def petal():
    im, d = canvas(8)
    d.ellipse((1, 2, 6, 5), fill=(255, 170, 200, 230), outline=(220, 110, 150, 255))
    return im

def ember():
    im, d = canvas(8)
    glow(im, (255, 120, 30), (1, 1, 6, 6), blur=1, alpha=220)
    ImageDraw.Draw(im).point((3, 3), fill=(255, 240, 180, 255))
    return im

dmi(OUT + 'cultivation_particles.dmi', [
    ('qi_mote', [mote((120, 210, 255))], 1), ('gold_mote', [mote((255, 210, 90))], 1),
    ('petal', [petal()], 1), ('ember', [ember()], 1), ('void_mote', [mote((150, 110, 255), 2)], 1),
], (8, 8))

# ---------- 32px effects ----------
def orbit_sword():
    big = 128
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    glow(im, (190, 220, 255), (40, 10, 88, 118), blur=6, alpha=110)
    d = ImageDraw.Draw(im)
    d.polygon([(64, 8), (72, 84), (56, 84)], fill=(220, 230, 245, 255), outline=(120, 130, 150, 255))
    d.line((64, 12, 64, 82), fill=(255, 255, 255, 255), width=2)
    d.rectangle((46, 84, 82, 92), fill=(190, 150, 60, 255))
    d.rectangle((60, 92, 68, 116), fill=(110, 40, 30, 255))
    return im.resize((32, 32), Image.LANCZOS)

dmi(OUT + 'cultivation_effects.dmi', [('orbit_sword', [orbit_sword()], 1)], (32, 32))

# ---------- 64px effects ----------
def golden_bell():
    big = 256
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    body = [(70, 70), (186, 70), (210, 200), (222, 222), (34, 222), (46, 200)]
    d.polygon(body, fill=(255, 200, 60, 90), outline=(255, 214, 90, 220))
    d.ellipse((96, 30, 160, 82), fill=(255, 210, 80, 110), outline=(255, 226, 120, 230), width=4)
    for y in (110, 150, 190):
        d.line((56 + (y - 110) * 0.15, y, 200 - (y - 110) * 0.15, y), fill=(255, 236, 160, 170), width=4)
    for x in range(80, 180, 24):
        d.ellipse((x, 94, x + 10, 104), fill=(255, 240, 180, 200))
    im = im.filter(ImageFilter.GaussianBlur(1))
    return im.resize((64, 64), Image.LANCZOS)

def water_bubble(phase):
    big = 256
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    wob = 6 * math.sin(phase * 2 * math.pi)
    d.ellipse((36 - wob, 30 + wob, 220 + wob, 236 - wob), fill=(80, 170, 255, 50), outline=(160, 220, 255, 200), width=6)
    d.arc((60, 52, 150, 140), 200, 260, fill=(255, 255, 255, 200), width=8)
    return im.filter(ImageFilter.GaussianBlur(1)).resize((64, 64), Image.LANCZOS)

def buddha_palm():
    big = 256
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    glow(im, (255, 214, 90), (10, 10, 246, 246), blur=10, alpha=120)
    d = ImageDraw.Draw(im)
    gold, dark = (246, 196, 70, 235), (150, 96, 20, 255)
    d.rounded_rectangle((60, 110, 196, 230), 40, fill=gold, outline=dark, width=5)
    for i, (x, top) in enumerate(((66, 40), (98, 18), (130, 14), (162, 30))):
        d.rounded_rectangle((x, top, x + 28, 140), 14, fill=gold, outline=dark, width=5)
    d.rounded_rectangle((180, 120, 236, 160), 18, fill=gold, outline=dark, width=5)
    d.ellipse((112, 150, 144, 182), outline=(255, 246, 200, 255), width=5)
    return im.resize((64, 64), Image.LANCZOS)

def void_rift(phase):
    big = 256
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    glow(im, (120, 80, 255), (40, 20, 216, 236), blur=14, alpha=170)
    d = ImageDraw.Draw(im)
    w = 30 + 20 * phase
    d.ellipse((128 - w, 30, 128 + w, 226), fill=(10, 4, 24, 255), outline=(190, 160, 255, 255), width=6)
    for i in range(5):
        a = phase * 2 * math.pi + i * 1.25
        x, y = 128 + math.cos(a) * w * 0.6, 128 + math.sin(a) * 80
        d.ellipse((x - 5, y - 5, x + 5, y + 5), fill=(220, 200, 255, 255))
    return im.resize((64, 64), Image.LANCZOS)

dmi(OUT + 'cultivation_effects_64.dmi', [
    ('golden_bell', [golden_bell()], 1),
    ('water_bubble', [water_bubble(i / 6) for i in range(6)], 2),
    ('buddha_palm', [buddha_palm()], 1),
    ('void_rift', [void_rift(i / 6) for i in range(6)], 1),
], (64, 64))

# ---------- 96px effects ----------
def storm_cloud(phase):
    big = 384
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    base = [(60, 120, 90), (130, 90, 110), (210, 100, 100), (280, 120, 85), (170, 140, 110), (100, 150, 80), (250, 150, 80)]
    for i, (x, y, r) in enumerate(base):
        dx = 10 * math.sin(phase * 2 * math.pi + i)
        shade = 40 + (i % 3) * 14
        d.ellipse((x - r + dx, y - r * 0.6, x + r + dx, y + r * 0.6), fill=(shade, shade, shade + 24, 225))
    if phase in (0.5,):
        d.line((190, 170, 170, 230, 200, 230, 176, 320), fill=(255, 250, 200, 255), width=10)
    im = im.filter(ImageFilter.GaussianBlur(3))
    return im.resize((96, 96), Image.LANCZOS)

def sigil(color, symbol):
    big = 384
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    glow(im, color, (20, 20, 364, 364), blur=10, alpha=60)
    d = ImageDraw.Draw(im)
    c = big / 2
    d.ellipse((24, 24, big - 25, big - 25), outline=color + (230,), width=8)
    d.ellipse((60, 60, big - 61, big - 61), outline=color + (180,), width=4)
    # eight trigrams
    trigrams = ['111', '011', '101', '001', '110', '010', '100', '000']
    for i, tri in enumerate(trigrams):
        a = i * math.pi / 4 - math.pi / 2
        for j, bit in enumerate(tri):
            rr = 150 - j * 14
            x, y = c + math.cos(a) * rr, c + math.sin(a) * rr
            px, py = -math.sin(a) * 22, math.cos(a) * 22
            if bit == '1':
                d.line((x - px, y - py, x + px, y + py), fill=color + (230,), width=7)
            else:
                d.line((x - px, y - py, x - px * 0.3, y - py * 0.3), fill=color + (230,), width=7)
                d.line((x + px * 0.3, y + py * 0.3, x + px, y + py), fill=color + (230,), width=7)
    font = ImageFont.truetype(FONT_BOLD, 90)
    bbox = d.textbbox((0, 0), symbol, font=font)
    d.text((c - (bbox[2] - bbox[0]) / 2 - bbox[0], c - (bbox[3] - bbox[1]) / 2 - bbox[1]), symbol, font=font, fill=color + (240,))
    return im.resize((96, 96), Image.LANCZOS)

dmi(OUT + 'cultivation_effects_96.dmi', [
    ('storm_cloud', [storm_cloud(i / 4) for i in range(4)], 3),
    ('sigil_barrier', [sigil((255, 200, 80), '御')], 1),
    ('sigil_gathering', [sigil((120, 210, 255), '聚')], 1),
    ('sigil_alarm', [sigil((255, 90, 90), '警')], 1),
], (96, 96))

# ---------- preview ----------
prev = Image.new('RGBA', (1024, 420), (34, 32, 44, 255))
acts = Image.open(OUT + 'cultivation_actions.dmi'); prev.alpha_composite(acts.crop((0, 0, min(acts.width, 1024), acts.height)), (0, 0))
y = acts.height + 6
items = Image.open(OUT + 'cultivation_items.dmi'); prev.alpha_composite(items.crop((0, 0, min(items.width, 1024), 32)), (0, y))
hud = Image.open(OUT + 'cultivation_hud.dmi'); prev.alpha_composite(hud.crop((0, 0, 512, 32)), (0, y + 40))
e64 = Image.open(OUT + 'cultivation_effects_64.dmi'); prev.alpha_composite(e64.crop((0, 0, min(e64.width, 1024), 64)), (0, y + 80))
e96 = Image.open(OUT + 'cultivation_effects_96.dmi'); prev.alpha_composite(e96.crop((0, 0, min(e96.width, 1024), 96)), (0, y + 150))
prev.resize((prev.width, prev.height), Image.NEAREST).save(os.environ['PREVIEW'])
print('ok')
