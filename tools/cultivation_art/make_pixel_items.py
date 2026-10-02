"""Crisp native 32px item and artifact sprites, with separate soft glows and animated glints on legendary artifacts."""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from pixel import save_dmi, harden, outline, soft_glow, compose
from PIL import Image, ImageDraw, ImageFont

OUT = 'surfshack13/icons/cultivation/'
from pixel import cjk_font
FONT = cjk_font()
OUTLINE = (26, 22, 30, 255)

def c(rgb, a=255):
    return tuple(rgb) + (a,)

def canvas():
    im = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)

def finish(im, line=OUTLINE, glow=None):
    """Harden + outline, then put an optional soft glow underneath. glow = (color, box, blur, alpha)."""
    body = outline(harden(im), line)
    if not glow:
        return body
    color, box, blur, alpha = glow
    return compose(soft_glow((32, 32), [('ellipse', box)], color, blur, alpha), body)

def glint(im, x, y, size=2):
    """A little four-point sparkle."""
    d = ImageDraw.Draw(im)
    d.point((x, y), fill=(255, 255, 255, 255))
    for k in range(1, size + 1):
        a = 255 - k * 70
        for dx, dy in ((k, 0), (-k, 0), (0, k), (0, -k)):
            if 0 <= x + dx < 32 and 0 <= y + dy < 32:
                d.point((x + dx, y + dy), fill=(255, 255, 240, a))
    return im

# =====================================================================
#                               ITEMS
# =====================================================================

def mat():
    im, d = canvas()
    red, red_dark, red_light, gold = (176, 46, 38), (112, 24, 20), (208, 80, 60), (232, 184, 70)
    d.ellipse((2, 13, 29, 29), fill=c(red_dark))
    d.ellipse((3, 13, 28, 27), fill=c(red))
    for k in range(12):
        a = k * math.pi / 6
        d.point((15.5 + math.cos(a) * 10, 20 + math.sin(a) * 5.5), fill=c(red_light))
    d.ellipse((8, 16, 23, 24), outline=c(gold))
    d.ellipse((13, 18, 18, 22), fill=c(gold))
    d.point((14, 19), fill=c((255, 236, 150)))
    return finish(im)

def manual():
    im, d = canvas()
    cover, cover_dark, paper, gold = (44, 96, 66), (26, 60, 40), (236, 224, 190), (214, 174, 80)
    d.rectangle((8, 4, 24, 28), fill=c(cover))
    d.line((9, 4, 9, 28), fill=c(cover_dark))
    for y in (7, 12, 17, 22, 26):
        d.point((8, y), fill=c(gold)); d.point((9, y), fill=c(gold))
    d.rectangle((13, 6, 21, 22), fill=c(paper))
    d.line((14, 8, 20, 8), fill=c((160, 30, 30))); d.line((16, 10, 16, 14), fill=c((160, 30, 30)))
    d.line((14, 12, 18, 12), fill=c((160, 30, 30))); d.line((14, 16, 20, 16), fill=c((160, 30, 30)))
    d.line((15, 18, 19, 20), fill=c((160, 30, 30)))
    d.line((24, 5, 24, 27), fill=c((70, 130, 90)))
    return finish(im)

def ring():
    im, d = canvas()
    gold, gold_dark, gold_light, stone = (226, 180, 60), (150, 104, 26), (255, 226, 140), (30, 28, 44)
    d.ellipse((9, 13, 23, 27), outline=c(gold), width=2)
    d.arc((10, 14, 22, 26), 200, 300, fill=c(gold_light))
    d.arc((9, 13, 23, 27), 20, 160, fill=c(gold_dark))
    d.rectangle((13, 8, 19, 14), fill=c(gold_dark))
    d.ellipse((12, 6, 20, 13), fill=c(stone))
    d.point((14, 8), fill=c((150, 140, 220))); d.point((15, 8), fill=c((110, 100, 180)))
    return finish(im, glow=((130, 100, 220), (8, 2, 24, 18), 2, 80))

