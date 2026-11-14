#!/usr/bin/env python3
"""Builds animation_demo.html: every LRRH character's six animations, playing live.

The page is self-contained (sheets are embedded as base64), so it opens anywhere.
Re-run after re-exporting any sheet:  python3 lrrh_sprites/build_demo.py
"""
import base64
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))

CAST = [
    ("little_red_riding_hood", "Little Red Riding Hood"),
    ("mother", "Mother"),
    ("grandmother", "Grandmother"),
    ("woodcutter", "Woodcutter"),
    ("wolf_in_disguise", "Wolf in Disguise"),
]
ENEMIES = [
    ("big_bad_wolf", "Big Bad Wolf"),
    ("rogue_hunter", "Rogue Hunter"),
    ("forest_witch", "Forest Witch"),
    ("wild_boar", "Wild Boar"),
    ("forest_crow", "Forest Crow"),
    ("living_tree", "Living Tree"),
    ("thorn_brambles", "Thorn Brambles"),
    ("lost_wisp", "Lost Wisp"),
    ("brown_bear", "Brown Bear"),
    ("forest_stag", "Forest Stag"),
    ("spore_mushroom", "Spore Mushroom"),
    ("ghost_hunter", "Ghost Hunter"),
    ("raven", "Raven"),
    ("will_o_wisp", "Will-o'-Wisp"),
]
# Kept at full size in the game set even though a _small version may exist (see shrink/all.lua).
ORIGINAL = {"wild_boar", "big_bad_wolf"}


def load(base):
    png, js = os.path.join(HERE, base + "_sheet.png"), os.path.join(HERE, base + "_sheet.json")
    if not os.path.exists(png):
        return None
    data = json.load(open(js))
    frames = data["frames"]
    if isinstance(frames, dict):
        frames = list(frames.values())
    tags = [
        {"name": t["name"], "from": t["from"], "to": t["to"]}
        for t in data["meta"]["frameTags"]
    ]
    return {
        "src": "data:image/png;base64," + base64.b64encode(open(png, "rb").read()).decode(),
        "frames": [[f["frame"]["x"], f["frame"]["y"], f["duration"]] for f in frames],
        "tags": tags,
    }


def entry(name, title, group):
    orig = load(name)
    small = load(name + "_small")
    return {
        "id": name,
        "title": title,
        "group": group,
        "original": orig,
        "small": small,
        "gameUsesOriginal": name in ORIGINAL or small is None,
    }


chars = [entry(n, t, "cast") for n, t in CAST] + [entry(n, t, "enemy") for n, t in ENEMIES]
template = open(os.path.join(HERE, "demo_template.html")).read()
out = template.replace("/*__DATA__*/null", json.dumps(chars, separators=(",", ":")))
dst = os.path.join(HERE, "animation_demo.html")
open(dst, "w").write(out)
print(f"wrote {dst} ({len(out) // 1024} KB, {len(chars)} characters)")
