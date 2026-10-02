"""HD legendary artifacts: drawn at 256px with gradients, engravings and highlights, downscaled to 32px,
then re-sharpened with a crisp alpha edge and outline so they keep detail without looking blurry."""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from pixel import save_dmi, outline, soft_glow, compose
from PIL import Image, ImageDraw, ImageFilter, ImageChops

OUT = 'surfshack13/icons/cultivation/'
S = 256

# ---------------------------------------------------------------- helpers
def blank():
    return Image.new('RGBA', (S, S), (0, 0, 0, 0))

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))

def gradient(size, stops, angle_deg):
    """Linear gradient image. stops: list of (t, rgb). angle 0 = left->right, 90 = top->bottom."""
    w, h = size
    g = Image.new('RGBA', size)
    px = g.load()
    a = math.radians(angle_deg)
    dx, dy = math.cos(a), math.sin(a)
    proj = [x * dx + y * dy for x, y in ((0, 0), (w, 0), (0, h), (w, h))]
    lo, hi = min(proj), max(proj)
    for y in range(h):
        for x in range(w):
            t = ((x * dx + y * dy) - lo) / (hi - lo)
            for (t0, c0), (t1, c1) in zip(stops, stops[1:]):
                if t0 <= t <= t1:
                    k = (t - t0) / (t1 - t0) if t1 > t0 else 0
                    px[x, y] = lerp(c0, c1, k) + (255,)
                    break
            else:
                px[x, y] = (stops[-1][1] if t > stops[-1][0] else stops[0][1]) + (255,)
    return g

def fill_shape(im, draw_mask, stops, angle):
    """Fill a shape (drawn by draw_mask(ImageDraw) on an L mask) with a gradient."""
    mask = Image.new('L', (S, S), 0)
    draw_mask(ImageDraw.Draw(mask))
    bbox = mask.getbbox()
    if not bbox:
        return
    grad = gradient((bbox[2] - bbox[0], bbox[3] - bbox[1]), stops, angle)
    layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    layer.paste(grad, bbox[:2])
    im.paste(layer, (0, 0), mask)

def rot(im, deg):
    return im.rotate(deg, resample=Image.BICUBIC, center=(S / 2, S / 2))

def to_sprite(big, line=(22, 18, 26, 255), glow=None):
    """256 -> 32 with detail kept: Lanczos downscale, unsharp, alpha snapped to crisp, 1px outline, optional glow."""
    small = big.resize((32, 32), Image.LANCZOS)
    r, g, b, a = small.split()
    rgb = Image.merge('RGB', (r, g, b)).filter(ImageFilter.UnsharpMask(radius=1, percent=90, threshold=1))
    a = a.point(lambda v: 255 if v >= 96 else 0)
    small = Image.merge('RGBA', (*rgb.split(), a))
    small = outline(small, line)
    if glow:
        color, box, blur, alpha = glow
        small = compose(soft_glow((32, 32), [('ellipse', box)], color, blur, alpha), small)
    return small

def sparkle(im, x, y, strength=1.0):
    d = ImageDraw.Draw(im)
    a = int(255 * strength)
    d.point((x, y), fill=(255, 255, 255, a))
    for k, fade in ((1, 0.75), (2, 0.35)):
        for dx, dy in ((k, 0), (-k, 0), (0, k), (0, -k)):
            if 0 <= x + dx < 32 and 0 <= y + dy < 32:
                d.point((x + dx, y + dy), fill=(255, 250, 230, int(a * fade)))
    return im