def dantian():
    im, d = canvas()
    flesh, dark, light = (206, 96, 110), (140, 50, 66), (246, 170, 180)
    d.ellipse((8, 10, 24, 25), fill=c(flesh))
    d.arc((10, 12, 22, 23), 200, 400, fill=c(dark))
    d.ellipse((11, 13, 15, 16), fill=c(light))
    d.point((19, 20), fill=c(dark)); d.point((13, 21), fill=c(dark))
    return finish(im, glow=((255, 140, 150), (6, 8, 26, 27), 2, 90))

def golden_core(phase):
    im, d = canvas()
    gold, dark, light, pale = (240, 188, 50), (176, 118, 20), (255, 226, 120), (255, 250, 220)
    d.ellipse((9, 9, 23, 23), fill=c(gold))
    d.arc((9, 9, 23, 23), 20, 160, fill=c(dark))
    d.arc((10, 10, 22, 22), 200, 280, fill=c(light))
    d.ellipse((12, 12, 15, 15), fill=c(pale))
    # orbiting qi spark
    a = phase * 2 * math.pi
    sx, sy = 16 + math.cos(a) * 10, 16 + math.sin(a) * 4
    body = finish(im, line=(110, 66, 16, 255), glow=((255, 214, 90), (3, 3, 29, 29), 3, int(110 + 80 * (math.sin(a) + 1) / 2)))
    return glint(body, int(sx), int(sy), 1)

def needles():
    im, d = canvas()
    steel, steel_light = (190, 200, 216), (250, 252, 255)
    for k, x in enumerate((10, 15, 20)):
        d.line((x, 5 + k, x + 3, 24 + k), fill=c(steel))
        d.point((x, 5 + k), fill=c(steel_light))
    d.rectangle((8, 20, 25, 23), fill=c((170, 34, 44)))
    d.line((8, 21, 25, 21), fill=c((214, 70, 70)))
    return finish(im)

def flying_dagger():
    im, d = canvas()
    blade, edge, shade = (200, 212, 228), (255, 255, 255), (140, 152, 176)
    d.polygon([(25, 5), (27, 7), (14, 20), (12, 18)], fill=c(blade))
    d.line((25, 6, 13, 18), fill=c(edge))
    d.line((26, 7, 14, 19), fill=c(shade))
    d.line((10, 17, 15, 22), fill=c((210, 170, 70)))
    d.line((12, 20, 7, 25), fill=c((110, 60, 30)), width=2)
    d.line((6, 26, 3, 29), fill=c((200, 40, 40)))
    d.line((7, 26, 5, 30), fill=c((220, 60, 60)))
    return finish(im)

def smoke_pellet():
    im, d = canvas()
    shell, light, dark = (70, 70, 78), (150, 150, 162), (40, 40, 46)
    for x, y in ((11, 19), (19, 17), (15, 23)):
        d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=c(shell))
        d.point((x - 2, y - 2), fill=c(light)); d.point((x + 2, y + 2), fill=c(dark))
    d.line((19, 12, 21, 8), fill=c((190, 190, 200)))
    d.point((22, 7), fill=c((220, 220, 230)))
    return finish(im)

def sect_plaque():
    im, d = canvas()
    wood, wood_dark, gold, board = (110, 50, 26), (70, 30, 14), (226, 178, 70), (34, 22, 16)
    d.rectangle((2, 7, 29, 25), fill=c(wood))
    d.rectangle((4, 9, 27, 23), fill=c(board))
    d.rectangle((4, 9, 27, 23), outline=c(gold))
    font = ImageFont.truetype(cjk_font(), 11)
    d.text((5, 10), '宗门', font=font, fill=c(gold))
    d.line((7, 3, 14, 7), fill=c((170, 30, 30))); d.line((24, 3, 17, 7), fill=c((170, 30, 30)))
    d.line((2, 25, 29, 25), fill=c(wood_dark))
    return finish(im)

def jade_seal():
    im, d = canvas()
    jade, jade_dark, jade_light = (76, 176, 126), (36, 104, 72), (150, 224, 184)
    d.rectangle((8, 17, 23, 27), fill=c(jade))
    d.polygon([(8, 17), (12, 13), (27, 13), (23, 17)], fill=c(jade_light))
    d.polygon([(23, 17), (27, 13), (27, 23), (23, 27)], fill=c(jade_dark))
    # coiled dragon knob
    d.ellipse((12, 5, 21, 14), fill=c(jade))
    d.arc((13, 6, 20, 13), 0, 270, fill=c(jade_dark))
    d.point((15, 8), fill=c((20, 40, 30))); d.point((18, 8), fill=c((20, 40, 30)))
    d.rectangle((10, 20, 13, 23), fill=c((196, 30, 40)))
    return finish(im, glow=((255, 220, 110), (4, 3, 30, 31), 3, 110))

