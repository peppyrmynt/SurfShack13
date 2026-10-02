"""Crisp pixel-art helpers: hard alpha, 1px dark outlines, optional soft glow underneath.
Downsampled art looks blurry next to SS13 sprites; these keep edges sharp."""
from PIL import Image, ImageDraw, ImageFilter, PngImagePlugin
import math, os

def save_dmi(path, states, size):
    w, h = size
    flat = []
    desc = f"# BEGIN DMI\nversion = 4.0\n\twidth = {w}\n\theight = {h}\n"
    for name, frames, delay in states:
        desc += f'state = "{name}"\n\tdirs = 1\n\tframes = {len(frames)}\n'
        if len(frames) > 1:
            if isinstance(delay, (list, tuple)):
                desc += "\tdelay = " + ",".join(str(x) for x in delay) + "\n"
            else:
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

def harden(im, threshold=110):
    """Snap alpha to fully opaque or fully clear."""
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255 if a >= threshold else 0)
    return im

def outline(im, color=(24, 22, 30, 255)):
    """1px outline around opaque pixels (4-neighbour)."""
    src = im.load()
    out = im.copy()
    dst = out.load()
    for y in range(im.height):
        for x in range(im.width):
            if src[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < im.width and 0 <= ny < im.height and src[nx, ny][3] == 255:
                    dst[x, y] = color
                    break
    return out

def soft_glow(size, shapes, color, blur, alpha):
    """A blurred glow layer from (ellipse/polygon) shapes, kept semi-transparent on purpose."""
    layer = Image.new('RGBA', size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for kind, data in shapes:
        if kind == 'ellipse':
            d.ellipse(data, fill=color + (alpha,))
        else:
            d.polygon(data, fill=color + (alpha,))
    return layer.filter(ImageFilter.GaussianBlur(blur))

def compose(glow_layer, body):
    """Glow under a crisp body."""
    base = glow_layer.copy() if glow_layer else Image.new('RGBA', body.size, (0, 0, 0, 0))
    base.alpha_composite(body)
    return base


def cjk_font(bold=False):
    """A font with Chinese glyphs: Windows fonts locally, Noto CJK on Linux (apt install fonts-noto-cjk)."""
    candidates = [
        'C:/Windows/Fonts/msyhbd.ttc' if bold else 'C:/Windows/Fonts/simhei.ttf',
        'C:/Windows/Fonts/simhei.ttf',
        '/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc' if bold else '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
        '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
        '/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc',
        '/System/Library/Fonts/PingFang.ttc',
    ]
    for path in candidates:
        if os.path.exists(path):
            return path
    raise FileNotFoundError("No CJK font found; install fonts-noto-cjk")
