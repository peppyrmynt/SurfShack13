"""Native pixel weapons in tg's style: long corner-to-corner diagonals, blades shaded by highlight/shade rows,
no black outline, no glow blob. Replaces the sword and staff states in cultivation_artifacts.dmi, keeps the rest."""
import sys, os, re, math
sys.path.insert(0, os.path.dirname(__file__))
from pixel import save_dmi
from PIL import Image

OUT = 'surfshack13/icons/cultivation/cultivation_artifacts.dmi'

def read_dmi(path):
    im = Image.open(path)
    desc = im.info['Description']
    w = int(re.search(r'width = (\d+)', desc).group(1))
    h = int(re.search(r'height = (\d+)', desc).group(1))
    cols = im.width // w
    states, idx = [], 0
    for block in desc.split('state = ')[1:]:
        name = block.split('"')[1]
        frames = int(re.search(r'frames = (\d+)', block).group(1))
        delay_match = re.search(r'delay = ([\d,.]+)', block)
        delay = [int(float(x)) for x in delay_match.group(1).split(',')] if delay_match else 1
        crops = [im.crop(((i % cols) * w, (i // cols) * h, (i % cols) * w + w, (i // cols) * h + h)) for i in range(idx, idx + frames)]
        states.append([name, crops, delay])
        idx += frames
    return states

class Px:
    def __init__(self):
        self.im = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
        self.px = self.im.load()
    def put(self, x, y, c, a=255):
        if 0 <= x < 32 and 0 <= y < 32:
            self.px[x, y] = tuple(c[:3]) + (a,)

def rows(p, start, length, offsets_colors, taper_from=None):
    """Draw solid parallel rows along a 45 degree diagonal. offsets_colors: list of ((dx, dy), color)."""
    sx, sy = start
    for i in range(length):
        x, y = sx + i, sy - i
        for (dx, dy), color in offsets_colors:
            if taper_from is not None and i >= taper_from and (dx, dy) != (0, 0):
                continue
            p.put(x + dx, y + dy, color)

def shades(base, steps=(-0.35, 0.0, 0.25, 0.55)):
    out = []
    for k in steps:
        if k < 0:
            out.append(tuple(int(c * (1 + k)) for c in base))
        else:
            out.append(tuple(int(c + (255 - c) * k) for c in base))
    return out

def sword(blade, guard_base, grip_a, grip_b, tassel, phase, length=19, wide=False, gem=None, ridge=None, rune=None, aura=None):
    """An oriental jian. Hilt bottom-left, tip top-right. Rows on a 45 degree line: index = dx + dy."""
    p = Px()
    gx, gy = 8, 23
    shade, mid, light, edge = shades(blade)
    rowset = [((-1, 0), light), ((0, 0), mid), ((1, 0), shade)]
    if wide:
        rowset = [((-1, 0), edge), ((0, 0), light), ((1, 0), mid), ((2, 0), shade)]
    rows(p, (gx + 1, gy - 1), length, rowset, taper_from=length - 2)
    # central ridge in a contrasting colour (a fuller running up the blade)
    ridge_row = (0, 0) if not wide else (1, 0)
    if ridge:
        for i in range(3, length - 2):
            p.put(gx + 1 + i + ridge_row[0], gy - 1 - i, ridge)
    # engraved runes near the guard
    if rune:
        for i in (1, 3):
            p.put(gx + 1 + i + ridge_row[0], gy - 1 - i, rune)
    p.put(gx + length + 1, gy - length - 1, edge)
    # glint racing up the blade
    gi = 2 + int((length - 5) * phase)
    p.put(gx + gi, gy - gi - 1, (255, 255, 255))
    p.put(gx + gi + 1, gy - gi - 2, (255, 255, 240), 150)
    # cloud-shaped crossguard: ends curl toward the blade, jewel in the middle
    g_dark, g_mid, g_light, g_pale = shades(guard_base)
    for k in range(-3, 4):
        p.put(gx + k, gy + k, g_light if k <= 0 else g_mid)
    for k in (-3, 3):
        p.put(gx + k + 1, gy + k - 1, g_mid)              # curl toward the blade
        p.put(gx + k + 1 + (1 if k > 0 else 0), gy + k - 2 + (1 if k > 0 else 0), g_pale if k < 0 else g_dark)
    p.put(gx + 4, gy + 3, g_dark)
    p.put(gx + 1, gy - 1, g_mid)                          # centre bump toward the blade
    if gem:
        p.put(gx, gy, gem); p.put(gx + 1, gy, tuple(int(c * 0.7) for c in gem))
    # slim wrapped grip
    for i in range(1, 5):
        p.put(gx - i, gy + i, grip_a if i % 2 else grip_b)
        p.put(gx - i + 1, gy + i, grip_b if i % 2 else grip_a)
    # ring pommel (hollow)
    for dx, dy in ((-5, 5), (-7, 5), (-6, 4), (-6, 6), (-5, 4), (-7, 6)):
        p.put(gx + dx, gy + dy, g_mid if dy < 6 else g_dark)
    p.put(gx - 6, gy + 4, g_pale)
    # long knotted tassel, swaying
    if tassel:
        sway = round(math.sin(phase * 2 * math.pi))
        t_dark = tuple(int(c * 0.72) for c in tassel)
        t_light = tuple(min(int(c * 1.25), 255) for c in tassel)
        p.put(gx - 7, gy + 7, t_light); p.put(gx - 6, gy + 7, tassel)   # knot
        for k in range(1, 5):
            off = sway if k >= 3 else 0
            p.put(gx - 7 + off, gy + 7 + k, tassel)
            p.put(gx - 6 + off, gy + 7 + k, t_dark)
        p.put(gx - 7 + sway, gy + 12, t_dark)
    if aura:
        # a soft pulsing band of sword qi along the blade, under the sprite
        from pixel import soft_glow, compose
        pulse = (math.sin(phase * 2 * math.pi) + 1) / 2
        band = soft_glow((32, 32), [('polygon', [(gx + 2, gy - 4), (gx + length - 1, gy - length - 1), (gx + length + 2, gy - length + 2), (gx + 4, gy - 1)])], aura, 1.5, int(55 + 55 * pulse))
        return compose(band, p.im)
    return p.im

def dragon_saber(phase):
    """Broad dao: dark spine on the upper-left, steel body, gold dragon line, bright edge bellying out on the lower-right."""
    p = Px()
    gx, gy = 8, 23
    length = 19
    spine, steel, steel_light, edge = (34, 32, 42), (72, 70, 86), (124, 122, 140), (226, 228, 240)
    gold, gold_light = (226, 176, 56), (255, 226, 130)
    for i in range(1, length + 1):
        x, y = gx + i, gy - i
        belly = 1 + (1 if 3 < i < length - 1 else 0) + (1 if 7 < i < length - 3 else 0)
        if i >= length - 1:
            belly = 0
        p.put(x - 1, y, spine)                        # row -1: spine
        p.put(x, y, gold if 3 <= i <= length - 4 and i % 4 else (gold_light if 3 <= i <= length - 4 else steel))  # row 0: dragon
        for k in range(1, belly + 1):
            p.put(x + k, y, steel if k < belly else steel_light)
        p.put(x + belly + 1, y, edge)                 # bright cutting edge
    p.put(gx + length + 1, gy - length - 1, edge)
    gi = 3 + int((length - 7) * phase)
    p.put(gx + gi + 3, gy - gi, (255, 255, 255))
    for dx, dy, c in ((0, 0, gold_light), (-1, 1, gold), (1, -1, gold), (-1, -1, gold_light), (1, 1, gold), (-2, 0, gold), (0, 2, gold), (2, 0, gold), (0, -2, gold_light)):
        p.put(gx + dx, gy + dy, c)
    for i in range(2, 6):
        p.put(gx - i, gy + i, (150, 26, 26) if i % 2 else (196, 54, 46))
        p.put(gx - i + 1, gy + i, (110, 18, 18))
    p.put(gx - 6, gy + 6, gold); p.put(gx - 7, gy + 6, gold); p.put(gx - 6, gy + 7, gold_light)
    return p.im

def ruyi_staff(phase):
    p = Px()
    red_shade, red, red_light, _ = shades((196, 40, 30))
    gold_shade, gold, gold_light, gold_pale = shades((230, 182, 60), (-0.3, 0.0, 0.3, 0.6))
    start, n = (2, 29), 27
    for i in range(n + 1):
        x, y = start[0] + i, start[1] - i
        cap = i < 5 or i > n - 5
        dark, core, light = (gold_shade, gold, gold_light) if cap else (red_shade, red, red_light)
        p.put(x - 1, y, light); p.put(x, y, core); p.put(x + 1, y, dark)
        if cap and i in (2, n - 2):
            p.put(x, y, gold_shade); p.put(x - 1, y, gold)
    for i in range(8, n - 7, 3):
        p.put(start[0] + i, start[1] - i, gold_pale)
    gi = 2 + int((n - 4) * phase)
    p.put(start[0] + gi - 1, start[1] - gi, (255, 255, 255))
    return p.im

FR = 6
def anim(fn):
    return [fn(i / FR) for i in range(FR)]

replacements = {
    'ganjiang': anim(lambda t: sword((84, 100, 156), (220, 172, 60), (40, 30, 34), (82, 64, 60), (54, 104, 220), t,
        gem=(110, 170, 255), ridge=(196, 160, 70), rune=(150, 200, 255), aura=(110, 160, 255))),
    'moye': anim(lambda t: sword((200, 210, 230), (220, 172, 60), (150, 26, 38), (200, 64, 74), (226, 46, 58), t,
        gem=(240, 70, 90), ridge=(236, 236, 248), rune=(230, 80, 96), aura=(255, 120, 140))),
    'heaven_reliant': anim(lambda t: sword((176, 222, 202), (84, 172, 132), (28, 64, 52), (64, 124, 100), (246, 246, 246), t, length=20, wide=True,
        gem=(240, 255, 250), ridge=(255, 255, 255), rune=(214, 186, 90), aura=(220, 255, 240))),
    'dragon_saber': anim(dragon_saber),
    'ruyi_staff': anim(ruyi_staff),
}

states = read_dmi(OUT)
for state in states:
    if state[0] in replacements:
        state[1] = replacements[state[0]]
        state[2] = 2
save_dmi(OUT, [tuple(s) for s in states], (32, 32))

if len(sys.argv) > 1:
    names = ['ganjiang', 'moye', 'heaven_reliant', 'dragon_saber', 'ruyi_staff']
    prev = Image.new('RGBA', (32 * 5, 32), (60, 62, 70, 255))
    for i, n in enumerate(names):
        prev.alpha_composite(replacements[n][2], (32 * i, 0))
    prev.resize((prev.width * 5, prev.height * 5), Image.NEAREST).save(sys.argv[1])
print('ok')
