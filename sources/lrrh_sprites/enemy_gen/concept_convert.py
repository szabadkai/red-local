# Downscale one character row of a concept sheet (concepts/enemies_concept_2.png by default,
# or the entry's "src", e.g. enemies_concept_1.png for the boar) into 32x32 pose drafts.
#   uv run --with pillow --with numpy python concept_convert.py <name> [out_dir] [--force]
# Writes <out_dir>/<name>_poses.png: the 9 concept poses side by side, 32x32 each, transparent.
# An entry's "size" (e.g. 48 for the story bosses) changes the cell size, and "lua_dir" where
# its <name>_poses.lua goes.
# Every pose uses the same scale and is anchored on the row's ground line, so heights (jumps,
# crouches) survive. Colours snap to a hand-picked palette by majority vote over each block;
# background and ground-shadow colours become transparent. The result is a draft to fix by hand.
import os
import sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "concepts", "enemies_concept_2.png")

BG = ["#625064", "#5d4c60", "#5f4e62", "#645266", "#69576a", "#58475b", "#514156", "#6b5a6e", "#55465a"]
SHADOW = ["#3f3346", "#46394d", "#392d40"]          # only treated as background near the ground line

OUT_ALIASES = ["#0a0610", "#0d0b17", "#11101a", "#171520", "#191722", "#0c0a15", "#0f0e18", "#16141f", "#0f0d18", "#15131e"]

BOAR_BG = ["#655863", "#665964", "#645762", "#635461", "#645561", "#635661", "#625460", "#605360",
           "#665962", "#5d4f5a", "#655861", "#675a66", "#6c616b", "#625862", "#645963"]
BOAR_SHADOW = ["#4f444e", "#423a44", "#3a2f39", "#453a45", "#3b303a", "#514651", "#4d434d", "#574c56"]

