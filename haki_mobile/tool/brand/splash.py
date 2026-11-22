"""Haki splash: the key-h traces itself, fills in, turns like a key (click), one ring pulse, hold."""
import json, os, sys
import keyh

W = H = 512
FR, OP = 60, 132
x0, y0, x1, y1 = keyh.bbox()
CX, CY = (x0 + x1) / 2, (y0 + y1) / 2
SCALE = 54  # percent: mark ~350px tall in a 512 box
LIME = [0.867, 0.984, 0.361, 1]

def ease(x1, y1, x2, y2):
    return {'o': {'x': [x1], 'y': [y1]}, 'i': {'x': [x2], 'y': [y2]}}

ENTER = ease(.20, .75, .34, .94)
SETTLE = ease(.00, .65, .51, .99)
TRAVEL = ease(.65, 0, .35, 1)

def kf(frames, values, eases):
    """frames/values lists; eases[i] applies between key i and i+1."""
    out = []
    for i, (t, v) in enumerate(zip(frames, values)):
        k = {'t': t, 's': v if isinstance(v, list) else [v]}
        if i < len(frames) - 1:
            k.update(eases[i] if isinstance(eases, list) else eases)
        out.append(k)
    return {'a': 1, 'k': out}

def static(v):
    return {'a': 0, 'k': v}

outline = keyh.lottie_path(origin=(CX, CY))
hole = {'c': True, 'v': [], 'i': [], 'o': []}
import math
hc = (keyh.BOW_C[0] - CX, keyh.BOW_C[1] - CY); r = keyh.HOLE_R; k = r * 0.5523
# counter-clockwise so even-odd and nonzero both cut it out
for (dx, dy), (ix, iy), (ox, oy) in [((0, -r), (k, 0), (-k, 0)), ((-r, 0), (0, -k), (0, k)), ((0, r), (-k, 0), (k, 0)), ((r, 0), (0, k), (0, -k))]:
    hole['v'].append([hc[0] + dx, hc[1] + dy]); hole['i'].append([ix, iy]); hole['o'].append([ox, oy])

def sh(name, path):
    return {'ty': 'sh', 'nm': name, 'ks': static(path)}

def tr(o=None):
    return {'ty': 'tr', 'p': static([0, 0]), 'a': static([0, 0]), 's': static([100, 100]), 'r': static(0),
            'o': o or static(100), 'sk': static(0), 'sa': static(0)}

# --- trace: a lime line draws the outline, then hands over to the fill
trace = {'ty': 'gr', 'nm': 'Trace', 'it': [
    sh('Outline', outline), sh('Hole', hole),
    {'ty': 'tm', 'nm': 'Draw', 's': static(0), 'e': kf([2, 46], [0, 100], ENTER), 'o': static(0), 'm': 1},
    {'ty': 'st', 'nm': 'Line', 'c': {'sid': 'markColor'}, 'o': static(100), 'w': static(22), 'lc': 2, 'lj': 2},
    tr(kf([38, 58], [100, 0], SETTLE)),
]}
fill = {'ty': 'gr', 'nm': 'Fill', 'it': [
    sh('Outline', outline), sh('Hole', hole),
    {'ty': 'fl', 'nm': 'Lime', 'c': {'sid': 'markColor'}, 'o': static(100), 'r': 2},
    tr(kf([34, 56], [0, 100], SETTLE)),
]}

mark_layer = {
    'ddd': 0, 'ind': 1, 'ty': 4, 'nm': 'Key h', 'sr': 1, 'ip': 0, 'op': OP, 'st': 0, 'bm': 0,
    'ks': {
        'o': static(100),
        # anchor at the bow hole: the mark turns around it like a key in a lock
        'a': static([hc[0], hc[1], 0]),
        'p': static([W / 2 + hc[0] * SCALE / 100, H / 2 + hc[1] * SCALE / 100, 0]),
        # the turn: a quarter-twist back, a small overshoot, then the click into place
        'r': kf([52, 74, 84], [-14, 3, 0], [TRAVEL, SETTLE]),
        's': kf([0, 30, 74, 84], [[SCALE * .9] * 2 + [100], [SCALE] * 2 + [100], [SCALE * 1.035] * 2 + [100], [SCALE] * 2 + [100]], [SETTLE, TRAVEL, SETTLE]),
    },
    'shapes': [trace, fill],
}

# --- one ring pulse out of the bow hole when the key clicks
ring = {
    'ddd': 0, 'ind': 2, 'ty': 4, 'nm': 'Click ring', 'sr': 1, 'ip': 72, 'op': OP, 'st': 0, 'bm': 0,
    'ks': {'o': kf([72, 112], [70, 0], SETTLE), 'a': static([0, 0, 0]),
           'p': static([W / 2 + hc[0] * SCALE / 100, H / 2 + hc[1] * SCALE / 100, 0]), 'r': static(0), 's': static([100, 100, 100])},
    'shapes': [{'ty': 'gr', 'nm': 'Ring', 'it': [
        {'ty': 'el', 'nm': 'Circle', 'p': static([0, 0]), 's': kf([72, 112], [[40, 40], [430, 430]], ENTER)},
        {'ty': 'st', 'nm': 'Stroke', 'c': {'sid': 'markColor'}, 'o': static(100), 'w': kf([72, 112], [10, 2], SETTLE), 'lc': 2, 'lj': 2},
        tr()]}],
}

doc = {
    'v': '5.12.1', 'fr': FR, 'ip': 0, 'op': OP, 'w': W, 'h': H, 'nm': 'Haki splash', 'ddd': 0,
    'assets': [], 'slots': {'markColor': {'p': {'a': 0, 'k': LIME}}},
    'layers': [ring, mark_layer],
}
# Flutter's lottie package doesn't read slots: also inline the colour as a fallback copy
inline = json.loads(json.dumps(doc).replace('{"sid": "markColor"}', json.dumps({'a': 0, 'k': LIME})))
inline.pop('slots')
out_dir = sys.argv[1]
os.makedirs(out_dir, exist_ok=True)
json.dump(doc, open(f'{out_dir}/lottie.json', 'w'))
json.dump({'controls': [{'sid': 'markColor', 'label': 'Mark colour'}]}, open(f'{out_dir}/controls.json', 'w'), indent=2)
if len(sys.argv) > 2:
    json.dump(inline, open(sys.argv[2], 'w'))
print('ok', CX, CY)
