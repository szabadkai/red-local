# Cat woman run/jump rig. Each frame is a skeleton (hip, knees, ankles, shoulders,
# elbows, fists, neck); limbs are drawn as shaded, separately outlined capsules,
# the tail is a follow-the-leader chain (like Madeline's hair in Celeste), and the
# hood/head is the reference's own pixels, leaning and trailing the bounce.
# Pose structure: Slynyrd Pixelblog 8 run (contact > recoil > pass > high, x2).
import math
from cat_woman import BASE, W, H

# ---------------------------------------------------------------- raster parts
def blank():
    return [['.'] * W for _ in range(H)]


def seg_dist(px, py, ax, ay, bx, by):
    vx, vy = bx - ax, by - ay
    L = vx * vx + vy * vy
    t = 0 if L == 0 else max(0, min(1, ((px - ax) * vx + (py - ay) * vy) / L))
    qx, qy = ax + vx * t, ay + vy * t
    return math.hypot(px - qx, py - qy)


def capsules(segs):
    """segs: [(ax, ay, bx, by, r)]. Returns the set of filled pixels."""
    pts = set()
    for (ax, ay, bx, by, r) in segs:
        for y in range(int(min(ay, by) - r - 1), int(max(ay, by) + r + 2)):
            for x in range(int(min(ax, bx) - r - 1), int(max(ax, bx) + r + 2)):
                if 0 <= x < W and 0 <= y < H and seg_dist(x, y, ax, ay, bx, by) <= r:
                    pts.add((x, y))
    return pts


def shade(pts, dark=False):
    """Light from the upper right. Near parts: 'b' body, a 2-px lit 'd' edge on
    the top/right, 'a' on the bottom/left edge. Far parts sit one step darker
    ('a' body, 'b' lit edge) so overlapping limbs separate by value."""
    def edge(x, y, dirs):
        return any((x + dx, y + dy) not in pts for dx, dy in dirs)
    LIT = ((1, 0), (0, -1), (1, -1))
    out = {}
    for (x, y) in pts:
        lit1 = edge(x, y, LIT)
        lit2 = not lit1 and edge(x, y, ((2, 0), (0, -2), (1, -1), (2, -1), (1, -2)))
        shadow = edge(x, y, ((-1, 0), (0, 1), (-1, 1)))
        if dark:
            c = 'b' if lit1 and not shadow else 'a'
        else:
            c = 'd' if (lit1 or lit2) and not shadow else ('a' if shadow and not lit1 else 'b')
        out[(x, y)] = c
    return out


def put_part(g, colored, seam=True):
    """Composite a part with its own 1-px outline. seam=True keeps a line where
    it overlaps earlier parts (separate limbs); seam=False outlines only against
    empty space, so the part grows out of what's under it (hood into shoulders)."""
    for (x, y) in colored:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < W and 0 <= ny < H and (nx, ny) not in colored:
                if seam or g[ny][nx] == '.':
                    g[ny][nx] = 'O'
    for (x, y), c in colored.items():
        g[y][x] = c


# ---------------------------------------------------------------- body parts
def leg(hip, knee, ankle, toe_dir, dark=False):
    """Thigh and shin taper; the boot is its own darker block with a lit top
    edge so it reads as a boot, not the end of a tube."""
    hx, hy = hip; kx, ky = knee; ax, ay = ankle
    tx, ty = ax + toe_dir[0] * 3.4, ay + toe_dir[1] * 3.4
    limb = capsules([(hx, hy, kx, ky, 3.0), (kx, ky, ax, ay, 2.3)])
    boot = capsules([(ax - toe_dir[0] * 1.0, ay - toe_dir[1] * 1.0, tx, ty, 2.4)])
    c = shade(limb | boot, dark)
    # boot cuff: a dark band across the shin just above the boot
    for p in limb - boot:
        if any((p[0] + dx, p[1] + dy) in boot for dx, dy in ((0, 1), (1, 1), (-1, 1), (1, 0), (-1, 0))):
            c[p] = 'O'
    return c


def arm(shoulder, elbow, fist, dark=False):
    sx, sy = shoulder; ex, ey = elbow; fx, fy = fist
    pts = capsules([(sx, sy, ex, ey, 2.4), (ex, ey, fx, fy, 2.1), (fx, fy, fx, fy, 2.8)])
    return shade(pts, dark)


