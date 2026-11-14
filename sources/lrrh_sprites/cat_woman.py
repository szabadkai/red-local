# Cat woman idle, 48x48, from concepts/cat_woman_concept.png.
# The base pose is cat_woman_base.txt (converted cell by cell by
# enemy_gen/cat_woman_convert.py, then hand-fixed). Every animated part below is a
# hand-drawn pixel patch; this script only picks patches per frame and stacks them.
#   python3 cat_woman.py   -> cat_woman_frames.lua  (loaded by cat_woman.lua)
import os

HERE = os.path.dirname(os.path.abspath(__file__))
W = H = 48


def read_base():
    key, rows = {}, []
    for line in open(os.path.join(HERE, 'cat_woman_base.txt')):
        line = line.rstrip('\n')
        if line.startswith('# '):
            k, v = line[2:].split()
            key[k] = v
        elif line:
            rows.append(line)
    return key, rows


KEY, BASE = read_base()
KEY['H'] = '#dfeae6'          # goggle glint flash

# ---------------------------------------------------------------- patches
# (x0, y0, rows): '.' = leave alone, '_' = clear to transparent.

# Tail: only the upright part moves (rows 30-36); the bend and the base at the hip
# (rows 37-40) stay put. Region x 2-10.
TAIL_CLEAR = (2, 30, ["_________"] * 7)
TAIL = {
    'mid': (2, 30, [
        ".........",
        ".........",
        "....OO...",
        "...OddO..",
        "...ObdO..",
        "...ObddO.",
        "....ObdOO",
    ]),
    'fwd': (2, 30, [                     # tip leans toward the body
        ".........",
        ".........",
        ".....OO..",
        "....OddO.",
        "...ObddO.",
        "...ObddO.",
        "....ObdOO",
    ]),
    'back': (2, 30, [                    # tip swings out and back
        ".........",
        ".........",
        "..OO.....",
        ".OddO....",
        "..ObdO...",
        "...ObddO.",
        "....ObdOO",
    ]),
    'up': (2, 30, [                      # tip flicks up a pixel
        ".........",
        "....OO...",
        "...OddO..",
        "...ObdO..",
        "...ObdO..",
        "...ObddO.",
        "....ObdOO",
    ]),
}

# Right ear: tip flicks outward and down (twitch).
EAR_TWITCH = (33, 0, [
    "________",
    "....OO..",
    "OOaaabO.",
    "OOaabO..",
])

# Eyes (2x3 each at x27-28 and x37-38, rows 17-19).
EYES = {
    'open': None,
    'half': [(27, 17, ["ss", "OO", "OO"]), (37, 17, ["ss", "OO", "OO"])],
    'shut': [(27, 17, ["ss", "OO", "ss"]), (37, 17, ["ss", "OO", "ss"])],
}

# Goggle glint flash: the two glint pixels on each lens brighten and spread.
GLINT = [(27, 7, ["Hh.", ".HH"]), (37, 7, ["Hh.", ".HH"])]


def stamp(g, patch, dy=0):
    x0, y0, rows = patch
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            x, y = x0 + i, y0 + j + dy
            if ch == '.' or not (0 <= x < W and 0 <= y < H):
                continue
            g[y][x] = '.' if ch == '_' else ch


def reoutline(g):
    """Seal any opaque edge left open by a moved patch with the outline colour."""
    out = [r[:] for r in g]
    for y in range(H):
        for x in range(W):
            if g[y][x] == '.':
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and g[ny][nx] not in '.O':
                        out[y][x] = 'O'
                        break
    return out


def build(bob=0, tail='mid', ear=False, eyes='open', glint=False):
    g = [list(r) for r in BASE]
    # face/hood details are stamped before the bob so they ride along with it
    if ear:
        stamp(g, EAR_TWITCH)
    if EYES[eyes]:
        for p in EYES[eyes]:
            stamp(g, p)
    if glint:
        for p in GLINT:
            stamp(g, p)
    stamp(g, TAIL_CLEAR)
    stamp(g, TAIL[tail])
    # breathe out: everything above the legs settles 1 px; row 40 (hip/leg join)
    # folds away and the legs from row 41 stay planted. At bob 0.5 the body has
    # settled but the head hasn't yet (the hood's bottom row 25 is doubled).
    if bob == 1:
        g = [['.'] * W] + g[:40] + g[41:]
    elif bob == 0.5:
        g = g[:26] + g[25:40] + g[41:]
    return [''.join(r) for r in reoutline(g)]


# per-frame spec: (bob, tail, ear twitch, eyes, glint, ms)
SPEC = [
    (0,   'mid',  False, 'open', False, 100),
    (0,   'fwd',  False, 'open', False, 100),
    (0,   'fwd',  False, 'open', True,  100),
    (0,   'mid',  False, 'open', True,  100),
    (0,   'back', False, 'open', False, 100),
    (0.5, 'back', False, 'open', False, 90),
    (1,   'mid',  False, 'open', False, 100),
    (1,   'fwd',  False, 'open', False, 100),
    (1,   'fwd',  False, 'half', False, 80),
    (1,   'mid',  False, 'shut', False, 160),
    (1,   'back', False, 'half', False, 80),
    (0.5, 'back', False, 'open', False, 90),
    (0,   'mid',  True,  'open', False, 90),
    (0,   'up',   False, 'open', False, 90),
    (0,   'up',   True,  'open', False, 110),
]

if __name__ == '__main__':
    from cat_woman_moves import RUN, JUMP
    idle = [(build(b, t, e, ey, gl), ms) for (b, t, e, ey, gl, ms) in SPEC]
    tags, frames = [], []
    for name, seq in (('idle', idle), ('run', RUN), ('jump', JUMP)):
        if seq:
            tags.append((name, len(frames) + 1, len(frames) + len(seq)))
            frames += seq
    with open(os.path.join(HERE, 'cat_woman_frames.lua'), 'w') as f:
        f.write(f'return {{\n  w = {W}, h = {H},\n  key = {{\n')
        for k, v in KEY.items():
            f.write(f'    ["{k}"] = "{v}",\n')
        f.write('  },\n  dur = {' + ', '.join(str(ms) for _, ms in frames) + '},\n')
        f.write('  tags = {' + ', '.join(f'{{"{n}", {a}, {b}}}' for n, a, b in tags) + '},\n  frames = {\n')
        for fr, _ in frames:
            f.write('    {\n' + ''.join(f'      "{r}",\n' for r in fr) + '    },\n')
        f.write('  },\n}\n')
    print(len(frames), 'frames', tags)
