# Cat woman (v3): hand-placed pixels after concepts/cat_woman_concept.png, redrawn at
# red_anime's scale (32x32, ~30 px tall, big chibi head rows 1-18, body 19-31).
# Each part is a list of (row, start_x, pixels); '.' in a run is skipped.
# The script only stacks parts and adds the outer outline.
#   python3 cat_woman.py   -> cat_woman_frames.lua  (loaded by cat_woman.lua)
import os

W = H = 32
PAL = {
    'O': '#100c14',                                   # outline / brows / eyes
    'k': '#24303a', 'K': '#33434c', 'L': '#4d6268',   # catsuit: shade, base, lit
    'M': '#7d9696',                                   # rim light
    'G': '#6a4a3a', 'h': '#b8c8c4',                   # goggle lens, glint
    's': '#f8cfa0', 'S': '#d89a70', 'b': '#ec8a72',   # skin, shade, blush
    'm': '#7a3430',                                   # mouth
    'w': '#8a5a3a', 'W': '#5a3624',                   # whip
}

# ---------------------------------------------------------------- parts
HOOD = [
    (1, 10, "K"), (1, 24, "K"),
    (2, 9, "kKK"), (2, 23, "KLK"),
    (3, 9, "kkKK"), (3, 22, "KkLK"),
    (4, 9, "kkKKKKKKKKKKKKkLK"),
    (5, 8, "kkKKOOOKKKKKOOOKKLK"),
    (6, 8, "kkkOhGGOkkkOhGGOkkk"),
    (7, 8, "kKKOGGWOkkkOGGWOKLK"),
    (8, 8, "kKKKOOOKKKKKOOOKKLK"),
    (9, 8, "kKKKKKKKKKKKKKKKKLK"),
    (10, 8, "kKKKsssssKsssssKKLK"),
    (11, 8, "kKKssOOsssssOOssKLK"),
    (12, 8, "kKkssssOsssOssssKLK"),
    (13, 8, "kKksssOsssssOsssKLK"),
    (14, 8, "kKksssOsssssOsssKLK"),
    (15, 8, "kKksbbssssmssbbsKLK"),
    (16, 8, "kKkSssssmmssssssKLK"),
    (17, 9, "kKkSssssssssssKLK"),
    (18, 10, "kKKSsssssssKKKL"),
]
BODY = [
    (19, 11, "kKKKKKLKKKKKL"),
    (20, 9, "kKKkKKKKLKKKKkKLK"),
    (21, 8, "kKKOkKKKKLKKKKOKLKK"),
    (22, 8, "kKKOkKKKKLKKKKOOKLK"),
    (23, 8, "LLKOkKKKKLKKKKOOLLK"),
    (24, 8, "kKkOkKKKKLKKKKOOkKk"),
    (25, 12, "kKKKKLKKKK"),
    (26, 12, "kKKKKkKKKL"),
    (27, 11, "kKKKK..KKKLK"),
    (28, 10, "kKKKK....KKKLK"),
    (29, 9, "kKKKK......KKKLK"),
    (30, 8, "kkkkkk......kkkkkk"),
    (31, 7, "kkkkkkk......kkkkkkk"),
]
TAIL = [
    (22, 2, "L"),
    (23, 2, "K"),
    (24, 2, "K"),
    (25, 3, "K"),
    (26, 3, "kKKLKKKK"),
    (27, 5, "kkk"),
]
WHIP = [
    (22, 15, "W"),
    (23, 15, "w"),
    (24, 12, "ww"),
    (25, 11, "w.ww"),
    (26, 11, "wW.wW"),
    (27, 12, "wwW"),
    (28, 13, "ww"),
]


def stamp(g, part, dx=0, dy=0):
    for (y, x0, run) in part:
        for i, ch in enumerate(run):
            x, yy = x0 + i + dx, y + dy
            if ch != '.' and 0 <= x < W and 0 <= yy < H:
                g[yy][x] = ch


def outline(g):
    out = [row[:] for row in g]
    for y in range(H):
        for x in range(W):
            if g[y][x] == '.':
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and g[ny][nx] != '.':
                        out[y][x] = 'O'
                        break
    return out


def frame(parts):
    g = [['.'] * W for _ in range(H)]
    for part, dx, dy in parts:          # back to front
        stamp(g, part, dx, dy)
    return [''.join(r) for r in outline(g)]


def base():
    return frame([(TAIL, 0, 0), (BODY, 0, 0), (WHIP, 0, 0), (HOOD, 0, 0)])


FRAMES = [base()]
DUR = [100]

if __name__ == '__main__':
    here = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(here, 'cat_woman_frames.lua'), 'w') as f:
        f.write('return {\n  key = {\n')
        for k, v in PAL.items():
            f.write(f'    ["{k}"] = "{v}",\n')
        f.write('  },\n  dur = {' + ', '.join(map(str, DUR)) + '},\n  frames = {\n')
        for fr in FRAMES:
            f.write('    {\n' + ''.join(f'      "{r}",\n' for r in fr) + '    },\n')
        f.write('  },\n}\n')
    for r in FRAMES[0]:
        print(r)
