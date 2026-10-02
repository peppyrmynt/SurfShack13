"""Backlog art: demonic path medallions and items, per-law manual covers, per-type talismans, the alchemy cauldron,
the guqin, new pills, heart demon and spirit beast auras, and the imperial decree scroll.

Unlike the earlier scripts this one MERGES its states into the existing DMIs (adding or replacing only its own states),
so it can run after all of them without disturbing anything. Run from the repo root."""
import sys, os, math, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel import save_dmi, harden, outline, soft_glow, compose, cjk_font
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = 'surfshack13/icons/cultivation/'
FONT_BOLD = cjk_font(bold=True)
OUTLINE = (26, 22, 30, 255)

# ---------------------------------------------------------------- DMI merging

def read_dmi(path):
    """Returns (size, [(name, [frames], delays)]). Only handles dirs = 1, which is all these files use."""
    im = Image.open(path).convert('RGBA')
    desc = Image.open(path).info['Description']
    w = int(re.search(r'width = (\d+)', desc).group(1))
    h = int(re.search(r'height = (\d+)', desc).group(1))
    cols = im.width // w
    states = []
    index = 0
    for block in re.split(r'\nstate = ', desc)[1:]:
        name = re.match(r'"([^"]*)"', block).group(1)
        dirs = int(re.search(r'dirs = (\d+)', block).group(1))
        frames = int(re.search(r'frames = (\d+)', block).group(1))
        assert dirs == 1, f'{path}:{name} has {dirs} dirs'
        delay_match = re.search(r'delay = ([\d.,]+)', block)
        delays = [float(x) if '.' in x else int(x) for x in delay_match.group(1).split(',')] if delay_match else 1
        images = []
        for _ in range(frames):
            x, y = (index % cols) * w, (index // cols) * h
            images.append(im.crop((x, y, x + w, y + h)))
            index += 1
        states.append((name, images, delays))
    return (w, h), states

def merge_dmi(path, new_states):
    size, states = read_dmi(path)
    names = [s[0] for s in states]
    for state in new_states:
        if state[0] in names:
            states[names.index(state[0])] = state
        else:
            states.append(state)
            names.append(state[0])
    save_dmi(path, states, size)

# ---------------------------------------------------------------- helpers

def c(rgb, a=255):
    return tuple(rgb) + (a,)

def canvas(w=32, h=None):
    im = Image.new('RGBA', (w, h or w), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)

def finish(im, line=OUTLINE, glow=None):
    body = outline(harden(im), line)
    if not glow:
        return body
    color, box, blur, alpha = glow
    return compose(soft_glow(im.size, [('ellipse', box)], color, blur, alpha), body)

def glint(im, x, y, size=2):
    d = ImageDraw.Draw(im)
    d.point((x, y), fill=(255, 255, 255, 255))
    for k in range(1, size + 1):
        a = 255 - k * 70
        for dx, dy in ((k, 0), (-k, 0), (0, k), (0, -k)):
            if 0 <= x + dx < im.width and 0 <= y + dy < im.height:
                d.point((x + dx, y + dy), fill=(255, 255, 240, a))
    return im

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

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

# ---------------------------------------------------------------- medallions (same recipe as make_art_v2.py)

PALETTE = {
    'gold':    ((92, 60, 10), (246, 200, 80), (255, 246, 200)),
    'crimson': ((70, 6, 14), (206, 40, 52), (255, 214, 206)),
    'void':    ((8, 8, 20), (70, 60, 120), (200, 190, 255)),
    'demon':   ((14, 2, 6), (104, 14, 28), (255, 150, 150)),
    'violet':  ((40, 16, 72), (146, 92, 220), (240, 226, 255)),
    'metal':   ((52, 58, 72), (196, 206, 222), (255, 255, 255)),
    'earth':   ((58, 36, 12), (184, 132, 66), (255, 232, 186)),
    'jade':    ((12, 66, 54), (80, 186, 144), (226, 255, 240)),
    'bronze':  ((70, 40, 14), (196, 128, 56), (255, 226, 180)),
}

def medallion(char, palette):
    dark, mid, light = PALETTE[palette]
    big = 128
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    disc = radial((big, big), lerp(mid, light, 0.35), lerp(mid, dark, 0.45), center=(big * 0.4, big * 0.35), radius=big * 0.62)
    mask = Image.new('L', (big, big), 0)
    ImageDraw.Draw(mask).ellipse((8, 8, big - 9, big - 9), fill=255)
    im.paste(disc, (0, 0), mask)
    d = ImageDraw.Draw(im)
    d.ellipse((8, 8, big - 9, big - 9), outline=dark + (255,), width=6)
    d.ellipse((16, 16, big - 17, big - 17), outline=light + (170,), width=3)
    for i in range(8):
        a = i * math.pi / 4 - math.pi / 2
        x, y = big / 2 + math.cos(a) * 49, big / 2 + math.sin(a) * 49
        d.ellipse((x - 3.5, y - 3.5, x + 3.5, y + 3.5), fill=light + (230,))
    gloss = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    ImageDraw.Draw(gloss).pieslice((18, 14, big - 30, big - 40), 190, 300, fill=(255, 255, 255, 70))
    im.alpha_composite(gloss.filter(ImageFilter.GaussianBlur(4)))
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
    'devouring_art': ('噬', 'demon'), 'gu_worm': ('蛊', 'demon'), 'stir_gu': ('搅', 'demon'),
    'soul_search': ('搜', 'void'), 'corpse_puppet': ('尸', 'demon'), 'blood_escape': ('遁', 'crimson'),
    'transmit_forbidden': ('魔', 'demon'), 'ascension': ('仙', 'gold'),
    # Body Molding Art
    'body_panel': ('体', 'bronze'), 'forge_body': ('锻', 'earth'), 'body_breakthrough': ('蜕', 'bronze'),
    'iron_shirt': ('铁', 'metal'), 'mountain_leap': ('跃', 'earth'), 'shattering_fist': ('碎', 'crimson'),
    'bone_setting': ('骨', 'jade'), 'body_disciple': ('徒', 'bronze'), 'remold_limb': ('塑', 'bronze'),
    'blood_boil': ('沸', 'crimson'), 'vajra_body': ('刚', 'gold'), 'primordial_roar': ('吼', 'void'),
    'earth_stomp': ('震', 'earth'), 'hundred_fists': ('百', 'crimson'), 'bull_charge': ('冲', 'bronze'),
    'falling_star': ('坠', 'earth'), 'mountain_hurl': ('掷', 'bronze'), 'sky_splitting_palm': ('裂', 'metal'),
    'heaven_quake': ('崩', 'void'),
}