def pill(color, light, dark):
    im, d = canvas()
    d.ellipse((10, 12, 21, 23), fill=c(color))
    d.arc((10, 12, 21, 23), 20, 160, fill=c(dark))
    d.ellipse((12, 14, 15, 17), fill=c(light))
    body = finish(im, glow=(color, (6, 8, 25, 27), 2, 110))
    return glint(body, 19, 13, 1)

# =====================================================================
#                             ARTIFACTS
# =====================================================================

def diagonal_sword(blade, edge, shade, guard, grip, tassel, glow_color, phase, length=21):
    """A jian from bottom-left (hilt) to top-right (tip)."""
    im, d = canvas()
    tip = (27, 4)
    base = (tip[0] - length, tip[1] + length)
    # blade: 3 diagonal lines
    d.line((base[0] + 1, base[1] - 1, tip[0], tip[1]), fill=c(blade), width=3)
    d.line((base[0] + 1, base[1] - 2, tip[0] - 1, tip[1]), fill=c(edge))
    d.line((base[0] + 2, base[1] - 1, tip[0], tip[1] + 1), fill=c(shade))
    d.point(tip, fill=c(edge))
    # guard (perpendicular)
    gx, gy = base
    d.line((gx - 2, gy - 2, gx + 2, gy + 2), fill=c(guard), width=2)
    # grip
    d.line((gx - 1, gy + 1, gx - 4, gy + 4), fill=c(grip), width=2)
    d.point((gx - 5, gy + 5), fill=c(guard)); d.point((gx - 6, gy + 5), fill=c(guard)); d.point((gx - 5, gy + 6), fill=c(guard))
    if tassel:
        sway = round(math.sin(phase * 2 * math.pi))
        d.line((gx - 6, gy + 6, gx - 7 + sway, gy + 10), fill=c(tassel))
        d.line((gx - 5, gy + 7, gx - 5 + sway, gy + 10), fill=c(tassel))
    body = finish(im, glow=(glow_color, (6, 4, 28, 26), 2, int(40 + 35 * (math.sin(phase * 2 * math.pi) + 1) / 2)))
    # a glint sliding up the blade
    t = phase
    gxp = int(base[0] + 2 + (tip[0] - base[0] - 3) * t)
    gyp = int(base[1] - 2 - (base[1] - tip[1] - 3) * t)
    return glint(body, gxp, gyp, 1)

FRAMES = 6
def frames(fn):
    return [fn(i / FRAMES) for i in range(FRAMES)]

def ganjiang(p):
    return diagonal_sword((70, 80, 120), (160, 180, 230), (40, 46, 74), (210, 170, 70), (50, 34, 30), (50, 100, 210), (90, 120, 220), p)

def moye(p):
    return diagonal_sword((214, 222, 236), (255, 255, 255), (150, 160, 184), (214, 174, 80), (130, 24, 34), (220, 44, 54), (255, 150, 160), p)

def heaven_reliant(p):
    return diagonal_sword((222, 242, 232), (255, 255, 255), (150, 196, 176), (90, 180, 140), (30, 64, 52), (250, 250, 250), (170, 255, 220), p, length=23)

def dragon_saber(p):
    im, d = canvas()
    black, edge, gold = (40, 38, 46), (220, 222, 232), (236, 186, 60)
    # broad curved dao, hilt bottom-left
    d.polygon([(7, 23), (24, 4), (28, 5), (27, 10), (11, 26)], fill=c(black))
    d.line((24, 5, 27, 9), fill=c(edge))
    d.line((26, 10, 11, 25), fill=c(edge))
    # golden dragon along the spine
    pts = [(9 + k * 1.8, 22 - k * 1.8 + (1 if k % 2 else -1)) for k in range(9)]
    d.line(pts, fill=c(gold))
    d.point((25, 6), fill=c((255, 230, 120)))
    d.line((5, 21, 10, 26), fill=c(gold), width=2)
    d.line((6, 26, 3, 29), fill=c((130, 24, 24)), width=2)
    body = finish(im, glow=((255, 140, 50), (6, 4, 28, 26), 2, int(35 + 30 * (math.sin(p * 2 * math.pi) + 1) / 2)))
    return glint(body, int(12 + 12 * p), int(22 - 13 * p), 1)