# ---------------------------------------------------------------- swords
def jian(blade_stops, ridge, guard_stops, gem, grip_a, grip_b, tassel, pommel_stops, length=190, width=26, engraving=None):
    """A straight jian pointing right, drawn horizontally at 256 then rotated 45 degrees."""
    im = blank()
    cy = S / 2
    x0 = 50
    tip = x0 + length
    # blade with a cross-section gradient (light upper bevel, dark lower bevel)
    fill_shape(im, lambda d: d.polygon([(x0, cy - width / 2), (tip - 26, cy - width / 2), (tip, cy), (tip - 26, cy + width / 2), (x0, cy + width / 2)], fill=255), blade_stops, 90)
    d = ImageDraw.Draw(im)
    d.line((x0 + 4, cy, tip - 6, cy), fill=ridge + (255,), width=3)           # central ridge
    d.line((x0 + 4, cy - width / 2 + 2, tip - 28, cy - width / 2 + 2), fill=(255, 255, 255, 230), width=2)  # edge highlight
    if engraving:
        for i in range(5):
            ex = x0 + 18 + i * 14
            d.line((ex, cy - 5, ex + 6, cy + 5), fill=engraving + (255,), width=3)
    # guard: a cloud-shaped crossguard with a gem
    fill_shape(im, lambda d: d.polygon([(x0 - 4, cy - 34), (x0 + 10, cy - 24), (x0 + 10, cy + 24), (x0 - 4, cy + 34), (x0 - 18, cy + 22), (x0 - 18, cy - 22)], fill=255), guard_stops, 0)
    d.ellipse((x0 - 12, cy - 8, x0 + 4, cy + 8), fill=gem + (255,))
    d.ellipse((x0 - 9, cy - 6, x0 - 4, cy - 1), fill=(255, 255, 255, 220))
    # grip: diamond wrap
    d.rectangle((x0 - 62, cy - 9, x0 - 18, cy + 9), fill=grip_a + (255,))
    for gx in range(int(x0 - 62), int(x0 - 18), 10):
        d.line((gx, cy - 9, gx + 10, cy + 9), fill=grip_b + (255,), width=3)
        d.line((gx, cy + 9, gx + 10, cy - 9), fill=grip_b + (255,), width=3)
    # pommel
    fill_shape(im, lambda d: d.ellipse((x0 - 80, cy - 14, x0 - 58, cy + 14), fill=255), pommel_stops, 45)
    # tassel
    if tassel:
        d.ellipse((x0 - 90, cy + 4, x0 - 78, cy + 16), fill=tassel + (255,))
        for k in range(4):
            d.line((x0 - 86 + k * 3, cy + 14, x0 - 100 + k * 5, cy + 52), fill=lerp(tassel, (255, 255, 255), 0.15 * k) + (255,), width=4)
    return rot(im, 45)

def ganjiang():
    return jian(blade_stops=[(0, (150, 168, 220)), (0.45, (72, 84, 130)), (1, (26, 30, 56))], ridge=(36, 42, 80),
                guard_stops=[(0, (120, 86, 26)), (0.5, (230, 186, 70)), (1, (130, 92, 28))], gem=(70, 120, 230),
                grip_a=(40, 30, 34), grip_b=(90, 70, 60), tassel=(40, 90, 210), pommel_stops=[(0, (250, 210, 100)), (1, (140, 96, 26))],
                engraving=(110, 140, 210))

def moye():
    return jian(blade_stops=[(0, (255, 255, 255)), (0.45, (214, 222, 238)), (1, (140, 150, 176))], ridge=(170, 180, 204),
                guard_stops=[(0, (130, 92, 28)), (0.5, (244, 204, 96)), (1, (130, 92, 28))], gem=(220, 50, 70),
                grip_a=(130, 22, 34), grip_b=(190, 60, 70), tassel=(222, 40, 52), pommel_stops=[(0, (255, 220, 120)), (1, (150, 104, 30))],
                engraving=(220, 120, 140))

def heaven_reliant():
    return jian(blade_stops=[(0, (255, 255, 255)), (0.4, (226, 246, 236)), (1, (130, 186, 162))], ridge=(150, 210, 186),
                guard_stops=[(0, (40, 110, 84)), (0.5, (120, 210, 170)), (1, (40, 110, 84))], gem=(230, 250, 255),
                grip_a=(28, 64, 52), grip_b=(70, 130, 106), tassel=(246, 246, 246), pommel_stops=[(0, (190, 240, 216)), (1, (50, 120, 94))],
                length=200, width=24, engraving=(120, 200, 170))