# ---------------------------------------------------------------- items

def manual_cover(cover, cover_dark, emblem):
    """The old manual's binding and layout, with an element emblem instead of the paper label."""
    im, d = canvas()
    paper, gold = (236, 224, 190), (214, 174, 80)
    d.rectangle((8, 4, 24, 28), fill=c(cover))
    d.line((9, 4, 9, 28), fill=c(cover_dark))
    for y in (7, 12, 17, 22, 26):
        d.point((8, y), fill=c(gold)); d.point((9, y), fill=c(gold))
    d.rectangle((13, 6, 21, 22), fill=c(paper))
    d.rectangle((13, 6, 21, 22), outline=c(gold))
    emblem(d)
    d.line((24, 5, 24, 27), fill=c(lerp(cover, (255, 255, 255), 0.25)))
    d.line((14, 25, 21, 25), fill=c(gold))
    return finish(im)

def emblem_metal(d):
    blade, edge, guard = (150, 160, 180), (230, 236, 246), (180, 140, 60)
    d.line((17, 8, 17, 17), fill=c(blade)); d.line((18, 8, 18, 16), fill=c(edge))
    d.line((15, 18, 20, 18), fill=c(guard)); d.line((17, 19, 17, 21), fill=c((90, 50, 30)))

def emblem_water(d):
    blue, light = (40, 110, 200), (120, 190, 250)
    for y, col in ((10, light), (14, blue), (18, light)):
        d.point((14, y + 1), fill=c(col)); d.line((15, y, 16, y), fill=c(col)); d.point((17, y + 1), fill=c(col))
        d.line((18, y + 1, 19, y + 1), fill=c(col)); d.point((20, y), fill=c(col))