def ruyi_staff(p):
    im, d = canvas()
    red, red_dark, gold, gold_dark = (186, 34, 28), (120, 20, 16), (240, 194, 64), (160, 110, 24)
    d.line((5, 27, 27, 5), fill=c(red), width=3)
    d.line((5, 26, 26, 5), fill=c((220, 70, 60)))
    for (x1, y1, x2, y2) in ((3, 29, 8, 24), (24, 8, 29, 3)):
        d.line((x1, y1, x2, y2), fill=c(gold), width=4)
        d.line((x1 + 1, y1 - 1, x2, y2 - 1), fill=c((255, 230, 140)))
    body = finish(im, glow=((255, 200, 80), (6, 6, 26, 26), 2, int(35 + 30 * (math.sin(p * 2 * math.pi) + 1) / 2)))
    return glint(body, int(8 + 16 * p), int(24 - 16 * p), 1)

def ruyi_needle(p):
    im, d = canvas()
    d.line((12, 20, 20, 12), fill=c((240, 194, 64)))
    d.point((12, 20), fill=c((160, 110, 24))); d.point((20, 12), fill=c((160, 110, 24)))
    body = finish(im, glow=((255, 214, 90), (8, 8, 24, 24), 2, int(120 + 80 * (math.sin(p * 2 * math.pi) + 1) / 2)))
    return glint(body, 16, 16, 2 if p < 0.5 else 1)

def gourd(p):
    im, d = canvas()
    purple, dark, light, gold = (128, 56, 168), (70, 26, 96), (186, 130, 224), (236, 186, 60)
    d.ellipse((7, 13, 25, 30), fill=c(purple))
    d.ellipse((11, 5, 21, 15), fill=c(purple))
    d.arc((9, 15, 23, 28), 200, 300, fill=c(light))
    d.arc((12, 6, 20, 14), 200, 290, fill=c(light))
    d.arc((7, 13, 25, 30), 20, 150, fill=c(dark))
    d.rectangle((12, 13, 20, 15), fill=c(gold))
    d.rectangle((14, 2, 18, 5), fill=c((130, 84, 40)))
    sway = round(math.sin(p * 2 * math.pi))
    d.line((20, 14, 24 + sway, 19), fill=c((210, 36, 46)))
    d.line((20, 15, 22 + sway, 21), fill=c((230, 60, 70)))
    body = finish(im, glow=((190, 120, 255), (3, 1, 29, 31), 3, int(60 + 50 * (math.sin(p * 2 * math.pi) + 1) / 2)))
    return glint(body, 11, 18, 1) if p < 0.34 else body

def plantain_fan(p):
    im, d = canvas()
    leaf, dark, light = (74, 156, 62), (36, 90, 34), (130, 200, 100)
    d.ellipse((4, 2, 28, 24), fill=c(leaf))
    for a in range(-60, 61, 20):
        r = math.radians(a - 90)
        d.line((16, 23, 16 + math.cos(r) * 12, 13 + math.sin(r) * 10), fill=c(dark))
    d.arc((5, 3, 27, 23), 200, 290, fill=c(light))
    d.rectangle((15, 22, 17, 30), fill=c((156, 104, 52)))
    d.ellipse((13, 20, 19, 25), fill=c((224, 184, 74)))
    return finish(im)

