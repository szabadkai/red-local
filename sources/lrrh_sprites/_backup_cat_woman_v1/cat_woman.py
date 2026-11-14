# Cat woman idle, built on red_anime's proportions (32x32, big chibi head ~ rows 2-19,
# body rows 19-31, facing right in 3/4, auto outline).  Writes cat_woman_frames.lua,
# which cat_woman.lua loads into cat_woman.aseprite.
#   uv run python cat_woman.py
import math, os
from collections import Counter

W = H = 32
TAU = math.pi * 2
N = 24                       # loop length (80 ms frames -> 1.92 s)

PAL = {
    'O': '#1c1428',          # outline (cool, near-black violet)
    # hair / ears / tail fur: black cat, lifted so it reads on dark scenes
    'k': '#2b2340', 'K': '#40365c', 'L': '#62578a', 'M': '#9c98c2',   # M = moonlight rim/shine
    # inner ear
    'p': '#e48aa4', 'P': '#a8507a',
    # skin
    's': '#ffdcc4', 'S': '#eaa892', 'b': '#e48aa4',
    # eyes: dark lash + gold iris, mouth
    'e': '#1c1428', 'Y': '#f2c14e', 'm': '#a8507a',
    # teal scarf
    't': '#2fa38c', 'T': '#1d6466', 'u': '#6fe0bc',
    # gold bell / belt buckle
    'g': '#f2c14e', 'G': '#b07a2a', 'w': '#fff6d8',
    # plum top + skirt
    'v': '#7a3e64', 'V': '#52284a', 'x': '#a85a84',
    # leggings, boots
    'd': '#271d33', 'B': '#4a2c2a', 'H': '#7a3e64',
}


def blank():
    return [['.'] * W for _ in range(H)]


def put(g, x, y, ch):
    x, y = int(round(x)), int(round(y))
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = ch


def ell(g, cx, cy, rx, ry, ch, cond=None):
    for y in range(H):
        for x in range(W):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0 and (cond is None or cond(x, y)):
                g[y][x] = ch


