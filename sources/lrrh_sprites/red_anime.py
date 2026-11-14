import json, math, sys
W = H = 32
PAL = {
  'O': '#2a1418', 'R': '#c8303c', 'r': '#8e2232', 'L': '#ea5a62', 'q': '#6a1a28',
  'h': '#3a2226', 'H': '#6a4038', 's': '#ffdcc4', 'S': '#eaa892', 'b': '#f48c8c',
  'e': '#22141e', 'i': '#8a3a28', 'I': '#e0903a', 'w': '#ffffff', 'm': '#8a2c3a',
  'd': '#f2e8e4', 'D': '#c4b2bc', 'k': '#3a2c4a', 'K': '#271d33', 'g': '#2a1c22',
  'B': '#4a2c2a', 'n': '#c89058', 'N': '#8a5a34', 'c': '#d84a4a',
  'C': '#c8303c', 'F': '#8e2232', 'G': '#ea5a62',
}
def blank(): return [['.'] * W for _ in range(H)]

def ell(g, cx, cy, rx, ry, ch, cond=None):
    for y in range(H):
        for x in range(W):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0 and (cond is None or cond(x, y)):
                g[y][x] = ch
def rect(g, x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < W and 0 <= y < H: g[y][x] = ch
def px(g, pts, ch):
    for x, y in pts:
        if 0 <= x < W and 0 <= y < H: g[y][x] = ch

TAU = math.pi * 2
def build(t=0, blink=False, bob=0, mouth='m'):
    g = blank()
    gust = 0.55 + 0.45 * math.sin(TAU * t / 24)      # slow gust envelope (24-frame loop)
    p = TAU * t / 8                                   # cloth wave, 3 waves per loop
    # ---- cape (behind body): streams back to the left, a wave travels down it
    x0s, x1s = {}, {}
    for y in range(17, 31):
        u = (y - 17) / 12
        x0 = 13 - 5 * u - gust * (1.2 + 4.2 * u) * u - 1.4 * u * math.sin(p - u * 4.5)
        x1 = 18 + 2 * u
        x0s[y], x1s[y] = x0, x1
        for x in range(round(x0), round(x1) + 1):
            hem = 29 + 0.8 * math.sin(p * 1.0 - x * 0.8) - gust * 2.4 * max(0.0, (13.5 - x) / 7)
            if y > hem: continue
            v = (x - x0) / max(1.0, x1 - x0)
            f1 = 0.30 + 0.10 * math.sin(p - u * 3.2)
            f2 = 0.64 + 0.09 * math.sin(p + 1.7 - u * 3.2)
            ch = 'C'
            if v < 0.13: ch = 'F'
            elif u > 0.12 and (abs(v - f1) < 0.065 or abs(v - f2) < 0.06): ch = 'F'
            elif u > 0.12 and (0.065 <= v - f1 < 0.15 or 0.06 <= v - f2 < 0.13): ch = 'G'
            if y > hem - 1: ch = 'q'                     # lining shows along the hem
            if 0 <= x < W: g[y][x] = ch
    # ---- skirt + legs + boots
    for y in range(24, 28):
        u = (y - 24) / 3
        flut = (gust * 0.9 + 0.5 * math.sin(p + 2.0)) * u
        rect(g, round(13 - u - flut), y, round(20 + u - flut * 0.4), y, 'k')
        px(g, [(round(13 - u - flut), y), (round(14 - u - flut), y)], 'K')
    rect(g, 14, 28, 15, 29, 'g'); rect(g, 18, 28, 19, 29, 'g')
    rect(g, 13, 30, 15, 31, 'B'); rect(g, 18, 30, 20, 31, 'B')
    px(g, [(15, 30), (20, 30)], 'H')
    # ---- blouse / torso
    rect(g, 14, 19, 20, 23, 'd')
    px(g, [(14, 19), (14, 20), (14, 21), (14, 22), (14, 23), (15, 23)], 'D')
    px(g, [(17, 20), (17, 21)], 'c')   # little red ribbon at the collar
    px(g, [(16, 20), (18, 20)], 'c')
    # ---- arm + hand holding the basket
    rect(g, 19, 20, 21, 22, 'd'); px(g, [(19, 22)], 'D')
    px(g, [(21, 23), (22, 23)], 's')
    # ---- basket
    for x, y in [(20, 22), (21, 21), (22, 20), (23, 20), (24, 21), (25, 22)]: g[y][x] = 'N'
    rect(g, 20, 23, 25, 23, 'd'); px(g, [(21, 23), (23, 23)], 'c'); px(g, [(25, 23)], 'D')
    rect(g, 20, 24, 25, 26, 'n'); rect(g, 20, 26, 25, 26, 'N'); px(g, [(20, 24), (20, 25)], 'N')
    px(g, [(22, 25), (24, 25)], 'N')
    # ---- head (bobs)
    hy = bob
    # hood
    ell(g, 15.6, 11.6 + hy, 9.4, 8.3, 'R')
    tipx = 7.5 - gust * 2.2 - 0.9 * math.sin(p)
    tipy = 6.2 + 0.9 * math.sin(p + 1.2)
    for k in range(0, 11):                                  # tip blown back, flapping
        a = k / 10
        cx, cy = 10.5 + (tipx - 10.5) * a, 8.0 + (tipy - 8.0) * a
        rad = 1.9 * (1 - a) + 0.45
        for yy in range(int(cy - 2), int(cy + 3)):
            for xx in range(int(cx - 3), int(cx + 3)):
                if (xx - cx) ** 2 + (yy - cy) ** 2 <= rad * rad and 0 <= xx < W and 0 <= yy + hy < H:
                    g[yy + hy][xx] = 'R'
    # hood drape over shoulders
    for y in range(16 + hy, 20):
        for x in range(9, 21):
            if g[y][x] in '.qrRCFG' and ((x - 15) / 6.2) ** 2 + ((y - 15 - hy) / 4.5) ** 2 <= 1: g[y][x] = 'R'
    # shading on hood: left/back darker, top-right light
    for y in range(H):
        for x in range(W):
            if g[y][x] == 'R':
                if x < 10 + (y - hy) // 6: g[y][x] = 'r'
                elif y < 7 + hy and x > 13: g[y][x] = 'L'
    # face opening + face
    ell(g, 19.2, 14.3 + hy, 4.7, 4.4, 's')
    # inner hood shadow ring around face (left side)
    for y in range(9 + hy, 19 + hy):
        for x in range(13, 18):
            if g[y][x] == 's' and g[y][x - 1] in 'RrL': g[y][x - 1] = 'q'
    # hair: bangs + side lock
    for x in range(15, 24):
        g[10 + hy][x] = 'h'
        g[11 + hy][x] = 'h'
    px(g, [(16, 10 + hy), (20, 10 + hy), (21, 11 + hy)], 'H')
    flick = 1 if math.sin(p + 0.5) > 0.35 else 0
    for x in [15, 16, 18, 19, 21, 23]: g[12 + hy][x - flick if x < 23 else x] = 'h'   # bang tips flick
    for y in range(12, 18): g[y + hy][23] = 'h'                         # side lock
    px(g, [(24, 13 + hy), (24, 14 + hy), (24, 15 + hy), (24, 16 + hy)], 'h')
    px(g, [(23, 18 + hy)], 'h')
    # shade under chin + left cheek
    px(g, [(16, 17 + hy), (17, 18 + hy), (15, 16 + hy)], 'S')
    # eyes
    if blink:
        px(g, [(16, 15 + hy), (17, 15 + hy), (20, 15 + hy), (21, 15 + hy)], 'e')
    else:
        px(g, [(17, 14 + hy), (17, 15 + hy), (21, 14 + hy), (21, 15 + hy)], 'e')
    px(g, [(15, 16 + hy), (22, 16 + hy)], 'b')   # blush
    px(g, [(23, 16 + hy)], 'b')
    px(g, [(20, 17 + hy)], mouth)
    # ---- fill enclosed gaps with the most common neighbour colour
    from collections import Counter
    seen = set(); st = [(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)]
    while st:
        x, y = st.pop()
        if (x, y) in seen or not (0 <= x < W and 0 <= y < H) or g[y][x] != '.': continue
        seen.add((x, y)); st += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    for y in range(H):
        for x in range(W):
            if g[y][x] == '.' and (x, y) not in seen:
                nb = Counter(g[ny][nx] for nx, ny in ((x+1,y),(x-1,y),(x,y+1),(x,y-1)) if 0 <= nx < W and 0 <= ny < H and g[ny][nx] != '.')
                g[y][x] = nb.most_common(1)[0][0] if nb else 'O'
    # ---- auto outline
    out = [row[:] for row in g]
    for y in range(H):
        for x in range(W):
            if g[y][x] == '.':
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and g[ny][nx] not in '.':
                        out[y][x] = 'O'; break
    return [''.join(r) for r in out]

frames = [build(t, blink=(t in (21, 22)), bob=(1 if 8 <= t < 16 else 0)) for t in range(24)]
json.dump({'frames': frames, 'key': PAL}, open(sys.argv[1] if len(sys.argv) > 1 else 'red_anime.json', 'w'))
for r in frames[0]: print(r)