def bagua_mirror(p):
    im, d = canvas()
    bronze, dark, mirror, gold = (176, 116, 44), (106, 64, 18), (210, 228, 240), (240, 200, 90)
    pts = [(16 + math.cos(math.radians(22.5 + i * 45)) * 13, 16 + math.sin(math.radians(22.5 + i * 45)) * 13) for i in range(8)]
    d.polygon(pts, fill=c(bronze))
    trigrams = ['111', '011', '101', '001', '110', '010', '100', '000']
    for i, tri in enumerate(trigrams):
        a = math.radians(i * 45 - 90)
        for j, bit in enumerate(tri[:2]):
            rr = 11 - j * 2
            x, y = 16 + math.cos(a) * rr, 16 + math.sin(a) * rr
            px, py = -math.sin(a) * 2, math.cos(a) * 2
            if bit == '1':
                d.line((x - px, y - py, x + px, y + py), fill=c(dark))
            else:
                d.point((x - px, y - py), fill=c(dark)); d.point((x + px, y + py), fill=c(dark))
    d.ellipse((10, 10, 22, 22), fill=c(mirror))
    d.ellipse((10, 10, 22, 22), outline=c(gold))
    # moving reflection
    sx = 12 + int(7 * p)
    d.line((sx, 13, sx + 3, 13), fill=c((255, 255, 255)))
    d.point((sx + 1, 14), fill=c((255, 255, 255)))
    return finish(im, glow=((255, 230, 150), (1, 1, 31, 31), 3, 90))

def qiankun_pouch(p):
    im, d = canvas()
    blue, dark, light, gold = (44, 66, 140), (24, 36, 84), (80, 110, 190), (236, 188, 64)
    d.ellipse((6, 11, 26, 29), fill=c(blue))
    d.polygon([(10, 12), (22, 12), (20, 7), (12, 7)], fill=c(light))
    d.line((9, 11, 23, 11), fill=c(gold))
    d.ellipse((12, 16, 20, 24), outline=c(gold))
    d.point((16, 20), fill=c(gold))
    d.arc((6, 11, 26, 29), 20, 150, fill=c(dark))
    d.line((22, 11, 25, 16), fill=c((200, 30, 40)))
    # swirling void peeking out of the mouth
    a = p * 2 * math.pi
    d.point((14 + round(math.cos(a) * 2), 9), fill=c((190, 160, 255)))
    d.point((18 - round(math.cos(a) * 2), 9), fill=c((150, 120, 240)))
    return finish(im, glow=((160, 120, 255), (2, 4, 30, 31), 3, 70))

items = [
    ('mat', [mat()], 1), ('manual', [manual()], 1), ('ring', [ring()], 1), ('dantian', [dantian()], 1),
    ('golden_core', [golden_core(i / 8) for i in range(8)], 1),
    ('needles', [needles()], 1), ('flying_dagger', [flying_dagger()], 1), ('smoke_pellet', [smoke_pellet()], 1),
    ('sect_plaque', [sect_plaque()], 1), ('jade_seal', [jade_seal()], 1),
    ('pill_qi', [pill((110, 190, 255), (220, 244, 255), (50, 110, 190))], 1),
    ('pill_foundation', [pill((250, 200, 70), (255, 246, 200), (170, 120, 20))], 1),
    ('pill_tribulation', [pill((176, 120, 250), (236, 220, 255), (100, 60, 170))], 1),
    ('pill_tempering', [pill((230, 80, 56), (255, 200, 170), (150, 36, 24))], 1),
]
artifacts = [
    ('ganjiang', frames(ganjiang), 2), ('moye', frames(moye), 2), ('heaven_reliant', frames(heaven_reliant), 2),
    ('dragon_saber', frames(dragon_saber), 2), ('ruyi_staff', frames(ruyi_staff), 2), ('ruyi_needle', frames(ruyi_needle), 2),
    ('purple_gold_gourd', frames(gourd), 2), ('plantain_fan', [plantain_fan(0)], 1), ('bagua_mirror', frames(bagua_mirror), 2),
    ('qiankun_pouch', frames(qiankun_pouch), 2),
]
save_dmi(OUT + 'cultivation_items.dmi', items, (32, 32))
save_dmi(OUT + 'cultivation_artifacts.dmi', artifacts, (32, 32))

if len(sys.argv) > 1:
    allf = [s[1][0] for s in items] + [s[1][min(1, len(s[1]) - 1)] for s in artifacts]
    prev = Image.new('RGBA', (32 * len(allf), 32), (60, 62, 70, 255))
    for i, f in enumerate(allf):
        prev.alpha_composite(f, (32 * i, 0))
    prev.resize((prev.width * 3, prev.height * 3), Image.NEAREST).save(sys.argv[1])
print('ok')