def dragon_saber():
    im = blank()
    cy = S / 2 - 10
    x0 = 66
    # broad dao: straight spine, belly curving to the point
    blade = [(x0, cy - 22), (x0 + 150, cy - 26), (x0 + 182, cy - 18), (x0 + 168, cy + 10), (x0 + 120, cy + 34), (x0, cy + 30)]
    fill_shape(im, lambda d: d.polygon(blade, fill=255), [(0, (110, 106, 120)), (0.35, (46, 44, 54)), (1, (18, 16, 22))], 90)
    d = ImageDraw.Draw(im)
    d.line([(x0 + 4, cy + 27), (x0 + 118, cy + 31), (x0 + 166, cy + 9), (x0 + 178, cy - 16)], fill=(236, 238, 246, 255), width=4)  # bright edge
    d.line((x0 + 2, cy - 20, x0 + 150, cy - 24), fill=(150, 146, 160, 255), width=3)  # spine
    # golden dragon coiling along the blade
    pts = [(x0 + 12 + k * 9, cy + 4 + math.sin(k / 2.0) * 12) for k in range(16)]
    d.line(pts, fill=(170, 112, 24, 255), width=9)
    d.line(pts, fill=(250, 204, 80, 255), width=5)
    for k in range(1, 15, 2):
        x, y = pts[k]
        d.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(255, 236, 150, 255))
    hx, hy = pts[-1]
    d.polygon([(hx, hy - 9), (hx + 18, hy - 2), (hx, hy + 9)], fill=(250, 204, 80, 255))
    d.ellipse((hx + 4, hy - 4, hx + 9, hy + 1), fill=(220, 30, 30, 255))
    # ring on the spine
    d.ellipse((x0 + 90, cy - 40, x0 + 108, cy - 22), outline=(230, 186, 70, 255), width=4)
    # round guard
    fill_shape(im, lambda d: d.ellipse((x0 - 16, cy - 36, x0 + 6, cy + 40), fill=255), [(0, (250, 210, 100)), (1, (130, 86, 20))], 0)
    # grip and pommel
    d.rectangle((x0 - 66, cy - 9, x0 - 14, cy + 11), fill=(120, 20, 22, 255))
    for gx in range(int(x0 - 66), int(x0 - 14), 10):
        d.line((gx, cy - 9, gx + 10, cy + 11), fill=(180, 50, 46, 255), width=3)
    fill_shape(im, lambda d: d.ellipse((x0 - 86, cy - 14, x0 - 62, cy + 16), fill=255), [(0, (250, 210, 100)), (1, (130, 86, 20))], 45)
    return rot(im, 40)

def ruyi_staff():
    im = blank()
    cy = S / 2
    # red lacquered shaft with cylindrical shading
    fill_shape(im, lambda d: d.rectangle((40, cy - 13, 216, cy + 13), fill=255), [(0, (110, 14, 10)), (0.35, (226, 60, 44)), (0.5, (250, 120, 96)), (0.7, (196, 34, 24)), (1, (90, 10, 8))], 90)
    d = ImageDraw.Draw(im)
    # golden bands
    for x0, x1 in ((14, 58), (198, 242)):
        fill_shape(im, lambda dd, a=x0, b=x1: dd.rounded_rectangle((a, cy - 19, b, cy + 19), 6, fill=255), [(0, (150, 100, 20)), (0.4, (255, 226, 120)), (0.55, (255, 246, 200)), (1, (140, 92, 18))], 90)
        for bx in range(x0 + 6, x1 - 2, 9):
            d.line((bx, cy - 18, bx, cy + 18), fill=(170, 112, 24, 255), width=2)
    # engraved inscription strip
    for k in range(10):
        x = 76 + k * 12
        d.rectangle((x, cy - 4, x + 6, cy + 4), fill=(255, 210, 90, 255))
    return rot(im, 45)

def ruyi_needle():
    im = blank()
    d = ImageDraw.Draw(im)
    cy = S / 2
    fill_shape(im, lambda dd: dd.rectangle((70, cy - 6, 186, cy + 6), fill=255), [(0, (150, 100, 20)), (0.5, (255, 240, 170)), (1, (150, 100, 20))], 90)
    d.rectangle((70, cy - 8, 84, cy + 8), fill=(200, 40, 30, 255))
    d.rectangle((172, cy - 8, 186, cy + 8), fill=(200, 40, 30, 255))
    return rot(im, 45)

