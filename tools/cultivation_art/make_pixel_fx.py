"""Crisp pixel-art effects: binding vines (growing, then swaying), bubbling mud, and the sword riding platform."""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(__file__))
from pixel import save_dmi, harden, outline, soft_glow, compose
from PIL import Image, ImageDraw

OUT = 'surfshack13/icons/cultivation/'
random.seed(7)

# ---------------- Binding vines (32x32) ----------------
VINE = (52, 140, 56, 255)
VINE_DARK = (30, 92, 38, 255)
VINE_LIGHT = (110, 196, 92, 255)
LEAF = (88, 186, 74, 255)
THORN = (214, 230, 170, 255)

def draw_vines(grow, sway=0.0):
    """Two thin vines coiling up around the legs, leaving the body visible."""
    im = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for k, (cx, offset, max_h) in enumerate(((12, 0.0, 17), (20, 2.4, 15))):
        h = int(max_h * grow)
        if h < 2:
            continue
        pts = []
        for i in range(h):
            y = 31 - i
            x = cx + math.sin(i / 2.2 + offset) * 3 + sway * (i / max_h) * (1 if k else -1)
            pts.append((round(x), y))
        for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
            d.line((x1, y1, x2, y2), fill=VINE)
        for j in range(4, h, 6):
            x, y = pts[j]
            side = 1 if (j // 6 + k) % 2 else -1
            d.point((x + side, y - 1), fill=LEAF)
            d.point((x + 2 * side, y - 1), fill=LEAF)
            d.point((x + side, y - 2), fill=LEAF)
        if grow >= 1:
            tx, ty = pts[-1]
            d.point((tx + 1, ty - 1), fill=VINE_LIGHT)
            d.point((tx + 2, ty), fill=VINE_LIGHT)
    root = int(5 * min(grow * 2, 1))
    if root:
        d.line((16 - root - 3, 31, 16 + root + 3, 31), fill=VINE_DARK)
    im = harden(im, 80)
    return outline(im, (18, 50, 22, 255))

grow_frames = [draw_vines(g) for g in (0.15, 0.35, 0.6, 0.85, 1.0)]
sway_frames = [draw_vines(1.0, s) for s in (0.0, 1.0, 0.0, -1.0)]

# ---------------- Bubbling mud (32x32) ----------------
MUD = (92, 62, 34, 230)
MUD_DARK = (60, 38, 20, 240)
MUD_LIGHT = (140, 102, 60, 255)

def mud_frame(t):
    im = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 31, 31), fill=MUD)
    rnd = random.Random(3)
    for _ in range(14):
        x, y, r = rnd.randint(2, 29), rnd.randint(2, 29), rnd.randint(2, 4)
        d.ellipse((x - r, y - r, x + r, y + r), fill=MUD_DARK)
    for _ in range(10):
        x, y = rnd.randint(1, 30), rnd.randint(1, 30)
        d.point((x, y), fill=MUD_LIGHT)
    # bubbles rising and popping
    for k, (bx, by) in enumerate(((8, 10), (22, 18), (14, 25), (25, 6))):
        phase = (t + k * 0.25) % 1
        r = 1 + int(phase * 3)
        if phase < 0.8:
            d.ellipse((bx - r, by - r, bx + r, by + r), outline=MUD_LIGHT)
            d.point((bx - r + 1, by - r + 1), fill=(200, 170, 120, 255))
        else:
            d.point((bx - 2, by), fill=MUD_LIGHT); d.point((bx + 2, by), fill=MUD_LIGHT); d.point((bx, by - 2), fill=MUD_LIGHT)
    return im

mud_frames = [mud_frame(i / 6) for i in range(6)]

# ---------------- Molten footprints (32x32), cooling from white-hot to black ----------------
def molten(t):
    """t = 0 fresh (white-hot) .. 1 cooled (dark rock)."""
    im = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rock = (int(60 - 20 * t), int(36 - 14 * t), int(30 - 12 * t), int(220 - 80 * t))
    hot = [(255, 250, 210), (255, 214, 90), (255, 140, 40), (190, 50, 20), (90, 30, 20)]
    vein = hot[min(int(t * 5), 4)]
    # two footprints
    for fx, fy in ((11, 12), (20, 21)):
        d.ellipse((fx - 4, fy - 6, fx + 4, fy + 5), fill=rock)
        d.ellipse((fx - 3, fy + 4, fx + 3, fy + 9), fill=rock)
        # glowing cracks
        d.line((fx - 2, fy - 4, fx + 1, fy, fx - 1, fy + 3, fx + 2, fy + 7), fill=vein + (255,))
        d.line((fx + 1, fy, fx + 3, fy - 2), fill=vein + (255,))
    im = harden(im, 60)
    if t < 0.7:
        glow = soft_glow((32, 32), [('ellipse', (4, 4, 28, 30))], (255, 120, 30), 3, int(150 * (1 - t)))
        return compose(glow, im)
    return im

molten_frames = [molten(t / 7) for t in range(8)]

