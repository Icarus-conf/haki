"""Key-h mark: one closed outline (the h, whose ascender is a key bow and right leg a key blade)
plus the bow's hole. Units: 1024 canvas. Used for both the PNG icons and the Lottie splash."""
import math

BOW_C, BOW_R, HOLE_R = (360, 248), 96, 36
STEM_L, STEM_R = 300, 420
ARCH_C, ARCH_RO, ARCH_RI = (500, 560), 200, 80
LEG_L, LEG_R, BOTTOM = 580, 700, 800
FOOT_R = 60
TEETH = [(700, 640), (754, 658), (754, 688), (700, 704), (700, 722), (744, 738), (744, 764), (700, 780)]


def _arc(c, r, a0, a1):
    return ('arc', c, r, math.radians(a0), math.radians(a1))


def outline():
    by = BOW_C[1] + math.sqrt(BOW_R**2 - (BOW_C[0] - STEM_L)**2)          # stem meets bow
    a_bow0 = math.degrees(math.atan2(by - BOW_C[1], STEM_L - BOW_C[0]))  # ~130
    a_bow1 = 360 + math.degrees(math.atan2(by - BOW_C[1], STEM_R - BOW_C[0]))
    ay = ARCH_C[1] - math.sqrt(ARCH_RO**2 - (STEM_R - ARCH_C[0])**2)     # stem meets outer arch
    a_out0 = 360 + math.degrees(math.atan2(ay - ARCH_C[1], STEM_R - ARCH_C[0]))
    segs = [
        ('move', (STEM_L, by)),
        _arc(BOW_C, BOW_R, a_bow0, a_bow1),
        ('line', (STEM_R, ay)),
        _arc(ARCH_C, ARCH_RO, a_out0, 360),
    ]
    segs += [('line', p) for p in TEETH]
    segs += [('line', (LEG_R, BOTTOM)), ('line', (LEG_L, BOTTOM)), ('line', (LEG_L, ARCH_C[1])),
             _arc(ARCH_C, ARCH_RI, 0, -180),
             ('line', (STEM_R, BOTTOM - FOOT_R)),
             _arc((STEM_L + FOOT_R, BOTTOM - FOOT_R), FOOT_R, 0, 180),
             ('line', (STEM_L, by))]
    return segs


def polygon(segs=None, step_deg=2):
    pts = []
    for s in segs or outline():
        if s[0] in ('move', 'line'):
            pts.append(s[1])
        else:
            _, c, r, a0, a1 = s
            n = max(2, int(abs(math.degrees(a1 - a0)) / step_deg))
            for i in range(1, n + 1):
                a = a0 + (a1 - a0) * i / n
                pts.append((c[0] + r * math.cos(a), c[1] + r * math.sin(a)))
    return pts


def hole_polygon(n=120):
    return [(BOW_C[0] + HOLE_R * math.cos(2 * math.pi * i / n), BOW_C[1] + HOLE_R * math.sin(2 * math.pi * i / n)) for i in range(n)]


def lottie_path(segs=None, origin=(512, 512)):
    """Closed Lottie shape {i,o,v,c} relative to origin; arcs as cubic beziers (<=90deg pieces)."""
    v, ii, oo = [], [], []
    ox, oy = origin
    def add(p):
        v.append([p[0] - ox, p[1] - oy]); ii.append([0, 0]); oo.append([0, 0])
    for s in segs or outline():
        if s[0] == 'move':
            add(s[1])
        elif s[0] == 'line':
            add(s[1])
        else:
            _, c, r, a0, a1 = s
            n = max(1, math.ceil(abs(a1 - a0) / (math.pi / 2)))
            da = (a1 - a0) / n
            k = 4 / 3 * math.tan(da / 4) * r
            for j in range(n):
                s0, s1 = a0 + da * j, a0 + da * (j + 1)
                # out tangent of current last vertex
                oo[-1] = [-math.sin(s0) * k, math.cos(s0) * k]
                add((c[0] + r * math.cos(s1), c[1] + r * math.sin(s1)))
                ii[-1] = [math.sin(s1) * k, -math.cos(s1) * k]
    # last point duplicates the first: merge
    if abs(v[-1][0] - v[0][0]) < .01 and abs(v[-1][1] - v[0][1]) < .01:
        ii[0] = ii[-1]; v.pop(); ii.pop(); oo.pop()
    return {'c': True, 'v': v, 'i': ii, 'o': oo}


def bbox():
    pts = polygon()
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    return min(xs), min(ys), max(xs), max(ys)