def emblem_fire(d):
    red, orange, yellow = (196, 40, 20), (240, 120, 30), (255, 210, 90)
    d.polygon([(17, 8), (20, 14), (20, 19), (14, 19), (14, 14), (16, 12)], fill=c(red))
    d.polygon([(17, 12), (19, 16), (18, 19), (16, 19), (15, 16)], fill=c(orange))
    d.line((17, 16, 17, 18), fill=c(yellow))

def emblem_earth(d):
    brown, ochre, snow = (110, 70, 30), (180, 130, 60), (246, 240, 226)
    d.polygon([(13, 20), (17, 10), (21, 20)], fill=c(brown))
    d.polygon([(15, 16), (17, 10), (19, 16)], fill=c(ochre))
    d.line((16, 12, 18, 12), fill=c(snow)); d.point((17, 11), fill=c(snow))
    d.line((14, 20, 21, 20), fill=c((80, 50, 20)))

def emblem_wood(d):
    green, light, stem = (50, 140, 60), (120, 210, 110), (90, 60, 30)
    d.ellipse((14, 9, 20, 17), fill=c(green))
    d.line((15, 16, 19, 10), fill=c(light))
    d.line((17, 16, 17, 20), fill=c(stem))

def manual_demonic():
    im, d = canvas()
    cover, cover_dark, red, eye_white = (30, 22, 28), (12, 8, 12), (170, 20, 30), (230, 210, 200)
    d.rectangle((8, 4, 24, 28), fill=c(cover))
    d.line((9, 4, 9, 28), fill=c(cover_dark))
    for y in (7, 12, 17, 22, 26):
        d.point((8, y), fill=c(red)); d.point((9, y), fill=c(red))
    # stitched flesh-ish seam and a staring eye
    for y in range(6, 27, 3):
        d.point((23, y), fill=c((90, 60, 60)))
    d.ellipse((12, 11, 22, 18), fill=c(eye_white))
    d.ellipse((15, 12, 19, 17), fill=c(red))
    d.line((17, 13, 17, 16), fill=c((20, 0, 0)))
    d.line((12, 14, 13, 14), fill=c(cover_dark)); d.line((21, 14, 22, 14), fill=c(cover_dark))
    d.point((14, 21), fill=c(red)); d.point((16, 23), fill=c(red)); d.point((19, 21), fill=c(red))
    return finish(im, glow=((180, 20, 30), (4, 2, 28, 30), 3, 120))

def body_primer():
    """A thin, grubby tan pamphlet with a figure in horse stance."""
    im, d = canvas()
    paper, paper_dark, ink = (214, 190, 140), (160, 132, 86), (60, 36, 24)
    d.polygon([(9, 6), (23, 5), (24, 27), (10, 28)], fill=c(paper))
    d.line((9, 6, 10, 28), fill=c(paper_dark))
    d.line((23, 5, 24, 27), fill=c(lerp(paper, (255, 255, 255), 0.3)))
    # stick figure in a horse stance
    d.ellipse((15, 9, 18, 12), fill=c(ink))
    d.line((16, 12, 16, 18), fill=c(ink))
    d.line((12, 14, 20, 14), fill=c(ink))
    d.line((16, 18, 13, 20), fill=c(ink)); d.line((13, 20, 13, 23), fill=c(ink))
    d.line((16, 18, 19, 20), fill=c(ink)); d.line((19, 20, 19, 23), fill=c(ink))
    # dog-eared corner and a sweat stain
    d.polygon([(20, 25), (24, 27), (23, 24)], fill=c(paper_dark))
    d.point((12, 25), fill=c(paper_dark)); d.point((13, 25), fill=c(paper_dark))
    return finish(im)

