# Cat woman run + jump. Hand-drawn body parts (absolute canvas coords at rest);
# the hood/head is the base pose's rows 0-25 so the face stays the reference's.
# Imported by cat_woman.py, which writes every tag into cat_woman_frames.lua.
from cat_woman import BASE, W, H, reoutline

HEAD = (0, 0, BASE[:26])


def stamp(g, patch, dx=0, dy=0, recolor=None):
    x0, y0, rows = patch
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            x, y = x0 + i + dx, y0 + j + dy
            if ch == '.' or not (0 <= x < W and 0 <= y < H):
                continue
            if recolor:
                ch = recolor.get(ch, ch)
            g[y][x] = '.' if ch == '_' else ch


FAR = {'b': 'a', 'd': 'b'}           # far-side limbs sit one shade darker

# ---------------------------------------------------------------- torso
TORSO = (20, 26, [
    "...OOOOOOOOOOOOO...",
    "..OabddbbbbObbbdO..",
    "..OaabbbbbbObbbddO.",
    ".OaaabbbbbbObbbddO.",
    ".OaaabbbbbbObbbddO.",
    ".OaaabbbbbbObbbbdO.",
    ".OaaabbbbbbObbbbdO.",
    ".OaaabbbbbbObbbbdO.",
    ".OaaabbbbbbObbbbdO.",
    ".OaaabbbbbbObbbbdO.",
    "OaaaabbbbbbbbbbbdO.",
    "OaaaabbbbbbbbbbbdO.",
    "OaaaaabbbbbbbbbbbO.",
    ".OaaaaabbbbbbbbbO..",
    "..OOOOOOOOOOOOOO...",
])

WHIP = (20, 32, [
    ".OOOOO.",
    "OwwwwlO",
    "OwOOOwO",
    "OWOwOwO",
    "OWOOOwO",
    "OWWwwwO",
    ".OOOOO.",
])

# ---------------------------------------------------------------- arms
ARM_R = {   # right side of the torso, drawn in front
    'fwd': (34, 26, [
        ".......OOO.",
        "......OddbO",
        "..OO..ObbbO",
        ".ObbOObbbaO",
        ".ObbbbbbaO.",
        "..OabbbaO..",
        "...OOOOO...",
    ]),
    'mid': (34, 27, [
        ".OOO......",
        "ObbbO.....",
        "ObbbbOOOO.",
        ".ObbbbddbO",
        ".ObbbbbbbO",
        "..OabbbbaO",
        "...OOOOOO.",
    ]),
    'back': (33, 27, [
        "..OOO.....",
        ".ObbbO....",
        ".ObbbbO...",
        "..ObbbbO..",
        "...ObbbbO.",
        "...OabbbO.",
        "..OabbbO..",
        ".OabbbO...",
        "OddbbO....",
        "ObbbaO....",
        "OabaO.....",
        ".OOO......",
    ]),
}
ARM_L = {   # left side, behind the torso
    'back': (12, 27, [
        "........OOO.",
        ".......OaabO",
        "......OaabO.",
        ".....OaabO..",
        "..OOOaabO...",
        ".OdbbaaO....",
        "ObbbbaO.....",
        "OabbaO......",
        ".OOOO.......",
    ]),
    'mid': (14, 28, [
        "......OOO",
        ".....OaaO",
        "....OaabO",
        "...OaabO.",
        "..OaabO..",
        ".OdbbaO..",
        ".ObbbaO..",
        "..OOOO...",
    ]),
    'fwd': (15, 27, [
        "..OOO...",
        ".OdbbO..",
        ".ObbbaO.",
        "..OabaaO",
        "...OaaaO",
        "....OOO.",
    ]),
}

