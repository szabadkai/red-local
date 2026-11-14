// The Huntsman's Bridge scenery, built from the concept pieces (bridge-atlas-v1: chapel tower, red oak,
// arch span, crypt; bridge-bough-v1: mossy log) at one shared scale, seated on the collision surfaces,
// and reduced once onto the game's 2-world-unit pixel grid (half-resolution cache, hard alpha) so it
// matches the sprites. Banks and ruined ledges use procedural masonry in the concept's stone palette.
// Lamps, banners and the falls animate on top (bridge.mjs). The helpers here are shared with arena-art.mjs.
export const P = {
  mortar: '#1a1616', stone: ['#2c2828', '#433b3a', '#5a4f4c', '#6f625a', '#8a7c6e'],
  moss: ['#3a3f1e', '#5a6226', '#7e8832', '#a8b04a'], bark: ['#22161a', '#3c2827', '#5a3a31', '#7b5340', '#99704f'],
  ivy: ['#4e1220', '#8e1e2c', '#c8352f', '#e2584a'], warm: ['#7a3c18', '#d0782c', '#f3b052', '#ffe2a1'],
  red: ['#4a1621', '#7a2230', '#a83a3a'], cream: '#d9b98a', wood: ['#3a2620', '#5e3e2c', '#83603f']
};
const H = 280;              // cache height in pixels (560 world units)
export const hash = n => { const s = Math.sin(n * 127.1 + 311.7) * 43758.5453; return s - Math.floor(s); };

export function painter(c) {
  const R = (x, y, w, h, col) => { c.fillStyle = col; c.fillRect(Math.round(x), Math.round(y), Math.max(1, Math.round(w)), Math.max(1, Math.round(h))); };
  const D = (x, y, col) => R(x, y, 1, 1, col);
  return { R, D };
}

// Staggered stone blocks: mortar, per-block tone, lit top/right edge, dark bottom, the odd missing block.
export function masonry(c, x0, y0, w, h, seed = 0) {
  const { R } = painter(c);
  c.save(); c.beginPath(); c.rect(x0, y0, w, h); c.clip();
  R(x0, y0, w, h, P.mortar);
  for (let row = 0, y = y0; y < y0 + h; row++, y += 7) {
    let x = x0 - (row % 2 ? 7 : 0) - Math.floor(hash(seed + row) * 5);
    for (let k = 0; x < x0 + w; k++) {
      const n = hash(seed * 31 + row * 17 + k * 7), bw = 9 + Math.floor(n * 7);
      if (n > .955) { R(x + 1, y + 1, bw - 1, 5, '#1f242b'); x += bw; continue; }
      const t = n < .3 ? 1 : n < .8 ? 2 : 3;
      R(x, y, bw - 1, 6, P.stone[t]);
      R(x, y, bw - 1, 1, P.stone[t + 1]); R(x + bw - 2, y + 1, 1, 4, P.stone[t + 1]);
      R(x, y + 5, bw - 1, 1, P.stone[t - 1]);
      if (n > .62 && n < .66) R(x + 3, y + 2, 2, 1, P.stone[t - 1]);
      x += bw;
    }
  }
  c.restore();
}
// Moss lip along a walkable edge, with drips and grass tufts.
export function mossTop(c, x0, y, w, seed = 0) {
  const { R, D } = painter(c);
  R(x0, y, w, 1, P.moss[3]); R(x0, y + 1, w, 2, P.moss[2]);
  for (let x = x0; x < x0 + w; x++) {
    const n = hash(seed + x * 3.1);
    if (n > .55) R(x, y + 3, 1, 1 + Math.floor(n * 4), n > .8 ? P.moss[1] : P.moss[0]);
    if (n < .12) { D(x, y - 1, P.moss[3]); if (n < .05) D(x, y - 2, P.moss[2]); }
  }
}
// Hanging red ivy: a thin stem with alternating leaves.
export function ivy(c, x, y, len, seed = 0) {
  const { R, D } = painter(c);
  for (let i = 0; i < len; i++) {
    const dx = Math.round(Math.sin(i * .35 + seed) * 1.5);
    D(x + dx, y + i, P.bark[1]);
    if (i % 3 === 1) {
      const s = (i / 3) % 2 ? 1 : -2, lx = x + dx + s;
      R(lx, y + i, 2, 2, P.ivy[1]); D(lx + (s > 0 ? 1 : 0), y + i, P.ivy[2]);
      if (hash(seed + i) > .6) D(lx + (s > 0 ? 2 : -1), y + i + 1, P.ivy[0]);
    }
  }
  R(x - 1, y + len, 3, 2, P.ivy[2]); D(x, y + len, P.ivy[3]);
}
// A cluster of leaves (canopy / ivy mats).
export function leaves(c, cx, cy, r, ramp, seed = 0) {
  const { D } = painter(c);
  for (let y = -r; y <= r; y++) for (let x = -r; x <= r; x++) {
    const d = (x * x + y * y) / (r * r), n = hash(seed + x * 13.3 + y * 7.7);
    if (d > 1 || (d > .55 && n > .6)) continue;
    const lit = (x - y) / (2 * r) + (n - .5) * .5;
    D(cx + x, cy + y, lit > .35 ? ramp[3] : lit > 0 ? ramp[2] : lit > -.35 ? ramp[1] : ramp[0]);
  }
}
export function mushroom(c, x, y) {
  const { R, D } = painter(c);
  R(x, y - 3, 1, 3, P.cream); R(x - 2, y - 5, 5, 2, P.ivy[2]); D(x - 1, y - 5, P.ivy[3]); D(x + 1, y - 4, P.cream);
}