def torso(hip, neck, r=6.4):
    """Body and shoulder yoke as one shape: the yoke spreads under the hood as
    wide as the hood's lower rim, so the hood drapes onto shoulders instead of
    sitting on a tube."""
    hx, hy = hip; nx, ny = neck
    pts = capsules([(hx, hy - 1, nx, ny + 3, r), (hx, hy - 1, hx, hy - 1, r + 0.2),
                    (nx - 9, ny + 4, nx + 7, ny + 4, 3.6)])
    c = shade(pts)
    # zipper: 1 px dark line from collar to belly, following the lean
    for i in range(0, 9):
        t = i / 12
        zx = round(nx + 1 + (hx - nx) * t + 1)
        zy = round(ny + 3 + (hy - ny) * t)
        if (zx, zy) in c:
            c[(zx, zy)] = 'O'
    return c


def tail_chain(root, prev_pts, vel, n=9, seg=2.0):
    """Follow-the-leader chain: the root is pinned, each point keeps at most
    `seg` px from the one before, and sags a little each frame."""
    pts = [root]
    for i in range(1, n):
        px, py = prev_pts[i]
        px, py = px - vel[0] * 0.55 * i / n, py + 0.12 - vel[1] * 0.35 - 0.25 * (i / n) ** 2   # drag, light gravity, tip curls up
        ax, ay = pts[-1]
        d = math.hypot(px - ax, py - ay)
        if d > seg:
            px, py = ax + (px - ax) * seg / d, ay + (py - ay) * seg / d
        pts.append((px, py))
    return pts


def tail_curve(root, phase, n=9, seg=2.0, base=165, curl=85, amp=18):
    """Cat tail: leaves the hip pointing back, curves up toward the tip; a wave
    travels down it, driven by the bounce (phase) a beat late."""
    x, y = root
    pts = [(x, y)]
    for i in range(1, n):
        s = i / (n - 1)
        th = base - curl * s ** 1.4 + amp * (0.3 + s) * math.sin(phase - 2.8 * s)
        x += math.cos(math.radians(th)) * seg
        y -= math.sin(math.radians(th)) * seg
        pts.append((x, y))
    return pts


def tail_part(pts):
    segs = []
    for i in range(len(pts) - 1):
        r = 1.8 - 0.8 * i / (len(pts) - 1)
        segs.append((pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], r))
    return shade(capsules(segs), dark=True)


# hood/head = base rows 0-25; chin centre at (31, 25), neck below it at (31, 26)
HEAD_ROWS = BASE[:26]


def head_part(dx, dy, act=None):
    """The reference's hood, acted per frame. act keys:
      pitch   0..2  top of the hood shears forward (nod into the step)
      squash  -1/0/1 crown row 4 removed / doubled; the chin stays put
      ear_n, ear_f  ear flop for the near (right) and far (left) ear:
              >0 drags back and down (rising), <0 tips forward (landing)
      mouth   'open' = panting
    """
    act = act or {}
    rows = [list(r) for r in HEAD_ROWS]
    if act.get('mouth') == 'open':
        rows[22][31], rows[22][32], rows[22][33] = 'm', 'O', 'm'
        rows[23][32] = 'm'
    sq = act.get('squash', 0)
    ear_rows = 4                                       # rows 0-3 hold the ear tips
    if sq < 0:
        rows = rows[:4] + rows[5:]
    elif sq > 0:
        rows = rows[:5] + [rows[4][:]] + rows[5:]
    n = len(rows)
    top = dy + (26 - n)                                # chin row stays where it was
    pitch = act.get('pitch', 0)

    face_top = 12 + (n - 26)                           # first brow row after squash

    def shear(r):                                      # only the hood above the brows nods
        if r >= face_top:
            return 0
        return round(pitch * (face_top - r) / face_top + 0.25)

    c = {}
    ears = {}
    for r, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == '.':
                continue
            X, Y = x + dx + shear(r), top + r
            if r < ear_rows and (x <= 23 or x >= 33):
                e = act.get('ear_n' if x >= 33 else 'ear_f', 0)
                if e > 0:                              # drag back and down
                    X, Y = X - e, Y + e
                elif e < 0:                            # tip forward, dip a little
                    X, Y = X - e, Y + (1 - e) // 2
                ears[(X, Y)] = ch
            else:
                c[(X, Y)] = ch
    out = {p: ch for p, ch in ears.items() if 0 <= p[0] < W and 0 <= p[1] < H}
    for p, ch in c.items():                            # crown sits over the ear roots
        if 0 <= p[0] < W and 0 <= p[1] < H:
            out[p] = ch
    return out


# whip coil: the base's own coil pixels (rows 33-41, x 14-21), hung on the hip;
# only the main connected coil is kept (the loose handle bits read as specks)
def _whip():
    px = {(x, y): BASE[y][x] for y in range(33, 42) for x in range(14, 22) if BASE[y][x] in 'wWl'}
    seen, comps = set(), []
    for p in px:
        if p in seen:
            continue
        comp, st = [], [p]
        while st:
            q = st.pop()
            if q in seen or q not in px:
                continue
            seen.add(q); comp.append(q)
            st += [(q[0] + dx, q[1] + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)]
        comps.append(comp)
    main = max(comps, key=len)
    return {(x - 18, y - 37): px[(x, y)] for (x, y) in main}