# ---------------------------------------------------------------- treasures
def gourd():
    im = blank()
    fill_shape(im, lambda d: d.ellipse((50, 104, 206, 248), fill=255), [(0, (220, 160, 255)), (0.35, (150, 70, 200)), (1, (60, 18, 90))], 60)
    fill_shape(im, lambda d: d.ellipse((84, 34, 172, 120), fill=255), [(0, (220, 160, 255)), (0.35, (150, 70, 200)), (1, (60, 18, 90))], 60)
    d = ImageDraw.Draw(im)
    # gold band and gold inlay patterns
    fill_shape(im, lambda dd: dd.rectangle((92, 106, 164, 124), fill=255), [(0, (150, 100, 20)), (0.5, (255, 230, 130)), (1, (150, 100, 20))], 90)
    # gold medallion with a dragon-scale ring
    d.ellipse((104, 150, 152, 198), outline=(255, 214, 110, 255), width=6)
    d.polygon([(128, 160), (142, 174), (128, 188), (114, 174)], fill=(255, 214, 110, 255))
    for k in range(10):
        a = math.radians(k * 36)
        d.ellipse((128 + math.cos(a) * 40 - 4, 174 + math.sin(a) * 40 - 4, 128 + math.cos(a) * 40 + 4, 174 + math.sin(a) * 40 + 4), fill=(240, 196, 90, 255))
    # highlights
    d.ellipse((80, 130, 110, 160), fill=(250, 220, 255, 170))
    d.ellipse((102, 50, 120, 68), fill=(250, 220, 255, 170))
    # cork and tassel
    fill_shape(im, lambda dd: dd.rounded_rectangle((110, 8, 146, 40), 6, fill=255), [(0, (190, 140, 80)), (1, (100, 64, 30))], 0)
    d.line((156, 112, 196, 150), fill=(200, 26, 40, 255), width=7)
    for k in range(4):
        d.line((194, 150, 186 + k * 7, 196), fill=(226, 50, 60, 255), width=4)
    return im

def plantain_fan():
    im = blank()
    fill_shape(im, lambda d: d.ellipse((28, 6, 228, 182), fill=255), [(0, (150, 220, 110)), (0.5, (80, 160, 64)), (1, (34, 90, 30))], 70)
    d = ImageDraw.Draw(im)
    d.line((128, 178, 128, 20), fill=(46, 110, 40, 255), width=6)
    for a in range(-70, 71, 14):
        r = math.radians(a - 90)
        d.line((128, 170, 128 + math.cos(r) * 100, 96 + math.sin(r) * 82), fill=(52, 120, 46, 255), width=3)
    d.arc((28, 6, 228, 182), 200, 300, fill=(200, 250, 160, 255), width=5)
    # handle, binding and tassel
    fill_shape(im, lambda dd: dd.rounded_rectangle((116, 170, 140, 250), 6, fill=255), [(0, (200, 150, 90)), (1, (110, 70, 32))], 0)
    fill_shape(im, lambda dd: dd.ellipse((104, 158, 152, 196), fill=255), [(0, (255, 226, 120)), (1, (150, 100, 20))], 45)
    return im

def bagua_mirror(phase):
    im = blank()
    c = S / 2
    pts = [(c + math.cos(math.radians(22.5 + i * 45)) * 118, c + math.sin(math.radians(22.5 + i * 45)) * 118) for i in range(8)]
    fill_shape(im, lambda d: d.polygon(pts, fill=255), [(0, (240, 190, 100)), (0.5, (176, 116, 44)), (1, (90, 52, 14))], 45)
    d = ImageDraw.Draw(im)
    inner = [(c + math.cos(math.radians(22.5 + i * 45)) * 100, c + math.sin(math.radians(22.5 + i * 45)) * 100) for i in range(8)]
    d.polygon(inner, outline=(110, 66, 18, 255))
    trigrams = ['111', '011', '101', '001', '110', '010', '100', '000']
    for i, tri in enumerate(trigrams):
        a = math.radians(i * 45 - 90)
        for j, bit in enumerate(tri):
            rr = 92 - j * 14
            x, y = c + math.cos(a) * rr, c + math.sin(a) * rr
            px, py = -math.sin(a) * 20, math.cos(a) * 20
            col = (70, 38, 10, 255)
            if bit == '1':
                d.line((x - px, y - py, x + px, y + py), fill=col, width=8)
            else:
                d.line((x - px, y - py, x - px * 0.25, y - py * 0.25), fill=col, width=8)
                d.line((x + px * 0.25, y + py * 0.25, x + px, y + py), fill=col, width=8)
    # mirror face with a sweeping reflection
    fill_shape(im, lambda dd: dd.ellipse((c - 46, c - 46, c + 46, c + 46), fill=255), [(0, (255, 255, 255)), (0.5, (190, 214, 232)), (1, (110, 140, 170))], 135)
    d.ellipse((c - 46, c - 46, c + 46, c + 46), outline=(255, 214, 110, 255), width=6)
    sweep = -40 + phase * 80
    d.line((c + sweep - 16, c - 30, c + sweep + 10, c + 30), fill=(255, 255, 255, 230), width=10)
    return im