def body_manual():
    """A heavy book bound between two bronze plates, with a clenched fist on the cover."""
    im, d = canvas()
    bronze, bronze_dark, bronze_light, patina = (156, 108, 48), (96, 62, 26), (214, 168, 92), (86, 150, 120)
    d.rectangle((7, 4, 25, 28), fill=c(bronze))
    d.rectangle((7, 4, 25, 28), outline=c(bronze_dark))
    d.line((8, 5, 24, 5), fill=c(bronze_light))
    for x, y in ((9, 6), (23, 6), (9, 26), (23, 26)):
        d.point((x, y), fill=c(bronze_light))
    # clenched fist
    skin, skin_dark = (232, 186, 140), (170, 120, 80)
    d.rectangle((12, 11, 20, 18), fill=c(skin))
    for x in (13, 15, 17, 19):
        d.line((x, 11, x, 13), fill=c(skin_dark))
    d.line((12, 15, 17, 15), fill=c(skin_dark))
    d.rectangle((13, 19, 19, 22), fill=c(skin_dark))
    d.point((10, 24), fill=c(patina)); d.point((22, 9), fill=c(patina)); d.point((21, 25), fill=c(patina))
    return finish(im)

def talisman(stamp):
    """A vertical yellow paper strip with red brush strokes and a coloured top stamp."""
    im, d = canvas()
    paper, paper_dark, ink = (238, 206, 92), (196, 160, 52), (178, 24, 24)
    d.rectangle((12, 3, 19, 29), fill=c(paper))
    d.line((19, 3, 19, 29), fill=c(paper_dark))
    d.line((12, 29, 19, 29), fill=c(paper_dark))
    # brush strokes: a little column of pseudo characters
    strokes = [((14, 12), (17, 12)), ((15, 13), (15, 16)), ((14, 15), (17, 15)), ((16, 17), (14, 19)),
               ((14, 21), (17, 21)), ((16, 21), (16, 24)), ((14, 23), (17, 25)), ((15, 26), (17, 26))]
    for a, b in strokes:
        d.line((a, b), fill=c(ink))
    stamp(d)
    return finish(im)

def stamp_fire(d):
    d.polygon([(15, 4), (18, 8), (17, 10), (14, 10), (13, 8)], fill=c((228, 70, 20)))
    d.point((15, 8), fill=c((255, 210, 90)))

def stamp_binding(d):
    purple = (120, 70, 190)
    d.ellipse((13, 4, 16, 7), outline=c(purple)); d.ellipse((15, 6, 18, 9), outline=c(purple))

def stamp_ward(d):
    d.ellipse((13, 4, 18, 9), fill=c((60, 140, 230)))
    d.ellipse((14, 5, 17, 8), outline=c((190, 230, 255)))

def stamp_light(d):
    sun = (255, 236, 120)
    d.ellipse((14, 5, 17, 8), fill=c(sun))
    for x, y in ((15, 3), (16, 3), (12, 6), (19, 6), (13, 4), (18, 4)):
        d.point((x, y), fill=c((255, 214, 80)))

def stamp_jiangshi(d):
    d.rectangle((13, 4, 18, 9), fill=c((190, 24, 30)))
    d.rectangle((14, 5, 17, 8), outline=c((255, 220, 160)))
    d.point((15, 6), fill=c((255, 220, 160))); d.point((16, 7), fill=c((255, 220, 160)))