def rect(g, x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(g, x, y, ch)


def tri(g, a, b, c, ch):
    """Fill triangle a,b,c (pixel centres)."""
    def side(p, q, r):
        return (p[0] - r[0]) * (q[1] - r[1]) - (q[0] - r[0]) * (p[1] - r[1])
    xs = [a[0], b[0], c[0]]; ys = [a[1], b[1], c[1]]
    for y in range(int(min(ys)) - 1, int(max(ys)) + 2):
        for x in range(int(min(xs)) - 1, int(max(xs)) + 2):
            p = (x, y)
            d1, d2, d3 = side(p, a, b), side(p, b, c), side(p, c, a)
            neg = d1 < -0.01 or d2 < -0.01 or d3 < -0.01
            pos = d1 > 0.01 or d2 > 0.01 or d3 > 0.01
            if not (neg and pos):
                put(g, x, y, ch)


# ---------------------------------------------------------------- tail
def tail(g, t):
    """Long tail from the back hip, curving left and up; a slow wave travels
    base -> tip and the tip curls, lagging the body."""
    p = TAU * t / N
    x, y = 13.0, 25.5
    L, step = 15.5, 0.35
    n = int(L / step)
    pts = []
    for i in range(n + 1):
        s = i / n
        # heading in screen space (degrees, 0 = right, 90 = up)
        th = 192 - 135 * s ** 1.3                       # left -> up -> curling right at the tip
        th += 20 * s * math.sin(p - 3.0 * s)            # travelling swish
        th += 16 * s ** 3 * math.sin(2 * p - 1.0)       # tip flick
        r = 1.55 - 0.45 * s + (0.35 if s > 0.9 else 0)   # fluffy tip
        pts.append((x, y, r, s))
        a = math.radians(th)
        x += math.cos(a) * step
        y -= math.sin(a) * step
    for (cx, cy, r, s) in pts:
        for yy in range(int(cy - 2), int(cy + 3)):
            for xx in range(int(cx - 2), int(cx + 3)):
                if (xx - cx) ** 2 + (yy - cy) ** 2 <= r * r + 0.15:
                    put(g, xx, yy, 'K')
    # shade: underside / outer side of the curve darker, top lit with the rim
    tailpx = {(xx, yy) for yy in range(H) for xx in range(W) if g[yy][xx] == 'K'}
    for (xx, yy) in tailpx:
        if (xx, yy + 1) not in tailpx and (xx + 1, yy) not in tailpx:
            g[yy][xx] = 'k'
        elif (xx, yy - 1) not in tailpx and (xx - 1, yy) in tailpx | {(xx - 1, yy)}:
            g[yy][xx] = 'L'
    # tip tuft: lighter
    tx, ty = pts[-1][0], pts[-1][1]
    put(g, tx, ty, 'M')


# ---------------------------------------------------------------- ears
def ears(g, hy, t):
    # front ear twitches twice early in the loop; back ear swivels once later
    ftw = {4: 2, 5: 0, 6: 2, 7: 1}.get(t, 0)
    btw = {15: 1, 16: 2, 17: 2, 18: 1}.get(t, 0)
    # back ear (left, further away): tip leans back
    tip = (10.5 - btw * 0.8, 1.5 + hy + btw * 1.0)
    tri(g, (10, 9 + hy), (15, 6 + hy), tip, 'K')
    tri(g, (11.2, 7.6 + hy), (13.8, 6.3 + hy), (tip[0] + 0.8, tip[1] + 2.4), 'P')
    # front ear (right): tip flicks back/down on a twitch
    ftip = (21.5 - ftw * 0.9, 1.0 + hy + ftw * 1.2)
    tri(g, (17, 6 + hy), (23, 8 + hy), ftip, 'K')
    tri(g, (18.6, 6.4 + hy), (21.6, 7.4 + hy), (ftip[0] - 0.2, ftip[1] + 2.0), 'p')
    put(g, ftip[0] - 0.4, ftip[1] + 3.0, 'P')            # depth in the ear cup


# ---------------------------------------------------------------- frame
def build(t):
    g = blank()
    p = TAU * t / N
    hy = 1 if 7 <= t < 17 else 0                        # breath: head settles 1 px
    lag = 1 if 9 <= t < 19 else 0                       # scarf follows 2 frames later


    # ---- legs + boots (weight on the back leg, front leg relaxed forward)
    rect(g, 14, 28, 15, 29, 'd'); rect(g, 18, 28, 19, 29, 'd')
    rect(g, 13, 30, 15, 31, 'B'); rect(g, 18, 30, 20, 31, 'B')
    put(g, 15, 30, 'H'); put(g, 20, 30, 'H')

    # ---- skirt (flares, hem sways with the tail)
    sway = 1 if math.sin(p - 0.8) > 0.55 else 0
    for y in range(25, 28):
        u = y - 25
        x0, x1 = 13 - u + (sway if u == 2 else 0), 20 + u
        rect(g, x0, y, x1, y, 'V')
        put(g, x0, y, 'd')
    put(g, 21, 27, 'v'); put(g, 22, 27, 'v'); put(g, 19, 26, 'v')
    # ---- torso
    rect(g, 14, 20, 20, 24, 'v')
    for y in range(20, 25):
        put(g, 14, y, 'V')
    put(g, 15, 24, 'V')
    put(g, 19, 21, 'x'); put(g, 19, 22, 'x')
    # belt + buckle
    rect(g, 14, 24, 20, 24, 'B'); put(g, 18, 24, 'g')
    # ---- front arm: hand on hip, elbow out
    rect(g, 20, 20, 21, 21, 'v')
    rect(g, 21, 22, 22, 22, 'v'); put(g, 22, 23, 'V'); put(g, 23, 22, 'V')
    put(g, 21, 23, 'V')
    rect(g, 20, 24, 21, 24, 's'); put(g, 21, 23, 'S')

    # ---- scarf tails: knot behind the neck, two tails hang down-left and flutter (lag the breath)
    f = math.sin(p - 1.6)
    k1 = 1 if f > 0.35 else 0                           # gust lifts the tails back
    k2 = 1 if f < -0.35 else 0                          # slack: they drop
    # knot, then two short ribbon ends: the far one hangs, the near one lifts in the gusts
    rect(g, 12, 20, 14, 20, 't'); put(g, 12, 20, 'T')
    put(g, 12, 21 + lag, 'T'); put(g, 12, 22 + lag, 'T'); put(g, 13, 21, 'T')
    put(g, 11 - k1, 21 - k1 + k2, 't'); put(g, 10 - k1, 21 - k1 + 2 * k2, 't')
    put(g, 11 - k1, 22 - k1 + k2, 'T')

    # ---- head
    # back hair mass falls to the shoulders
    ell(g, 15.5, 13.2 + hy, 7.0, 6.6, 'K')
    rect(g, 10, 15 + hy, 14, 19, 'K')
    ell(g, 17.0, 12.0 + hy, 7.6, 6.6, 'K')
    ears(g, 1 if 8 <= t < 18 else 0, t)               # ears follow the head a frame late
    # hair shading: back-left dark, glossy shine arc across the crown
    for y in range(H):
        for x in range(W):
            if g[y][x] == 'K' and y <= 20 and x <= 24 and y >= 4:
                if x < 11 + (y - hy - 8) // 5:
                    g[y][x] = 'k'
    for x in range(14, 22):
        yy = 7 + hy + (1 if x in (14, 21) else 0)
        if g[yy][x] == 'K':
            g[yy][x] = 'L'
    for x in (16, 17, 18):
        put(g, x, 8 + hy, 'L')
    put(g, 19, 7 + hy, 'M'); put(g, 18, 7 + hy, 'M')
    for (x, y) in ((12, 11), (12, 12), (13, 13), (13, 14), (14, 15)):
        put(g, x, y + hy, 'L')

    # face
    ell(g, 20.0, 14.4 + hy, 4.3, 4.2, 's')
    # bangs (jagged cat-lick fringe), flick with the breath
    for x in range(15, 25):
        put(g, x, 10 + hy, 'K')
    fl = 1 if math.sin(p + 0.4) > 0.5 else 0
    for x in (15, 16, 18, 21, 22):
        put(g, x + (fl if x == 18 else 0), 11 + hy, 'K')
    put(g, 16, 10 + hy, 'L'); put(g, 20, 10 + hy, 'L'); put(g, 21, 10 + hy, 'L')
    put(g, 15, 12 + hy, 'K')
    # side lock in front of the far cheek edge
    for y in range(11, 18):
        put(g, 24, y + hy, 'K')
    put(g, 25, 14 + hy, 'K'); put(g, 25, 15 + hy, 'K'); put(g, 24, 18 + hy, 'K')
    put(g, 23, 11 + hy, 'K')
    # cheek / jaw shade (light from the upper right)
    put(g, 17, 18 + hy, 'S'); put(g, 16, 17 + hy, 'S')
    put(g, 16, 12 + hy, 'K'); put(g, 16, 13 + hy, 'K'); put(g, 16, 14 + hy, 'k')

    # eyes: 2 px tall, dark lash over gold iris; slow cat blink near the end
    blink = {19: 1, 20: 2, 21: 2, 22: 1}.get(t, 0)
    for ex in (18, 22):
        if blink == 0:
            put(g, ex, 14 + hy, 'e'); put(g, ex, 15 + hy, 'Y')
        elif blink == 1:                                # heavy lids: lash low, iris peeks
            put(g, ex, 15 + hy, 'e'); put(g, ex - 1, 15 + hy, 'e')
        else:                                           # closed, contented ^^
            put(g, ex - 1, 15 + hy, 'e'); put(g, ex, 15 + hy, 'e'); put(g, ex - 1, 14 + hy, 's')
    # blush + cat mouth (":3" reads as one px plus a fang when smiling)
    put(g, 17, 16 + hy, 'b'); put(g, 23, 16 + hy, 'b')
    put(g, 20, 17 + hy, 'm')

    # ---- neck scarf + bell (moves with the head)
    put(g, 19, 19, 'S')
    rect(g, 14, 19 + hy, 21, 19 + hy, 't')
    put(g, 14, 19 + hy, 'T'); put(g, 15, 19 + hy, 'T')
    put(g, 18, 19 + hy, 'u'); put(g, 19, 19 + hy, 'u')
    # bell
    by = 20 + hy
    put(g, 19, by, 'g'); put(g, 20, by, 'g'); put(g, 19, by + 1, 'G'); put(g, 20, by + 1, 'g')
    put(g, 20, by, 'w') if t in (10, 11, 12) else None

    # ---- fill enclosed gaps with the most common neighbour colour
    seen = set()
    st = [(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)]
    while st:
        x, y = st.pop()
        if (x, y) in seen or not (0 <= x < W and 0 <= y < H) or g[y][x] != '.':
            continue
        seen.add((x, y))
        st += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    for y in range(H):
        for x in range(W):
            if g[y][x] == '.' and (x, y) not in seen:
                nb = Counter(g[ny][nx] for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))
                             if 0 <= nx < W and 0 <= ny < H and g[ny][nx] != '.')
                g[y][x] = nb.most_common(1)[0][0] if nb else 'O'

    # ---- tail goes behind everything (own grid, so a curl never gets filled in)
    tg = blank()
    tail(tg, t)
    for y in range(H):
        for x in range(W):
            if g[y][x] == '.' and tg[y][x] != '.':
                g[y][x] = tg[y][x]
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            if g[y][x] == '.' and all(g[y + dy][x + dx] != '.' for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                g[y][x] = 'k'

    # ---- auto outline
    out = [row[:] for row in g]
    for y in range(H):
        for x in range(W):
            if g[y][x] == '.':
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and g[ny][nx] != '.':
                        out[y][x] = 'O'
                        break

    # ---- bell sparkle (effect, after the outline so it floats free)
    if t == 11:
        for (sx, sy) in ((22, 19), (23, 20), (22, 21), (21, 20)):
            if out[sy][sx] in '.O':
                pass
        out[19][22] = 'w'
    return [''.join(r) for r in out]


DUR = [80] * N
DUR[20] = 160; DUR[21] = 120                            # hold the slow blink

if __name__ == '__main__':
    here = os.path.dirname(os.path.abspath(__file__))
    frames = [build(t) for t in range(N)]
    with open(os.path.join(here, 'cat_woman_frames.lua'), 'w') as f:
        f.write('return {\n  key = {\n')
        for k, v in PAL.items():
            f.write(f'    ["{k}"] = "{v}",\n')
        f.write('  },\n  dur = {' + ', '.join(map(str, DUR)) + '},\n  frames = {\n')
        for fr in frames:
            f.write('    {\n' + ''.join(f'      "{r}",\n' for r in fr) + '    },\n')
        f.write('  },\n}\n')
    for r in frames[0]:
        print(r)
