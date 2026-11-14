import json, os
from PIL import Image, ImageDraw, ImageFilter
from final_icon import icon, grad_bg, mark

APP = '/Users/muhammadfathy/Documents/Haki/haki_mobile'
master = icon(1024).convert('RGB')

# iOS: full-bleed squares, no alpha (iOS rounds the corners itself)
d = f'{APP}/ios/Runner/Assets.xcassets/AppIcon.appiconset'
for im in json.load(open(f'{d}/Contents.json'))['images']:
    px = round(float(im['size'].split('x')[0]) * int(im['scale'][0]))
    master.resize((px, px), Image.LANCZOS).save(f"{d}/{im['filename']}")

# macOS: Big Sur-style rounded square inside the canvas with a soft drop shadow
def mac(size):
    c = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    inner = round(size * 824 / 1024); off = (size - inner) // 2
    body = icon(inner * 2).resize((inner, inner), Image.LANCZOS)
    m = Image.new('L', (inner * 4, inner * 4), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, inner * 4, inner * 4), radius=int(inner * 4 * .2237), fill=255)
    m = m.resize((inner, inner), Image.LANCZOS)
    sh = Image.new('L', (size, size), 0); sh.paste(m, (off, off + max(1, size // 100)))
    shadow = Image.new('RGBA', (size, size), (0, 0, 0, 110)); shadow.putalpha(sh.filter(ImageFilter.GaussianBlur(max(1, size * .012))).point(lambda v: v * 110 // 255))
    c = Image.alpha_composite(c, shadow)
    body.putalpha(m); c.alpha_composite(body, (off, off)); return c
for s in (16, 32, 64, 128, 256, 512, 1024):
    mac(s).save(f'{APP}/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{s}.png')

# Android: legacy + adaptive (foreground mark sits in the 66% safe zone)
res = f'{APP}/android/app/src/main/res'
for dpi, legacy, adaptive in (('mdpi', 48, 108), ('hdpi', 72, 162), ('xhdpi', 96, 216), ('xxhdpi', 144, 324), ('xxxhdpi', 192, 432)):
    leg = icon(legacy * 4).resize((legacy, legacy), Image.LANCZOS)
    m = Image.new('L', (legacy * 4, legacy * 4), 0)
    ImageDraw.Draw(m).ellipse((0, 0, legacy * 4, legacy * 4), fill=255)
    leg.putalpha(m.resize((legacy, legacy), Image.LANCZOS))
    leg.save(f'{res}/mipmap-{dpi}/ic_launcher.png')
    grad_bg(adaptive).convert('RGB').save(f'{res}/mipmap-{dpi}/ic_launcher_background.png')
    mark(adaptive, scale=.66).save(f'{res}/mipmap-{dpi}/ic_launcher_foreground.png')
    mark(adaptive, scale=.66, color=(255, 255, 255), shadow=False).save(f'{res}/mipmap-{dpi}/ic_launcher_monochrome.png')

# Web + favicon
for s, name in ((192, 'Icon-192.png'), (512, 'Icon-512.png')):
    r = icon(s * 2).resize((s, s), Image.LANCZOS)
    m = Image.new('L', (s * 4, s * 4), 0); ImageDraw.Draw(m).rounded_rectangle((0, 0, s * 4, s * 4), radius=int(s * 4 * .2237), fill=255)
    r.putalpha(m.resize((s, s), Image.LANCZOS)); r.save(f'{APP}/web/icons/{name}')
    icon(s * 2, scale=.72).resize((s, s), Image.LANCZOS).convert('RGB').save(f'{APP}/web/icons/Icon-maskable-{s}.png')
fav = icon(256).resize((64, 64), Image.LANCZOS); fav.save(f'{APP}/web/favicon.png')

# Windows .ico
win = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
body = icon(512).resize((240, 240), Image.LANCZOS)
mw = Image.new('L', (960, 960), 0); ImageDraw.Draw(mw).rounded_rectangle((0, 0, 960, 960), radius=200, fill=255)
body.putalpha(mw.resize((240, 240), Image.LANCZOS)); win.alpha_composite(body, (8, 8))
win.save(f'{APP}/windows/runner/resources/app_icon.ico', sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
print('done')