def cauldron(phase=None):
    """A three-legged bronze ding. phase = flame frame index when lit."""
    im, d = canvas()
    bronze, bronze_dark, bronze_light, patina = (156, 108, 48), (96, 62, 26), (206, 160, 86), (86, 150, 120)
    if phase is not None:
        flame_heights = [(5, 7, 4), (7, 4, 6), (4, 6, 7), (6, 5, 5)][phase]
        for x, height in zip((9, 15, 21), flame_heights):
            d.polygon([(x - 2, 30), (x, 30 - height), (x + 2, 30)], fill=c((236, 96, 24)))
            d.polygon([(x - 1, 30), (x, 30 - height + 2), (x + 1, 30)], fill=c((255, 206, 90)))
    # legs
    for x in (8, 15, 22):
        d.rectangle((x, 22, x + 2, 28), fill=c(bronze_dark))
    # bowl
    d.pieslice((4, 4, 28, 26), 0, 180, fill=c(bronze))
    d.rectangle((4, 12, 28, 15), fill=c(bronze))
    d.line((5, 12, 27, 12), fill=c(bronze_light))
    d.line((6, 17, 26, 17), fill=c(bronze_dark))
    # taotie-ish band and patina
    for x in range(7, 26, 4):
        d.rectangle((x, 18, x + 1, 19), fill=c(patina))
    d.point((10, 21), fill=c(patina)); d.point((22, 22), fill=c(patina))
    # rim and handles
    d.rectangle((3, 10, 29, 12), fill=c(bronze_dark))
    d.line((4, 10, 28, 10), fill=c(bronze_light))
    for x in (6, 23):
        d.rectangle((x, 5, x + 3, 9), outline=c(bronze_dark))
        d.line((x + 1, 5, x + 2, 5), fill=c(bronze_light))
    if phase is not None:
        # steam over the mouth
        for k, x in enumerate((11, 16, 21)):
            y = 7 - ((phase + k) % 3)
            d.point((x, y), fill=c((230, 236, 236), 200)); d.point((x + 1, y - 1), fill=c((230, 236, 236), 150))
    glow = ((255, 140, 40), (2, 18, 30, 34), 3, 120) if phase is not None else None
    return finish(im, glow=glow)

def guqin():
    im, d = canvas()
    lacquer, lacquer_dark, lacquer_light, silk, jade, red = (74, 30, 20), (34, 12, 8), (128, 60, 38), (226, 214, 180), (120, 200, 160), (190, 30, 40)
    # a long lacquered board lying at a slight angle, head on the right
    d.polygon([(1, 15), (28, 11), (31, 13), (31, 19), (2, 22)], fill=c(lacquer))
    d.line((1, 15, 28, 11), fill=c(lacquer_light))
    d.line((2, 22, 31, 19), fill=c(lacquer_dark))
    d.line((2, 16, 2, 21), fill=c(lacquer_dark))
    # bridge near the head and the "dragon pool" at the tail
    d.line((26, 12, 27, 19), fill=c(lacquer_dark))
    d.line((5, 16, 5, 20), fill=c(lacquer_dark))
    # three visible strings, thin and pale
    for k, (y0, y1) in enumerate(((16, 13), (18, 15), (20, 17))):
        d.line((5, y0, 26, y1), fill=c(silk, 190))
    # jade hui studs along the top edge
    for x, y in ((9, 14), (13, 14), (17, 13), (21, 12)):
        d.point((x, y), fill=c(jade))
    # silk tassels from the head
    d.line((30, 19, 30, 25), fill=c(red)); d.line((28, 20, 29, 24), fill=c(red))
    d.point((30, 26), fill=c((240, 200, 90)))
    return finish(im)

def pill(color, light, dark, ring=None):
    im, d = canvas()
    d.ellipse((10, 12, 21, 23), fill=c(color))
    d.arc((10, 12, 21, 23), 20, 160, fill=c(dark))
    d.ellipse((12, 14, 15, 17), fill=c(light))
    if ring:
        d.arc((9, 11, 22, 24), 200, 340, fill=c(ring))
    body = finish(im, glow=(color, (6, 8, 25, 27), 2, 110))
    return glint(body, 19, 13, 1)

# ---------------------------------------------------------------- 64px effects

