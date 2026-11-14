# Reads concepts/cat_woman_concept.png cell by cell (12.8 px cells, 38x48 art px)
# into a 48x48 grid on the reference's own palette. Writes cat_woman_base.txt,
# which is then hand-edited; re-running refuses to overwrite it without --force.
#   uv run --with pillow python -I enemy_gen/cat_woman_convert.py [--force]
from PIL import Image
import os, sys
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(HERE, 'concepts/cat_woman_concept.png')
OUT = os.path.join(HERE, 'cat_woman_base.txt')
P, X0, Y0, COLS, ROWS = 12.8, 230, 88, 38, 48
W = H = 48
OX = (W - COLS) // 2
PAL = {
    '.': '#ffffff',
    'O': '#030112', 'a': '#1c1a24', 'b': '#272f35', 'c': '#2e363c', 'd': '#414d4d',
    's': '#f1c89f', 'S': '#d38b6f', 'p': '#ed846e', 'm': '#441a1d',
    'w': '#5d4644', 'W': '#3e3136', 'l': '#9f766f', 'h': '#8d9991',
}
def rgb(h): return tuple(int(h[i:i+2], 16) for i in (1, 3, 5))
PR = {k: rgb(v) for k, v in PAL.items()}
if os.path.exists(OUT) and '--force' not in sys.argv:
    sys.exit(f'{OUT} exists (hand-edited?); pass --force to overwrite')
im = Image.open(SRC).convert('RGB'); px = im.load()
rows = []
for r in range(ROWS):
    line = ['.'] * W
    for c in range(COLS):
        cx, cy = X0 + P * (c + 0.5), Y0 + P * (r + 0.5)
        vals = [px[int(cx + dx), int(cy + dy)] for dy in range(-3, 4) for dx in range(-3, 4)]
        m = tuple(sorted(v[i] for v in vals)[len(vals) // 2] for i in range(3))
        line[OX + c] = min(PR, key=lambda k: sum((a - b) ** 2 for a, b in zip(PR[k], m)))
    rows.append(''.join(line))
with open(OUT, 'w') as f:
    for k, v in PAL.items():
        if k != '.':
            f.write(f'# {k} {v}\n')
    f.write('\n'.join(rows) + '\n')
print('\n'.join(rows))