def qiankun_pouch(phase):
    im = blank()
    fill_shape(im, lambda d: d.ellipse((40, 86, 216, 246), fill=255), [(0, (110, 140, 220)), (0.4, (44, 66, 150)), (1, (14, 22, 60))], 60)
    fill_shape(im, lambda d: d.polygon([(76, 96), (180, 96), (164, 54), (92, 54)], fill=255), [(0, (110, 140, 220)), (1, (40, 60, 140))], 90)
    d = ImageDraw.Draw(im)
    # gold drawstring and embroidered cloud medallion
    d.line((70, 92, 186, 92), fill=(250, 200, 80, 255), width=9)
    d.ellipse((96, 132, 160, 196), outline=(250, 200, 80, 255), width=6)
    for sx in (114, 142):
        d.arc((sx - 12, 152, sx + 12, 176), 180, 450, fill=(250, 200, 80, 255), width=4)
    d.arc((40, 86, 216, 246), 210, 280, fill=(160, 190, 255, 255), width=5)
    # void swirling at the mouth
    a = phase * 2 * math.pi
    for k in range(3):
        ang = a + k * 2.1
        d.ellipse((128 + math.cos(ang) * 30 - 6, 66 + math.sin(ang) * 6 - 6, 128 + math.cos(ang) * 30 + 6, 66 + math.sin(ang) * 6 + 6), fill=(190, 160, 255, 255))
    d.line((180, 92, 206, 140), fill=(200, 30, 40, 255), width=6)
    return im

# ---------------------------------------------------------------- frames
FR = 6
def sword_frames(fn, glow_color, glint_path):
    base = fn()
    out = []
    for i in range(FR):
        t = i / FR
        pulse = (math.sin(t * 2 * math.pi) + 1) / 2
        sprite = to_sprite(base, glow=(glow_color, (10, 8, 24, 22), 2, int(22 + 22 * pulse)))
        (x0, y0), (x1, y1) = glint_path
        sparkle(sprite, int(x0 + (x1 - x0) * t), int(y0 + (y1 - y0) * t), 0.6 + 0.4 * pulse)
        out.append(sprite)
    return out

def pulse_frames(fn_or_img, glow_color, box, sparkle_at=None, animated_fn=None):
    out = []
    for i in range(FR):
        t = i / FR
        pulse = (math.sin(t * 2 * math.pi) + 1) / 2
        big = animated_fn(t) if animated_fn else fn_or_img
        sprite = to_sprite(big, glow=(glow_color, box, 2, int(25 + 30 * pulse)))
        if sparkle_at and i < 2:
            sparkle(sprite, *sparkle_at, 1.0 - 0.4 * i)
        out.append(sprite)
    return out

# glint paths run from hilt (bottom-left) to tip (top-right) on the rotated swords
BLADE_PATH = ((13, 19), (25, 7))
artifacts = [
    ('ganjiang', sword_frames(ganjiang, (90, 120, 230), BLADE_PATH), 2),
    ('moye', sword_frames(moye, (255, 150, 170), BLADE_PATH), 2),
    ('heaven_reliant', sword_frames(heaven_reliant, (170, 255, 220), BLADE_PATH), 2),
    ('dragon_saber', sword_frames(dragon_saber, (255, 150, 60), ((12, 20), (24, 9))), 2),
    ('ruyi_staff', pulse_frames(ruyi_staff(), (255, 200, 80), (5, 5, 27, 27), (24, 8)), 2),
    ('ruyi_needle', pulse_frames(ruyi_needle(), (255, 214, 90), (9, 9, 23, 23), (16, 16)), 2),
    ('purple_gold_gourd', pulse_frames(gourd(), (190, 120, 255), (5, 3, 27, 31), (11, 19)), 2),
    ('plantain_fan', [to_sprite(plantain_fan())], 1),
    ('bagua_mirror', pulse_frames(None, (255, 230, 150), (2, 2, 30, 30), None, bagua_mirror), 2),
    ('qiankun_pouch', pulse_frames(None, (160, 120, 255), (4, 6, 28, 31), None, qiankun_pouch), 2),
]
save_dmi(OUT + 'cultivation_artifacts.dmi', artifacts, (32, 32))

if len(sys.argv) > 1:
    prev = Image.new('RGBA', (32 * len(artifacts), 32), (60, 62, 70, 255))
    for i, (_, frames, _) in enumerate(artifacts):
        prev.alpha_composite(frames[min(1, len(frames) - 1)], (32 * i, 0))
    prev.resize((prev.width * 4, prev.height * 4), Image.NEAREST).save(sys.argv[1])
print('ok')
