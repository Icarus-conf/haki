import math, sys
from PIL import Image, ImageDraw, ImageFilter
import keyh

INK = (8, 8, 12); LIME = (221, 251, 92)
N, SS = 1024, 4
S = N * SS


def grad_bg(size):
    # deep violet top-left -> indigo -> blue, with a teal glow bottom-right
    small = Image.new('RGB', (256, 256)); px = small.load()
    c1, c2, c3 = (74, 40, 200), (34, 26, 120), (14, 56, 140)
    for y in range(256):
        for x in range(256):
            t = (x * .45 + y * .55) / 255
            a, b, u = (c1, c2, t / .5) if t < .5 else (c2, c3, (t - .5) / .5)
            px[x, y] = tuple(int(a[i] + (b[i] - a[i]) * u) for i in range(3))
    bg = small.resize((size, size), Image.BICUBIC).convert('RGBA')
    g = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    k = size / 1024
    ImageDraw.Draw(g).ellipse((640 * k, 620 * k, 1180 * k, 1160 * k), fill=(24, 179, 155, 150))
    bg = Image.alpha_composite(bg, g.filter(ImageFilter.GaussianBlur(150 * k)))
    g = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(g).ellipse((-200 * k, -260 * k, 420 * k, 360 * k), fill=(160, 120, 255, 110))
    return Image.alpha_composite(bg, g.filter(ImageFilter.GaussianBlur(160 * k)))


def mark(size, scale=.86, color=LIME, shadow=True):
    S = size * SS
    x0, y0, x1, y1 = keyh.bbox()
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    k = S / 1024 * scale
    T = lambda p: (S / 2 + (p[0] - cx) * k, S / 2 + (p[1] - cy) * k)
    m = Image.new('L', (S, S), 0); d = ImageDraw.Draw(m)
    d.polygon([T(p) for p in keyh.polygon()], fill=255)
    d.polygon([T(p) for p in keyh.hole_polygon()], fill=0)
    m = m.resize((size, size), Image.LANCZOS)
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    if shadow:
        sh = Image.new('RGBA', (size, size), (10, 6, 40, 150))
        sm = m.filter(ImageFilter.GaussianBlur(size * .018))
        out.paste(sh, (int(size * .004), int(size * .016)), sm)
    out.paste(Image.new('RGBA', (size, size), color + (255,)), (0, 0), m)
    return out


def icon(size=1024, scale=.86):
    return Image.alpha_composite(grad_bg(size), mark(size, scale))


if __name__ == '__main__':
    icon().convert('RGB').save(sys.argv[1] if len(sys.argv) > 1 else 'keyh.png')