CHARS = {
    # concept 1 (the first enemies sheet): idle x2, run x2, attack x2, charge, hit x2, death x2
    "wild_boar": dict(src="enemies_concept_1.png", band=(440, 512.0), scale=2.2, art_x=280, split=[551, 1272],
        pose_cx={3: 508, 4: 610, 6: 843, 7: 1067, 8: 1224, 10: 1411}, pose_sx={3: 2.35, 4: 2.35, 6: 2.5, 7: 3.1, 10: 2.7}, pose_s={1: 2.0, 2: 2.0},
        bg=BOAR_BG, shadow=BOAR_SHADOW, pal={
        "o": ["#1c121b", "#170c16", "#1a111b", "#10050f", "#19131c", "#1e131d", "#211018", "#221420", "#1f131c"],
        "1": ["#2e1e2a", "#271522", "#2c1f2a", "#2b1c24", "#291a21", "#342019", "#241a22", "#292028"],
        "2": ["#3f242d", "#3e2f36", "#382933", "#34232d", "#40333c"],
        "3": ["#503840", "#4f353e", "#514049", "#59414b"],
        "4": ["#684e54", "#65474d", "#694f55", "#623a41"],
        "5": ["#764f53", "#745155", "#7a4e52", "#795558", "#775054", "#704f54"],
        "6": ["#805a57", "#7e5859", "#836065", "#855959", "#7f5f5f"],
        "7": ["#8f605e", "#9a6e6a", "#925e5d", "#896165", "#8b6263", "#a0766b"],
        "s": ["#cf9580", "#c88f73", "#ca8f73", "#c78d78", "#b78979", "#af8978", "#ae766e"],
        "S": ["#ebcbb1", "#e6cdc1", "#dab0a5", "#d4a591", "#d8bcae", "#ceada3"],
        "t": ["#f6d7c6", "#ffe8d9", "#fff1e6", "#f0dfcc", "#f5e0d3", "#fad3c5"],
        "d": ["#ad948e", "#b2928b", "#a39694"],     # dust
    }, weight={"t": 4, "S": 2, "s": 1.5, "o": 1.2}),
    # band = (top, ground) in concept pixels; scale = concept px per sprite px
    "brown_bear": dict(band=(14, 152.6), scale=4.35, split=[968], pal={
        "o": ["#15141e"] + OUT_ALIASES,
        "1": ["#27202f", "#231c2a"], "2": ["#3b2a39", "#312838", "#423041"], "3": ["#553b4b", "#4c3546"],
        "4": ["#724953", "#694755"], "5": ["#875d5e", "#7c5258"], "m": ["#a47f7a", "#996f6c"],
        "n": ["#cb9f86", "#c69684"], "N": ["#e3c6b7", "#e6cabb"], "r": ["#6c3947", "#8a3c48"],
        "y": ["#f3cb29", "#fdda27", "#ecbb1f", "#d9af30"],
    }, weight={"y": 6, "N": 2, "r": 2}),
    "forest_stag": dict(band=(184, 311.9), scale=4.1, pal={
        "o": ["#15141e"] + OUT_ALIASES,
        "1": ["#221d2b", "#1c1926", "#2e2536"], "2": ["#423041", "#4c3546"], "3": ["#553b4b", "#5f4150"],
        "4": ["#694755", "#6c4a56"], "5": ["#744c58", "#78555b"], "a": ["#a98981", "#b39488"],
        "b": ["#debba4", "#e3beaa", "#e8c6ac"], "c": ["#efd1b9", "#eeccb2", "#f6e0c8"],
        "y": ["#f3cb29", "#ecbb1f", "#f7c436", "#f9db36", "#d9af30"],
    }, weight={"y": 6, "c": 1.5, "b": 1.5}),
    # the Briar Hart story boss: the same concept stag on a 48 px cell (more of the concept survives)
    "stag_boss": dict(size=48, lua_dir="../boss_gen", band=(184, 311.9), scale=4.1 * 32 / 48, pal={
        "o": ["#15141e"] + OUT_ALIASES,
        "1": ["#221d2b", "#1c1926", "#2e2536"], "2": ["#423041", "#4c3546"], "3": ["#553b4b", "#5f4150"],
        "4": ["#694755", "#6c4a56"], "5": ["#744c58", "#78555b"], "a": ["#a98981", "#b39488"],
        "b": ["#debba4", "#e3beaa", "#e8c6ac"], "c": ["#efd1b9", "#eeccb2", "#f6e0c8"],
        "y": ["#f3cb29", "#ecbb1f", "#f7c436", "#f9db36", "#d9af30"],
    }, weight={"y": 6, "c": 1.5, "b": 1.5}),
    "spore_mushroom": dict(band=(500, 609.5), scale=3.45, pal={
        "o": ["#15141e"] + OUT_ALIASES,
        "1": ["#1c1825", "#1c1926"], "2": ["#221d2b", "#201c29"], "3": ["#322534", "#2f2636"],
        "r": ["#6e2e3c", "#7a3442"], "s": ["#964350"], "t": ["#aa4d59"], "u": ["#c0626a", "#b85a62"],
        "p": ["#b57c7a", "#a98981"], "q": ["#d1a392", "#deb39f"], "w": ["#e5c2ae", "#efd1b9"],
        "y": ["#f5af1a", "#f9bd16", "#f4b629", "#e9a027", "#f4b90a", "#ecb01f"],
    }, weight={"y": 6, "q": 1.3, "w": 1.5}),
    "raven": dict(band=(352, 452.5), scale=3.4, pal={
        "o": ["#15141e"] + OUT_ALIASES,
        "1": ["#201c29", "#1a1723"], "2": ["#2b2233", "#251f2d"], "3": ["#36293f", "#312738"],
        "4": ["#4a3d55"], "b": ["#573d23"], "c": ["#9d712f"],
        "y": ["#e9ae20", "#f3cb29", "#ecbb1f", "#d9af30"],
    }, weight={"y": 5, "c": 3, "b": 2, "4": 1.5}),
    "will_o_wisp": dict(band=(664, 739), scale=2.45, anchor_eyes=16.5, anchor_key="w",
        bg_extra=["#5a5969", "#5e6573", "#565566", "#5b5f6e"], pal={
        "o": ["#1f3a42"],
        "1": ["#54767f", "#4f6f78"], "2": ["#538c8f", "#4f8e90", "#569293"], "3": ["#59a29b", "#539996", "#5a9a97"],
        "4": ["#66ada2", "#699596"], "5": ["#afc5b9"], "w": ["#f5eddb"],
    }, weight={"w": 1.3, "1": 1.5}),
    "ghost_hunter": dict(band=(815, 910), scale=3.0, anchor_eyes=24.5, pal={
        "o": ["#15141e"] + OUT_ALIASES,
        "1": ["#1c1926", "#201c29", "#221d2a"], "2": ["#2f2636", "#2b2334"], "3": ["#3e3346", "#423747"],
        "c": ["#8e7475", "#86696d"], "d": ["#b29391", "#b19188"], "e": ["#c2a39e", "#ccaea1", "#bd9e9a"],
        "f": ["#d4b5aa", "#d7baaf", "#dabeb2", "#dbbfb4"],
        "y": ["#eaab0e", "#ecbb1f", "#f3cb29", "#f4b90a", "#dca91e"],
    }, weight={"y": 6, "f": 1.2}),
}


def hexrgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def convert(name, out_dir):
    global Z
    cfg = CHARS[name]
    Z = cfg.get("size", 32)
    src_path = os.path.join(HERE, "..", "concepts", cfg["src"]) if "src" in cfg else SRC
    src = np.asarray(Image.open(src_path).convert("RGB")).astype(float)
    top, ground = cfg["band"]
    top, ground = int(round(top)), ground
    S = cfg["scale"]
    keys, cols = [], []
    for k, hs in cfg["pal"].items():
        for h in hs:
            keys.append(k); cols.append(hexrgb(h))
    for h in cfg.get("bg", BG) + cfg.get("bg_extra", []):
        keys.append("."); cols.append(hexrgb(h))
    for h in cfg.get("shadow", SHADOW):
        keys.append(","); cols.append(hexrgb(h))
    cols = np.array(cols, float)
    gi = int(np.ceil(ground))
    band = src[top:gi]
    off = gi - ground          # extra source rows below the anchor
    d = ((band[:, :, None, :] - cols[None, None]) ** 2).sum(-1)
    lab = np.array(keys)[d.argmin(-1)]
    yy = np.arange(lab.shape[0])[:, None]
    near_ground = yy > (lab.shape[0] - 2.2 * S)
    lab = np.where((lab == ",") & near_ground, ".", lab)
    lab = np.where(lab == ",", "2" if "2" in cfg["pal"] else "o", lab)
    subj = lab != "."
    # pose columns: split on gaps in the subject mask (art area starts at x=240)
    AX = cfg.get("art_x", 240)
    colhit = subj[:, AX:].sum(0) > 3
    segs, ins = [], False
    for x, v in enumerate(colhit):
        if v and not ins: ins, x0 = True, x
        if not v and ins:
            ins = False; segs.append([x0 + AX, x + AX])
    if ins: segs.append([x0 + AX, len(colhit) + AX])
    merged = []
    for s in segs:
        if merged and s[0] - merged[-1][1] < 9: merged[-1][1] = s[1]
        else: merged.append(s)
    merged = [s for s in merged if s[1] - s[0] > 12]
    for x in cfg.get("split", []):          # poses whose effects touch the next pose
        merged = [p for s in merged for p in ([[s[0], x], [x, s[1]]] if s[0] < x < s[1] else [s])]
    print(name, "poses", len(merged), merged)
    weight = cfg.get("weight", {})
    pal = {k: hexrgb(v[0]) for k, v in cfg["pal"].items()}
    grids = []
    for n, (a, b) in enumerate(merged):
        cx = cfg.get("pose_cx", {}).get(n + 1, (a + b) / 2)   # optional per-pose centre / x-scale
        SY = cfg.get("pose_s", {}).get(n + 1, S)                # optional per-pose overall scale
        SX = cfg.get("pose_sx", {}).get(n + 1, SY)
        if cfg.get("anchor_eyes") is not None:      # put the eyes at a fixed column instead
            ys_, xs_ = np.where(lab[:, a:b] == cfg.get("anchor_key", "y"))
            if len(xs_):
                cx = a + xs_.mean() - (cfg["anchor_eyes"] - 15.5) * S
        rows = []
        for j in range(Z):
            row = ""
            sy1 = lab.shape[0] - off - (Z - 1 - j) * SY
            sy0 = sy1 - SY
            for i in range(Z):
                sx0 = cx + (i - Z // 2) * SX
                ys0, ys1 = int(round(max(0, sy0))), int(round(max(0, sy1)))
                xs0, xs1 = int(round(sx0)), int(round(sx0 + SX))
                blk = lab[ys0:ys1, max(0, xs0):max(0, xs1)].ravel()
                if blk.size == 0 or (blk != ".").sum() < 0.45 * blk.size:
                    row += "."; continue
                cnt = {}
                for k in blk:
                    if k != ".": cnt[k] = cnt.get(k, 0) + weight.get(k, 1)
                k = max(cnt, key=cnt.get)
                row += k
            rows.append(row)
        grids.append(rows)
    grids = [clean(g) for g in grids]
    sheet = Image.new("RGBA", (Z * len(grids), Z), (0, 0, 0, 0))
    for n, rows in enumerate(grids):
        for j, row in enumerate(rows):
            for i, k in enumerate(row):
                if k != ".": sheet.putpixel((Z * n + i, j), pal[k] + (255,))
    write_lua(name, cfg, grids)
    os.makedirs(out_dir, exist_ok=True)
    sheet.save(os.path.join(out_dir, name + "_poses.png"))
    with open(os.path.join(out_dir, name + "_poses.txt"), "w") as f:
        for n, rows in enumerate(grids):
            f.write("pose %d\n" % (n + 1))
            f.write("\n".join(rows) + "\n")
    big = sheet.resize((sheet.width * 6, sheet.height * 6), Image.NEAREST)
    bg = Image.new("RGBA", big.size, (74, 68, 80, 255)); bg.alpha_composite(big)
    bg.save(os.path.join(out_dir, name + "_poses_x6.png"))


DARK = set("o12")
Z = 32   # cell size of the character being converted


def comps(rows):
    """8-connected components of opaque pixels -> list of sets of (x, y)."""
    seen, out = set(), []
    for y in range(Z):
        for x in range(Z):
            if rows[y][x] != "." and (x, y) not in seen:
                st, c = [(x, y)], set()
                seen.add((x, y))
                while st:
                    cx, cy = st.pop(); c.add((cx, cy))
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            nx, ny = cx + dx, cy + dy
                            if 0 <= nx < Z and 0 <= ny < Z and (nx, ny) not in seen and rows[ny][nx] != ".":
                                seen.add((nx, ny)); st.append((nx, ny))
                out.append(c)
    return out


def clean(rows):
    g = [list(r) for r in rows]
    # 1. ground shadow: dark pixels on the bottom rows with nothing but dark/empty above them
    for y in (Z - 1, Z - 2):
        for x in range(Z):
            if g[y][x] in DARK:
                above = [g[y - 1][xx] for xx in (x - 1, x, x + 1) if 0 <= xx < Z]
                if all(k == "." or k in DARK for k in above) and g[y - 1][x] in ".o":
                    g[y][x] = "."
    # 2. dark specks not attached to the body (shadow remnants); light fx stay
    cs = comps(g)
    if cs:
        body = max(cs, key=len)
        for c in cs:
            if c is not body and all(g[y][x] in DARK for x, y in c):
                for x, y in c: g[y][x] = "."
        # 3. close outline gaps around the body
        add = []
        for x, y in body:
            if g[y][x] == "o": continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < Z and 0 <= ny < Z and g[ny][nx] == ".": add.append((nx, ny))
        for x, y in add: g[y][x] = "o"
    return ["".join(r) for r in g]


def write_lua(name, cfg, grids):
    path = os.path.join(HERE, cfg.get("lua_dir", "."), name + "_poses.lua")
    if os.path.exists(path) and "--force" not in sys.argv:   # never clobber hand fixes
        path = os.path.join(HERE, "drafts", name + "_poses.lua")
        print("kept hand-fixed", name + "_poses.lua; new draft in drafts/ (use --force to replace)")
    with open(path, "w") as f:
        f.write("-- %s: the concept poses (concepts/%s), downscaled by concept_convert.py\n" % (name, cfg.get("src", "enemies_concept_2.png")))
        f.write("-- and then fixed by hand. One char per pixel, '.' = transparent. Edit these, not the PNG.\n")
        f.write("return {\n  pal = {\n")
        for k, v in cfg["pal"].items():
            f.write('    ["%s"] = "%s",\n' % (k, v[0]))
        f.write("  },\n  poses = {\n")
        for n, rows in enumerate(grids):
            f.write("    { -- %d\n" % (n + 1))
            for r in rows:
                f.write('      "%s",\n' % r)
            f.write("    },\n")
        f.write("  },\n}\n")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--force"]
    convert(args[0], args[1] if len(args) > 1 else os.path.join(HERE, "drafts"))