# ---------------- Sword riding platform (64x64, crisp) ----------------
BLADE = (214, 230, 248, 255)
BLADE_EDGE = (255, 255, 255, 255)
BLADE_SHADE = (150, 170, 200, 255)
GOLD = (222, 176, 64, 255)
GOLD_DARK = (150, 104, 26, 255)
GRIP = (120, 36, 30, 255)
GRIP_LIGHT = (176, 70, 58, 255)
TASSEL = (210, 40, 52, 255)

def sword_ride(phase):
    y = 48
    body = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(body)
    # blade pointing right, 3px tall
    d.polygon([(58, y), (52, y - 2), (24, y - 2), (24, y + 2), (52, y + 2)], fill=BLADE)
    d.line((25, y + 1, 53, y + 1), fill=BLADE_SHADE)
    d.line((25, y - 1, 54, y - 1), fill=BLADE_EDGE)
    gx = 26 + int(26 * phase)
    d.point((gx, y - 1), fill=(255, 255, 255, 255)); d.point((gx + 1, y), fill=(255, 255, 255, 255))
    # guard
    d.rectangle((21, y - 4, 23, y + 4), fill=GOLD)
    d.point((22, y - 4), fill=GOLD_DARK); d.point((22, y + 4), fill=GOLD_DARK)
    # grip with wrap
    d.rectangle((13, y - 1, 20, y + 1), fill=GRIP)
    for x in range(14, 20, 2):
        d.point((x, y - 1), fill=GRIP_LIGHT)
    # pommel
    d.rectangle((10, y - 2, 12, y + 2), fill=GOLD)
    # tassel fluttering behind
    sway = round(math.sin(phase * 2 * math.pi) * 1.5)
    d.line((10, y + 1, 5, y + 4 + sway), fill=TASSEL)
    d.line((10, y + 2, 7, y + 6 + sway), fill=TASSEL)
    body = outline(harden(body), (28, 34, 52, 255))
    shimmer = (math.sin(phase * 2 * math.pi) + 1) / 2
    glow = soft_glow((64, 64), [('ellipse', (14, y - 7, 60, y + 7))], (150, 210, 255), 3, int(110 + 70 * shimmer))
    trail = soft_glow((64, 64), [('polygon', [(0, y - 1), (12, y - 3), (12, y + 3), (0, y + 1)])], (170, 220, 255), 2, int(90 + 60 * shimmer))
    glow.alpha_composite(trail)
    return compose(glow, body)

CLOUD = (255, 240, 200, 255)
CLOUD_SHADE = (240, 206, 140, 255)
CLOUD_LINE = (214, 150, 50, 255)

def qi_cloud(phase):
    y = 48
    body = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(body)
    puffs = [(18, y, 7), (27, y - 3, 8), (37, y - 3, 8), (46, y, 7), (32, y + 3, 8), (24, y + 3, 6), (41, y + 3, 6)]
    for i, (x, py, r) in enumerate(puffs):
        dx = round(math.sin(phase * 2 * math.pi + i))
        d.ellipse((x - r + dx, py - r * 0.6, x + r + dx, py + r * 0.6), fill=CLOUD)
    d.line((14, y + 4, 50, y + 4), fill=CLOUD_SHADE)
    # auspicious swirls
    for sx, sy in ((26, y - 1), (38, y - 1)):
        d.arc((sx - 3, sy - 2, sx + 3, sy + 2), 180, 450, fill=CLOUD_LINE)
        d.point((sx, sy), fill=CLOUD_LINE)
    # trailing wisps
    d.line((4, y + 2, 12, y), fill=CLOUD_SHADE)
    d.line((6, y + 5, 13, y + 3), fill=CLOUD_SHADE)
    body = outline(harden(body), (150, 100, 30, 255))
    shimmer = (math.sin(phase * 2 * math.pi) + 1) / 2
    glow = soft_glow((64, 64), [('ellipse', (8, y - 10, 56, y + 9))], (255, 214, 110), 3, int(90 + 70 * shimmer))
    return compose(glow, body)

save_dmi(OUT + 'cultivation_riding.dmi', [
    ('sword_ride', [sword_ride(i / 6) for i in range(6)], 1),
    ('qi_cloud', [qi_cloud(i / 6) for i in range(6)], 2),
], (64, 64))
save_dmi(OUT + 'cultivation_terrain.dmi', [
    ('vines_grow', grow_frames, 1),
    ('vines_sway', sway_frames, 3),
    ('mud', mud_frames, 2),
    ('molten_steps', molten_frames, [3, 3, 4, 5, 6, 8, 10, 60]),
], (32, 32))

if len(sys.argv) > 1:
    prev = Image.new('RGBA', (32 * 15 + 128, 64), (60, 62, 70, 255))
    for i, f in enumerate(grow_frames + sway_frames + mud_frames[:2] + molten_frames[::2]):
        prev.alpha_composite(f, (32 * i, 16))
    prev.alpha_composite(sword_ride(0.3), (32 * 15, 0))
    prev.alpha_composite(qi_cloud(0.3), (32 * 15 + 64, 0))
    prev.resize((prev.width * 3, prev.height * 3), Image.NEAREST).save(sys.argv[1])
print('ok')