def wisp_ring(phase, frames, base, count, radius, blob, alpha, wobble):
    """A soft ring of drifting blobs around the centre, for auras. Glows are meant to be soft here."""
    im = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for i in range(count):
        a = 2 * math.pi * (i / count + phase / frames / count)
        r = radius + wobble * math.sin(a * 3 + phase * 2 * math.pi / frames)
        x, y = 32 + math.cos(a) * r, 34 + math.sin(a) * r * 0.55
        size = blob * (0.7 + 0.3 * math.sin(a * 2 + phase))
        d.ellipse((x - size, y - size, x + size, y + size), fill=base + (alpha,))
    return im.filter(ImageFilter.GaussianBlur(2))

def heart_demon_aura(phase, frames=6):
    """Dark smoke pooling at the feet with curling wisps rising, slowly turning."""
    im = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # pooled smoke ring around the feet
    for i in range(14):
        a = 2 * math.pi * (i / 14 + phase / frames / 14)
        x, y = 32 + math.cos(a) * 14, 46 + math.sin(a) * 5
        size = 3.5 + 1.2 * math.sin(a * 3 + phase)
        d.ellipse((x - size, y - size, x + size, y + size), fill=(46, 8, 64, 150))
    # three curling wisps climbing the body
    for k in range(3):
        base_x = 22 + k * 10
        for step in range(10):
            t = step / 9
            y = 46 - t * 30 - ((phase * 2) % 6)
            x = base_x + math.sin(t * 5 + phase * 2 * math.pi / frames + k) * 4
            r = 2.6 * (1 - t) + 0.6
            d.ellipse((x - r, y - r, x + r, y + r), fill=(70, 14, 96, int(140 * (1 - t) + 30)))
    return im.filter(ImageFilter.GaussianBlur(1.4))

def beast_aura(phase, frames=6):
    im = wisp_ring(phase, frames, (232, 248, 255), 14, 15, 3, 190, 2)
    d = ImageDraw.Draw(im)
    for k in range(5):
        a = 2 * math.pi * (k / 5 + phase / frames / 5)
        x, y = 32 + math.cos(a) * 16, 30 + math.sin(a) * 9 - (phase * 2 + k * 3) % 10
        d.point((round(x), round(y)), fill=(255, 255, 255, 230))
    return im

def decree_scroll():
    """A horizontal imperial edict: yellow silk between two dark rollers, red seal, columns of writing."""
    im, d = canvas(64)
    silk, silk_dark, silk_light, ink, roller, roller_light, red = (240, 196, 70), (196, 150, 40), (255, 230, 140), (120, 30, 20), (70, 30, 20), (140, 80, 50), (196, 30, 36)
    top, bottom = 22, 40
    d.rectangle((8, top, 55, bottom), fill=c(silk))
    d.line((8, top, 55, top), fill=c(silk_light)); d.line((8, bottom, 55, bottom), fill=c(silk_dark))
    d.rectangle((10, top + 2, 53, bottom - 2), outline=c(silk_dark))
    # dragon-cloud border hints
    for x in range(12, 52, 6):
        d.arc((x, top + 1, x + 4, top + 4), 180, 360, fill=c(silk_dark))
        d.arc((x, bottom - 4, x + 4, bottom - 1), 0, 180, fill=c(silk_dark))
    # columns of writing
    for x in range(16, 46, 4):
        for y in range(top + 5, bottom - 4, 3):
            if (x * 7 + y * 3) % 5:
                d.line((x, y, x + 1, y), fill=c(ink))
    d.rectangle((45, top + 9, 50, top + 14), fill=c(red))
    d.rectangle((46, top + 10, 49, top + 13), outline=c((255, 214, 160)))
    # rollers with knobs
    for x in (5, 56):
        d.rectangle((x, top - 2, x + 2, bottom + 2), fill=c(roller))
        d.line((x, top - 2, x, bottom + 2), fill=c(roller_light))
        d.rectangle((x - 1, top - 4, x + 3, top - 3), fill=c((214, 174, 80)))
        d.rectangle((x - 1, bottom + 3, x + 3, bottom + 4), fill=c((214, 174, 80)))
    body = outline(harden(im), OUTLINE)
    return compose(soft_glow((64, 64), [('ellipse', (2, 14, 62, 48))], (255, 220, 110), 4, 90), body)