# ---------------------------------------------------------------- legs
# Drawn for the near (right) hip; the far leg is the same drawing 5 px left
# and one shade darker.
LEG = {
    'fwd': (28, 38, [            # reaching forward, heel down
        ".ObbbbO.........",
        ".ObbbbbO........",
        "..ObbbbbO.......",
        "...ObbbbbO......",
        "....ObbbbdO.....",
        ".....ObbbbdO....",
        "......ObbbbdOO..",
        "......OabbbbddO.",
        "......OaaabbbbdO",
        "......OOOOOOOOOO",
    ]),
    'back': (16, 38, [           # trailing, pushing off the toe
        "...........ObbbO",
        "..........ObbbbO",
        ".........ObbbbO.",
        "........ObbbbO..",
        ".......ObbbbO...",
        "......OabbbO....",
        "....OOabbbO.....",
        "...OaabbbO......",
        "..OaaaabO.......",
        "..OOOOOO........",
    ]),
    'under': (28, 38, [          # planted under the hips, knee soft
        ".ObbbbbO......",
        ".ObbbbbO......",
        ".ObbbbbdO.....",
        ".OabbbbdO.....",
        ".OabbbbdO.....",
        ".OabbbbbdO....",
        ".OaabbbbbdO...",
        ".OaaabbbbbdO..",
        ".OaaaaabbbbO..",
        ".OOOOOOOOOOO..",
    ]),
    'plant': (28, 38, [          # just landed: knee bent forward over the boot
        ".ObbbbO.........",
        ".ObbbbbO........",
        "..ObbbbbO.......",
        "..ObbbbbdO......",
        "..OabbbbdO......",
        "..OabbbbO.......",
        "..OabbbbbdO.....",
        "..OaabbbbbddO...",
        "..OaaaabbbbbdO..",
        "..OOOOOOOOOOOO..",
    ]),
    'lift': (18, 38, [           # toe has left the ground, boot swinging up
        "..........ObbbO",
        ".........ObbbbO",
        "........ObbbbO.",
        ".......ObbbbO..",
        "....OOObbbbO...",
        "..OOabbbbbO....",
        ".OaabbbbOO.....",
        "OaaaabOO.......",
        "OOOOOO.........",
    ]),
    'tuck': (24, 38, [           # passing: knee up front, boot kicked back
        ".....ObbbbbO.",
        "....ObbbbbbdO",
        "...OabbbbbbdO",
        "..OaabbbbbdO.",
        ".OaabbOOOOO..",
        "OaabbO.......",
        "OaaabO.......",
        ".OOOO........",
    ]),
}

# ---------------------------------------------------------------- tail
TAIL = {
    'up': (4, 30, [
        "OO.................",
        "OdO................",
        "ObdO...............",
        ".ObbO..............",
        "..ObbOO............",
        "...OabbOOO.........",
        "....OaabbbOOO......",
        ".....OOaabbbbOO....",
        ".......OOaaaabbO...",
        ".........OOOOOO....",
    ]),
    'mid': (3, 33, [
        "OO................",
        "ObO...............",
        "ObbOOOO...........",
        ".ObbbbbOOOOO......",
        "..OaabbbbbbbOOO...",
        "...OOaaaaaabbbbO..",
        ".....OOOOOOOOOO...",
    ]),
    'down': (3, 36, [
        "............OOOO.",
        ".OO.......OOabbO.",
        "OdbO....OOaabbO..",
        "ObbbOOOOaaabbO...",
        ".OabbbbbbbbOO....",
        "..OOOOOOOOO......",
    ]),
}


def _upper():
    """The base pose above the legs: hood, guard-up arms, torso and whip coil.
    The old tail and the old legs are cleared."""
    g = [list(r) for r in BASE]
    for y in range(H):
        for x in range(W):
            tail = (30 <= y <= 36 and x <= 10) or (37 <= y <= 40 and x <= 13)
            legs = y >= 43 or (y >= 41 and not 15 <= x <= 19)
            if tail or legs:
                g[y][x] = '.'
    return g


UPPER = _upper()


def _shift(rows, n):
    blank = ['.'] * W
    if n >= 0:
        return [blank[:] for _ in range(n)] + [r[:] for r in rows[:H - n]]
    return [r[:] for r in rows[-n:]] + [blank[:] for _ in range(-n)]


def _bob(body, head):
    """Upper body moved down by `body` px and the hood by `head` px (negative =
    up). A hood that trails above the body leaves a gap, filled by repeating the
    hood's bottom row; a hood that sinks lower overlaps the shoulders (squash)."""
    torso = _shift(UPPER, body)
    hood = _shift(UPPER[:26] + [['.'] * W for _ in range(H - 26)], head)
    g = [r[:] for r in torso]
    for y in range(26 + body):            # clear the torso copy's hood rows
        if 0 <= y < H:
            g[y] = ['.'] * W
    for k in range(26 + head, 26 + body):  # gap under a trailing hood
        if 0 <= k < H:
            g[k] = UPPER[25][:]
    for y in range(H):
        for x in range(W):
            if hood[y][x] != '.':
                g[y][x] = hood[y][x]
    return g


def pose(body=0, head=0, near='fwd', far='back', tail='mid', near_dx=3, far_dx=-8,
         legs_dy=0):
    g = [['.'] * W for _ in range(H)]
    stamp(g, TAIL[tail], dy=body)
    stamp(g, LEG[far], dx=far_dx, dy=legs_dy, recolor=FAR)
    stamp(g, LEG[near], dx=near_dx, dy=legs_dy)
    up = _bob(body, head)
    for y in range(H):
        for x in range(W):
            if up[y][x] != '.':
                g[y][x] = up[y][x]
    return [''.join(r) for r in reoutline(g)]


from cat_woman_rig import build_run
RUN = [(f, 70) for f in build_run()]


from cat_woman_rig import build_jump
JUMP = build_jump()