// Gnarled oak trunk rising off the top of the frame, flaring into roots at the base.
// Mossy bough carrying a ledge, joined to its trunk by a limb.

// Stone arch bridge: balustrade, deck, spandrel wall with two round arches open to the falls.
// Ruined gothic chapel wall with a lit lancet window.
// Crypt doorway cut into the far bank, lit by candles.

// Concept pieces (bridge-atlas-v1 / bridge-bough-v1), always at one scale so the masonry reads as one
// building: S world units per atlas pixel (the bough uses its own scale, it has no stones).
const S = .55, SB = .3;
const PIECES = { tower: [24, 30, 550, 590, 575], oak: [620, 20, 640, 600, 583], arch: [14, 710, 600, 450, 82], shrine: [640, 740, 610, 410, 396] };
function piece(c, img, name, x, y, flip = false) {
  const [sx, sy, sw, sh] = PIECES[name], w = sw * S / 2, h = sh * S / 2;
  c.save(); c.imageSmoothingEnabled = true; c.imageSmoothingQuality = 'high';
  if (flip) { c.translate(Math.round(x / 2 + w), 0); c.scale(-1, 1); c.drawImage(img, sx, sy, sw, sh, 0, Math.round(y / 2), w, h); }
  else c.drawImage(img, sx, sy, sw, sh, Math.round(x / 2), Math.round(y / 2), w, h);
  c.restore();
}
// placed so its ground line (or the bridge deck) lands on world y
const seat = (name, y) => y - PIECES[name][4] * S;
// Mossy bough cut from the long concept log at its own scale: ivy tip at each end, mossy middle.
function boughPiece(c, img, x, y, w, seed) {
  const tip = 180, mid0 = 260 + Math.floor(hash(seed) * 600), sy = 250, sh = 320;
  const tw = tip * SB / 2, h = sh * SB / 2, X = Math.round(x / 2), Y = Math.round((y - 10 * SB) / 2), W = Math.round(w / 2);
  c.save(); c.imageSmoothingEnabled = true; c.imageSmoothingQuality = 'high';
  c.drawImage(img, mid0, sy, (W - 2 * tw) * 2 / SB, sh, X + tw, Y, W - 2 * tw, h);
  c.drawImage(img, 14, sy, tip, sh, X, Y, tw, h);
  c.translate(X + W, 0); c.scale(-1, 1); c.drawImage(img, 14, sy, tip, sh, 0, Y, tw, h);
  c.restore();
}
// Hard alpha and a light posterise so the painted pieces sit on the same pixel grid as the sprites.
function crisp(c) {
  const d = c.getImageData(0, 0, c.canvas.width, c.canvas.height), p = d.data;
  for (let i = 0; i < p.length; i += 4) {
    if (p[i + 3] < 140) { p[i + 3] = 0; continue; }
    p[i + 3] = 255; for (let k = 0; k < 3; k++) p[i + k] = Math.min(255, Math.round(p[i + k] / 6) * 6);
  }
  c.putImageData(d, 0, 0);
}