def crater():
    """Cracked, sunken floor: a dark bowl with radial cracks and chunks of broken tile."""
    im = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((14, 18, 50, 46), fill=(30, 26, 24, 170))
    d.ellipse((20, 23, 44, 41), fill=(18, 15, 14, 200))
    rng = __import__('random').Random(13)
    for k in range(9):
        a = 2 * math.pi * k / 9 + rng.uniform(-0.2, 0.2)
        x, y = 32, 32
        for step in range(4):
            r = 8 + step * 5 + rng.uniform(0, 3)
            nx, ny = 32 + math.cos(a) * r, 32 + math.sin(a) * r * 0.75
            d.line((x, y, nx, ny), fill=(14, 12, 12, 230), width=1)
            x, y = nx, ny
            a += rng.uniform(-0.35, 0.35)
    for k in range(7):
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(16, 22)
        cx, cy = 32 + math.cos(a) * r, 32 + math.sin(a) * r * 0.75
        d.polygon([(cx - 2, cy), (cx, cy - 2), (cx + 2, cy + 1), (cx, cy + 2)], fill=(120, 116, 110, 230))
        d.point((round(cx), round(cy) - 1), fill=(170, 166, 160, 230))
    return im

def rubble(seed):
    im = Image.new('RGBA', (8, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rng = __import__('random').Random(seed)
    pts = [(rng.randint(1, 3), rng.randint(1, 3)), (rng.randint(4, 6), rng.randint(1, 3)), (rng.randint(4, 6), rng.randint(4, 6)), (rng.randint(1, 3), rng.randint(4, 6))]
    d.polygon(pts, fill=(118, 110, 100, 255))
    d.point(pts[0], fill=(170, 162, 150, 255))
    return outline(harden(im), (40, 34, 30, 255))

def body_hud(glow_phase=None):
    """Bronze medallion with a clenched fist: the body path's HUD meter. glow_phase animates the 'ready' pulse."""
    big = 128
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    dark, mid, light = (70, 40, 14), (196, 128, 56), (255, 226, 180)
    if glow_phase is not None:
        pulse = 0.5 + 0.5 * math.sin(glow_phase * 2 * math.pi / 8)
        halo = Image.new('RGBA', (big, big), (0, 0, 0, 0))
        ImageDraw.Draw(halo).ellipse((2, 2, big - 3, big - 3), fill=(255, 200, 90, int(90 + 120 * pulse)))
        im.alpha_composite(halo.filter(ImageFilter.GaussianBlur(8)))
    disc = radial((big, big), lerp(mid, light, 0.3), lerp(mid, dark, 0.5), center=(big * 0.4, big * 0.35), radius=big * 0.6)
    mask = Image.new('L', (big, big), 0)
    ImageDraw.Draw(mask).ellipse((10, 10, big - 11, big - 11), fill=255)
    im.paste(disc, (0, 0), mask)
    d = ImageDraw.Draw(im)
    d.ellipse((10, 10, big - 11, big - 11), outline=dark + (255,), width=7)
    font = ImageFont.truetype(FONT_BOLD, 64)
    bbox = d.textbbox((0, 0), '体', font=font)
    tx, ty = big / 2 - (bbox[2] - bbox[0]) / 2 - bbox[0], big / 2 - (bbox[3] - bbox[1]) / 2 - bbox[1]
    d.text((tx + 3, ty + 4), '体', font=font, fill=dark + (255,))
    d.text((tx, ty), '体', font=font, fill=(255, 246, 226, 255))
    return im.resize((32, 32), Image.LANCZOS)

def exhaustion_ring(band):
    """A red arc around the medallion, filling clockwise from the top in tenths."""
    big = 128
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    color = (120, 220, 120) if band < 5 else ((255, 160, 60) if band < 8 else (230, 40, 40))
    ImageDraw.Draw(im).arc((4, 4, big - 5, big - 5), -90, -90 + 36 * band, fill=color + (255,), width=12)
    return im.resize((32, 32), Image.LANCZOS)

# ---------------------------------------------------------------- write

merge_dmi(OUT + 'cultivation_actions.dmi', [(k, [medallion(*v)], 1) for k, v in TECHNIQUES.items()])

items = [
    ('manual_metal', [manual_cover((96, 104, 122), (60, 66, 80), emblem_metal)], 1),
    ('manual_water', [manual_cover((40, 80, 150), (22, 48, 96), emblem_water)], 1),
    ('manual_fire', [manual_cover((150, 36, 30), (96, 20, 16), emblem_fire)], 1),
    ('manual_earth', [manual_cover((130, 92, 44), (84, 56, 24), emblem_earth)], 1),
    ('manual_wood', [manual_cover((44, 96, 66), (26, 60, 40), emblem_wood)], 1),
    ('manual_demonic', [manual_demonic()], 1),
    ('manual_body_primer', [body_primer()], 1),
    ('manual_body', [body_manual()], 1),
    ('talisman', [talisman(lambda d: None)], 1),
    ('talisman_fire', [talisman(stamp_fire)], 1),
    ('talisman_binding', [talisman(stamp_binding)], 1),
    ('talisman_ward', [talisman(stamp_ward)], 1),
    ('talisman_light', [talisman(stamp_light)], 1),
    ('talisman_jiangshi', [talisman(stamp_jiangshi)], 1),
    ('cauldron', [cauldron()], 1),
    ('cauldron_lit', [cauldron(p) for p in range(4)], 2),
    ('guqin', [guqin()], 1),
    ('pill_marrow', [pill((236, 236, 226), (255, 255, 255), (170, 170, 160))], 1),
    ('pill_beast', [pill((150, 70, 40), (220, 140, 100), (90, 36, 20))], 1),
    ('pill_heart', [pill((240, 130, 170), (255, 210, 228), (170, 70, 110))], 1),
    ('pill_nine', [pill((236, 176, 30), (255, 240, 160), (150, 100, 10), ring=(255, 250, 220))], 1),
]
merge_dmi(OUT + 'cultivation_items.dmi', items)

merge_dmi(OUT + 'cultivation_effects_64.dmi', [
    ('heart_demon_aura', [heart_demon_aura(p) for p in range(6)], 1.5),
    ('beast_aura', [beast_aura(p) for p in range(6)], 1.5),
    ('decree_scroll', [decree_scroll()], 1),
    ('crater', [crater()], 1),
])

merge_dmi(OUT + 'cultivation_hud.dmi', [('body_display', [body_hud()], 1), ('body_display_ready', [body_hud(p) for p in range(8)], 1)] + \
    [(f'body_exhaustion_{band}', [exhaustion_ring(band)], 1) for band in range(1, 11)])

merge_dmi(OUT + 'cultivation_particles.dmi', [('rubble_1', [rubble(1)], 1), ('rubble_2', [rubble(2)], 1), ('rubble_3', [rubble(3)], 1)])

if os.environ.get('PREVIEW'):
    sheet = Image.new('RGBA', (40 * 12, 40 * 4), (60, 60, 70, 255))
    flat = [m for _, frames, _ in items for m in frames[:1]] + [medallion(*v) for v in TECHNIQUES.values()]
    for i, m in enumerate(flat):
        sheet.alpha_composite(m, ((i % 12) * 40 + 4, (i // 12) * 40 + 4))
    big = Image.new('RGBA', (64 * 3, 64), (60, 60, 70, 255))
    for i, m in enumerate([heart_demon_aura(0), beast_aura(0), decree_scroll()]):
        big.alpha_composite(m, (i * 64, 0))
    sheet = sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST)
    big = big.resize((big.width * 3, big.height * 3), Image.NEAREST)
    out = Image.new('RGBA', (max(sheet.width, big.width), sheet.height + big.height), (60, 60, 70, 255))
    out.paste(sheet, (0, 0)); out.paste(big, (0, sheet.height))
    out.save(os.environ['PREVIEW'])