WHIP = _whip()


# ---------------------------------------------------------------- the run
# Per pose: hip (x,y); legs as (knee, ankle, toe) offsets from their hip joint;
# arms as (elbow, fist) offsets from their shoulder. 'N' = near side, 'F' = far.
UP = (0.9, -0.45)    # toe up (heel strike)
FLAT = (1, 0)
DOWN = (0.55, 0.85)  # toe pointing down (pushing / trailing)
BACKDN = (-0.2, 1)   # boot hanging under a raised knee

RUN_POSES = [
    # contact: near heel strikes ahead, far boot up behind; arms opposite
    dict(hip=(25, 37), th=11, lean=3, r=6.4, head=dict(pitch=1, ear_n=0),
         N=((4, 3), (8, 7), UP),     F=((-3, 4), (-8, 4), DOWN),
         aN=((-3, 3), (-7, 2)),      aF=((3, 3), (7, 0))),
    # recoil: weight lands, knee soaks it up, body squashes; trailing boot flicks up
    dict(hip=(24, 39), th=10, lean=4, r=6.9,
         head=dict(pitch=2, squash=-1, ear_n=-1, mouth='open'),
         N=((4, 2), (2, 5), FLAT),   F=((-2, 3), (-8, 0), DOWN),
         aN=((-2, 4), (-5, 4)),      aF=((3, 3), (6, 2))),
    # pass: support leg under the hip, swing knee comes through, arms at the sides
    dict(hip=(25, 37), th=11, lean=3, r=6.4, head=dict(pitch=1, ear_n=0, mouth='open'),
         N=((1, 4), (0, 7), FLAT),   F=((3, 2), (-1, 5), BACKDN),
         aN=((0, 4), (2, 5)),        aF=((0, 4), (-2, 5))),
    # high: toe leaves the ground, knee drives up, body stretches; near fist punches
    dict(hip=(26, 36), th=12, lean=2, r=6.0, head=dict(pitch=0, squash=1, ear_n=1),
         N=((-2, 4), (-6, 6), DOWN), F=((5, 1), (5, 5), BACKDN),
         aN=((3, 2), (7, -1)),       aF=((-3, 3), (-7, 3))),
]


def mirror(p):
    """Second half of the cycle: near and far swap roles."""
    q = dict(p)
    q.update(N=p['F'], F=p['N'], aN=p['aF'], aF=p['aN'])
    return q


RUN_SEQ = RUN_POSES + [mirror(p) for p in RUN_POSES]
LEAN = 3          # neck sits this far ahead of the hip
TORSO_H = 11      # hip to neck


def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def head_track(seq):
    """Hood offset and acting per frame. The hood follows the neck but lags it
    by up to 1 px; the far ear repeats the near ear's previous flop (overlap);
    a stretch is skipped when the ears would leave the canvas."""
    cur = [p['hip'][1] - p.get('th', TORSO_H) - 24 for p in seq]
    dys = [max(0, c + max(-1, min(1, cur[i - 1] - c))) for i, c in enumerate(cur)]
    acts = []
    for i, p in enumerate(seq):
        a = dict(p.get('head', {}))
        a['ear_f'] = seq[i - 1].get('head', {}).get('ear_n', 0)
        if a.get('squash', 0) > 0 and dys[i] < 1:
            a['squash'] = 0
        acts.append(a)
    return dys, acts


def draw_pose(p, prev_hip, head_dy, act, tail_pts):
    hip = p['hip']
    th, lean, r = p.get('th', TORSO_H), p.get('lean', LEAN), p.get('r', 6.4)
    neck = (hip[0] + lean, hip[1] - th)
    head_dx = neck[0] - 31
    g = blank()
    hipN, hipF = add(hip, (3, 0)), add(hip, (-3, 0))
    shN, shF = add(neck, (6, 5)), add(neck, (-8, 5))      # ends of the yoke
    kF, aF, tF = p['F']
    kN, aN, tN = p['N']
    put_part(g, arm(shF, add(shF, p['aF'][0]), add(shF, p['aF'][1]), dark=True))
    put_part(g, leg(hipF, add(hipF, kF), add(hipF, aF), tF, dark=True))
    put_part(g, tail_part(tail_pts))
    put_part(g, torso(hip, neck, r))
    wy = prev_hip[1] - hip[1]                          # coil bounces a frame late
    coil = {}
    for (x, y), ch in WHIP.items():
        X, Y = hip[0] - 3 + x, hip[1] - 3 + y + max(-1, min(1, wy))
        if 0 <= X < W and 0 <= Y < H:
            coil[(X, Y)] = ch
    put_part(g, coil)
    put_part(g, leg(hipN, add(hipN, kN), add(hipN, aN), tN))
    near_arm = arm(shN, add(shN, p['aN'][0]), add(shN, p['aN'][1]))
    raised = p['aN'][1][1] < -1                        # fist above the shoulder
    if raised:                                         # swings up behind the hood
        put_part(g, near_arm)
    put_part(g, head_part(head_dx, head_dy, act), seam=False)
    if not raised:
        put_part(g, near_arm)
    return [''.join(r) for r in g]