const OAKS = [[915, false], [1715, true], [2360, false], [3375, false], [4055, true], [4770, false]];
const cache = new WeakMap();
function render(platforms, images) {
  const canvas = document.createElement('canvas');
  canvas.width = Math.max(...platforms.map(p => p.x + p.w)) / 2; canvas.height = H;
  const c = canvas.getContext('2d');
  const atlas = images.get('concept-bridge-atlas-v1'), log = images.get('concept-bridge-bough-v1');
  const px = p => ({ x: Math.round(p.x / 2), y: Math.round(p.y / 2), w: Math.round(p.w / 2) });
  if (atlas) {
    for (const [x, flip] of OAKS) piece(c, atlas, 'oak', flip ? x - 352 + 253 : x - 253, seat('oak', 420), flip);
    piece(c, atlas, 'tower', -40, seat('tower', 420));
    piece(c, atlas, 'shrine', 4375, seat('shrine', 420));
  }
  for (const p of platforms) {
    const q = px(p);
    if (p.ground) {
      masonry(c, q.x, q.y, q.w, H - q.y, p.id * 13);
      mossTop(c, q.x, q.y, q.w, p.id);
      for (let x = q.x + 20; x < q.x + q.w - 10; x += 37 + Math.floor(hash(x) * 25)) ivy(c, x, q.y + 3, 8 + Math.floor(hash(x * 2) * 16), x);
    } else if (p.kind === 'lower') { masonry(c, q.x, q.y, q.w, 14, 91); mossTop(c, q.x, q.y, q.w, 92); }
    else if (p.kind === 'bridge' || p.kind === 'branch' || p.kind === 'root') continue;
    else {
      const pierX = q.x + Math.max(0, q.w - 30);
      masonry(c, pierX, q.y + 5, 20, 215 - q.y, p.id * 5);
      masonry(c, q.x, q.y, q.w, 6, p.id * 9); mossTop(c, q.x, q.y, q.w, p.id * 3);
      painter(c).R(q.x, q.y + 6, q.w, 1, P.stone[0]);
      ivy(c, q.x + 6, q.y + 6, 10 + (p.id % 3) * 5, p.id);
    }
  }
  for (const p of platforms) {
    if (p.kind === 'bridge' && atlas) {
      const n = Math.max(1, Math.round(p.w / (PIECES.arch[2] * S)));
      for (let i = 0; i < n; i++) piece(c, atlas, 'arch', p.x + i * p.w / n, seat('arch', p.y));
    } else if ((p.kind === 'branch' || p.kind === 'root') && log) {
      // boughs near an oak grow out of its trunk instead of floating beside it
      let x0 = p.x, x1 = p.x + p.w;
      for (const [t] of OAKS) { if (t > x1 && t - x1 < 260) x1 = t - 30; if (t < x0 && x0 - t < 260) x0 = t + 30; }
      boughPiece(c, log, x0, p.y, x1 - x0, p.id * 7);
    }
  }
  crisp(c);
  return canvas;
}

export function drawBridgePixels(c, platforms, images) {
  let art = cache.get(platforms);
  if (!art) { art = render(platforms, images); cache.set(platforms, art); }
  c.save(); c.imageSmoothingEnabled = false; c.drawImage(art, 0, 0, art.width * 2, H * 2); c.restore();
}