def build_run():
    n = len(RUN_SEQ)
    dys, acts = head_track(RUN_SEQ)
    frames = []
    for i, p in enumerate(RUN_SEQ):
        # two bounces per cycle; the tail answers one frame late
        tail = tail_curve(add(p['hip'], (-7, -1)), 2 * math.pi * 2 * (i - 1) / n)
        frames.append(draw_pose(p, RUN_SEQ[i - 1]['hip'], dys[i], acts[i], tail))
    return frames


# ---------------------------------------------------------------- the jump
# The hood touches the top of the canvas, so the hip never rises above y 35;
# airborne frames read from the tucked legs (the game moves the sprite).
JUMP_SEQ = [
    # crouch: sink, knees out, arms swing back, lean in
    (dict(head=dict(pitch=2, squash=-1, ear_n=-1), hip=(24, 39), N=((4, 2), (3, 5), FLAT), F=((-3, 2), (-3, 5), FLAT),
          aN=((-3, 2), (-6, 3)), aF=((-3, 2), (-6, 2))), 4, (195, 55, 0), 110),
    # take-off: everything stretches, toes leave last, arms thrown up
    (dict(head=dict(pitch=0, squash=1, ear_n=2, mouth='open'), hip=(25, 35), N=((1, 4), (0, 9), DOWN), F=((-1, 4), (-3, 8), DOWN),
          aN=((3, -2), (5, -5)), aF=((2, -2), (3, -6))), 1, (205, 25, 0), 70),
    # rise: knees pull up, tail still dragging below
    (dict(head=dict(pitch=0, squash=1, ear_n=1, mouth='open'), hip=(25, 35), N=((4, 1), (2, 5), BACKDN), F=((2, 2), (-2, 5), BACKDN),
          aN=((3, -1), (5, -4)), aF=((2, -1), (4, -4))), 1, (198, 45, 0), 80),
    # apex: tight tuck, arms open for balance, tail curls up
    (dict(head=dict(pitch=1, ear_n=0), hip=(25, 35), N=((5, 0), (3, 4), BACKDN), F=((3, 1), (-1, 4), BACKDN),
          aN=((3, 1), (6, 0)), aF=((-3, 1), (-6, 0))), 2, (160, 100, 0), 140),
    # fall: legs open and reach for the ground, arms lift, tail streams up
    (dict(head=dict(pitch=1, ear_n=-1), hip=(25, 35), N=((2, 4), (3, 8), DOWN), F=((-2, 4), (-3, 7), DOWN),
          aN=((3, -1), (5, -3)), aF=((-3, -1), (-5, -3))), 2, (140, 110, 0), 90),
    # land: deep squash, arms forward to catch the weight, tail whips down
    (dict(head=dict(pitch=2, squash=-1, ear_n=-2, mouth='open'), hip=(25, 40), N=((5, 1), (3, 4), FLAT), F=((-4, 1), (-4, 4), FLAT),
          aN=((3, 3), (6, 4)), aF=((-2, 3), (-5, 4))), 4, (178, 40, 0), 120),
    # recover: rise out of it
    (dict(head=dict(pitch=1, ear_n=0), hip=(25, 37), N=((2, 3), (1, 7), FLAT), F=((-2, 3), (-2, 7), FLAT),
          aN=((1, 4), (3, 5)), aF=((-1, 4), (-2, 5))), 3, (165, 85, 0), 90),
]


def build_jump():
    seq = []
    for (p, lean, tl, ms) in JUMP_SEQ:
        q = dict(p); q.setdefault('lean', lean); seq.append(q)
    dys, acts = head_track(seq)
    frames = []
    for i, (p, lean, (tb, tc, ta), ms) in enumerate(JUMP_SEQ):
        tail = tail_curve(add(p['hip'], (-7, -1)), 0, base=tb, curl=tc, amp=ta)
        frames.append((draw_pose(seq[i], seq[i - 1]['hip'], dys[i], acts[i], tail), ms))
    return frames
