// Boss-arena sets and boss hazards as native pixel art (1 pixel = 2 world units), matching the
// Huntsman's Bridge scenery. Static set pieces are rendered once per stage into a 480x270 canvas;
// wheels, bells, flames and lanterns animate on top. Coordinates are set pixels (world / 2),
// floor at y = 210. Stages: 0 Briar Hart, 1 Tollkeeper's mill, 2 Rowan's camp, 3 Bell Widow, 4 cottage.
import { P, hash, painter, masonry, mossTop, ivy, leaves, mushroom } from './bridge-art.mjs';
import { drawProp } from './concept-props.mjs';

const W = 480, H = 270, FLOOR = 210;
const FIRE = ['#8a2a1a', '#d0562a', '#f39a3a', '#ffd76a', '#fff3c4'];
const WOOD = ['#2a1c18', '#4a3226', '#6b4a34', '#8f6a48', '#b08a5c'];
const IRON = ['#15141e', '#2c2f3a', '#4d4b5a', '#7a7688', '#a9a5b8'];
const GOLD = ['#5a3e1c', '#8a6430', '#bc9560', '#e6c48a', '#fff0c4'];
const SILK = ['#8f8494', '#b8adb5', '#d8cfd2', '#efe8e8'];
const BRIAR = ['#1c1a14', '#2e3322', '#46502f', '#5f6e3a'];

// Plank run (walls, floors, doors): boards with grain, knots and dark seams.
function planks(c, x0, y0, w, h, vertical, ramp, seed) {
  const { R, D } = painter(c);
  R(x0, y0, w, h, ramp[0]);
  const span = vertical ? w : h, bw = 8;
  for (let i = 0, o = 0; o < span; i++, o += bw) {
    const n = hash(seed + i * 7.3), tone = n < .3 ? 1 : n < .8 ? 2 : 3;
    if (vertical) {
      R(x0 + o + 1, y0, bw - 1, h, ramp[tone]); R(x0 + o + bw - 1, y0, 1, h, ramp[tone - 1]);
      for (let y = y0; y < y0 + h; y += 5 + Math.floor(hash(seed + i + y) * 9)) R(x0 + o + 2 + Math.floor(hash(y + i) * 4), y, 1, 3, ramp[tone - 1]);
      if (n > .7) { const ky = y0 + Math.floor(hash(seed * 3 + i) * (h - 4)); R(x0 + o + 3, ky, 2, 2, ramp[0]); D(x0 + o + 3, ky, ramp[tone + 1]); }
    } else {
      R(x0, y0 + o + 1, w, bw - 1, ramp[tone]); R(x0, y0 + o + 1, w, 1, ramp[tone + 1]); R(x0, y0 + o + bw - 1, w, 1, ramp[tone - 1]);
      for (let x = x0 + Math.floor(hash(seed + i) * 20); x < x0 + w; x += 24 + Math.floor(hash(x + i) * 18)) R(x, y0 + o + 1, 1, bw - 2, ramp[0]);
    }
  }
}
function stoneBlock(c, x, y, w, h, seed) { masonry(c, x, y, w, h, seed); const { R } = painter(c); R(x, y, w, 1, P.stone[4]); }

// --- stage sets --------------------------------------------------------------------------------
function hartSet() {
  // briar thickets come from the painted props
}
function millSet(c) {
  const { R, D } = painter(c);
  // the painted toll tower (props) stands where the hut was
  // stone pier carrying the wheel axle, and the mill race below it
  stoneBlock(c, 374, 134, 22, 76, 77);
  R(320, 196, 130, 14, '#1d3a44'); for (let x = 320; x < 450; x += 3) D(x, 197 + Math.floor(hash(x) * 3), '#5d93a0');
}
// One log lying end-on: its bark body recedes up and to the right behind the cut face, so the
// pile reads as cylinders. Cut face: wobbly growth rings round an off-centre pith, a radial crack,
// lit from the upper left (the camp fire); bark: dark rim with ragged notches.
const BARK = ['#170f0d', '#2e201a', '#45302a', '#5d4232'];
const HEART = ['#6e4a32', '#8f6a48', '#b08a5c', '#c9a46e', '#dfc08a'];
function logEnd(c, cx, cy, r, seed, moss) {
  const { D } = painter(c);
  for (let k = 4; k >= 1; k--) for (let yy = -r - 1; yy <= r + 1; yy++) for (let xx = -r - 1; xx <= r + 1; xx++) {
    const d = Math.hypot(xx, yy);
    if (d > r + .4) continue;
    const top = yy < -r * .45, edge = d > r - .9;
    D(cx + xx + k, cy + yy - Math.round(k * .6), edge ? BARK[0] : top ? (hash(seed + xx * 3 + k) < .3 ? BARK[3] : BARK[2]) : BARK[1]);
  }
  if (moss) for (let xx = -r + 2; xx <= r; xx++) if (hash(seed * 5 + xx) < .55) {
    const y = cy - Math.round(Math.sqrt(Math.max(0, r * r - xx * xx))) - 2;
    D(cx + xx + 2, y, '#5a6226'); if (hash(seed + xx) < .4) D(cx + xx + 2, y - 1, '#7e8832');
  }
  const px = cx + Math.round((hash(seed) - .5) * r * .5), py = cy + Math.round((hash(seed + 1) - .5) * r * .5);
  const crack = hash(seed + 2) * Math.PI * 2;
  for (let yy = -r; yy <= r; yy++) for (let xx = -r; xx <= r; xx++) {
    const d = Math.hypot(xx, yy);
    if (d > r + .4) continue;
    if (d > r - 1.1) { D(cx + xx, cy + yy, hash(seed + xx * 7 + yy) < .25 ? BARK[2] : BARK[0]); continue; }
    const rd = Math.hypot(cx + xx - px, cy + yy - py) + (hash(seed + Math.round(Math.atan2(yy, xx) * 3)) - .5) * .8;
    const lit = (xx + yy) / r;   // negative towards the fire (upper left)
    let tone = rd < 1.2 ? 1 : 4 - Math.min(2, Math.floor(rd / (r * .45)));
    if (lit > .55) tone = Math.max(0, tone - 1); else if (lit < -.6 && tone < 4) tone++;
    let col = HEART[tone];
    if (rd > 1.5 && Math.round(rd) % 2 === 0 && Math.abs(rd - Math.round(rd)) < .35) col = HEART[Math.max(0, tone - 3)];
    const a = Math.atan2(cy + yy - py, cx + xx - px);
    if (rd > 1 && Math.abs(Math.sin(a - crack)) < .12 && Math.cos(a - crack) > 0) col = BARK[1];
    D(cx + xx, cy + yy, col);
  }
}
function campSet(c) {
  const { R, D } = painter(c);
  // woodpile: a 4-3-2 stack of cut logs, back row first, on its own shadow
  R(380, 209, 64, 1, '#0d0a0b'); R(384, 208, 56, 1, '#0d0a0b');
  const logs = [
    [399, 181, 6, 1], [413, 180, 6.5, 2],
    [392, 192, 6.5, 3], [406, 191, 7, 4], [421, 192, 6.5, 5],
    [386, 202, 6.5, 6], [400, 202, 7, 7], [415, 202, 6.5, 8], [429, 203, 6, 9],
  ];
  for (const [x, y, r, s] of logs) logEnd(c, x, y, r, s * 13.7, y < 186);
  // low chopping stump (flared roots, ringed top) with the axe sunk in it at an angle
  R(354, 201, 18, 8, BARK[1]); R(354, 201, 1, 8, BARK[0]); R(371, 201, 1, 8, BARK[0]); R(358, 202, 1, 7, BARK[2]); R(365, 203, 1, 6, BARK[2]);
  R(351, 207, 3, 2, BARK[1]); R(372, 206, 3, 3, BARK[1]); R(351, 209, 25, 1, BARK[0]);
  R(353, 198, 20, 4, HEART[3]); R(354, 198, 18, 1, HEART[4]); R(353, 201, 20, 1, BARK[0]); R(353, 198, 1, 3, BARK[0]); R(372, 198, 1, 3, BARK[0]);
  R(358, 199, 9, 1, HEART[1]); D(362, 200, HEART[0]);
  for (let i = 0; i < 17; i++) { const x = 368 + Math.round(i * .45), y = 199 - i; D(x, y, WOOD[3]); D(x + 1, y, WOOD[1]); if (i > 14) D(x - 1, y, WOOD[1]); }
  R(363, 195, 7, 4, IRON[2]); R(363, 195, 7, 1, IRON[4]); R(362, 196, 1, 2, IRON[3]); R(363, 198, 7, 1, IRON[1]);
  // chips and a split-off wedge on the floor
  for (const [x, w, col] of [[346, 2, HEART[3]], [375, 3, HEART[2]], [380, 2, HEART[4]], [341, 3, HEART[1]], [438, 2, HEART[3]]]) { R(x, 208, w, 1, col); D(x, 209, BARK[0]); }
  R(444, 205, 6, 4, HEART[3]); R(444, 205, 6, 1, HEART[4]); R(449, 205, 1, 4, BARK[1]); R(444, 209, 6, 1, BARK[0]);
  // fire ring stones
  for (let i = 0; i < 7; i++) { const x = 113 + i * 4; R(x, 205 - (i % 2), 4, 4 - (i % 2), P.stone[2 + (i % 2)]); R(x, 205 - (i % 2), 4, 1, P.stone[4]); }
}
function chapelSet(c) {
  // painted pillars, ivy arch and candle shrines are drawn per frame (props)
}
function cottageSet(c) {
  const { R, D } = painter(c);
  planks(c, 4, 42, 472, 161, true, ['#1e1a1a', '#2c2624', '#383030', '#453a36', '#54473f'], 21);
  R(4, 42, 472, 8, WOOD[1]); R(4, 42, 472, 1, WOOD[3]); R(4, 50, 472, 1, WOOD[0]);
  for (const x of [16, 456]) { R(x, 41, 9, 169, WOOD[2]); R(x, 41, 2, 169, WOOD[3]); R(x + 7, 41, 2, 169, WOOD[1]); }
  // chimney breast and stone hearth; the mantel is the left ledge (x 48-142, top 180)
  stoneBlock(c, 70, 118, 50, 62, 7);
  stoneBlock(c, 48, 180, 94, 6, 9); R(48, 180, 94, 1, P.stone[4]); R(50, 186, 90, 1, P.stone[0]);
  stoneBlock(c, 60, 187, 12, 23, 13); stoneBlock(c, 118, 187, 12, 23, 15);
  R(72, 187, 46, 23, '#170f0c'); R(76, 191, 38, 17, '#2a1810'); R(60, 207, 70, 3, P.stone[2]); R(82, 203, 26, 3, WOOD[1]);
  // shelf with jars and hanging herbs
  R(176, 118, 46, 3, WOOD[3]); R(176, 121, 46, 1, WOOD[0]); R(180, 122, 2, 6, WOOD[1]); R(216, 122, 2, 6, WOOD[1]);
  for (const [x, h, col] of [[180, 8, '#5d7f8a'], [189, 6, '#8a5a3a'], [197, 9, '#6b7d30'], [207, 7, '#9a4b3f']]) { R(x, 118 - h, 6, h, col); R(x + 1, 118 - h + 1, 1, h - 2, '#e6dccb'); R(x + 1, 118 - h - 1, 4, 1, WOOD[2]); }
  for (let i = 0; i < 4; i++) { const x = 262 + i * 9, len = 6 + i % 2 * 3; R(x, 51, 1, len, WOOD[3]); R(x - 1, 51 + len, 3, 2, '#7a5340'); for (let j = 0; j < 7; j++) D(x - 2 + (j % 5), 53 + len + Math.floor(j / 2), ['#46582a', '#6b7d34', '#8a9a3c'][j % 3]); }
  // window with sill, cross bars and curtains
  R(350, 86, 53, 57, WOOD[0]); R(354, 90, 45, 49, '#3d5670'); R(356, 92, 20, 22, '#58738c'); R(378, 116, 19, 21, '#4b6680');
  D(360, 95, '#e9eef0'); D(388, 100, '#e9eef0'); D(370, 120, '#c9d6de');
  R(375, 90, 3, 49, WOOD[2]); R(354, 113, 45, 3, WOOD[2]); R(346, 141, 61, 4, WOOD[3]); R(346, 145, 61, 1, WOOD[0]);
  for (const [x0, x1] of [[354, 366], [387, 399]]) for (let y = 88; y < 140; y++) { const w = x1 - x0 - Math.floor((y - 88) / 6) % 2; R(x0 + (x0 > 370 ? x1 - x0 - w : 0), y, w, 1, y % 4 ? '#685169' : '#55405e'); }
  R(350, 86, 53, 2, WOOD[3]);
  // braided rug on the floor
  for (let y = 204; y < 210; y++) R(180, y, 120, 1, y % 2 ? '#7a2230' : '#a83a3a');
  for (let x = 180; x < 300; x += 6) D(x, 206, P.cream);
  // table (loaf and basket) and the bed on the right ledge (x 340-430, top 180)
  R(218, 188, 44, 5, WOOD[3]); R(218, 188, 44, 1, WOOD[4]); R(220, 193, 4, 17, WOOD[1]); R(256, 193, 4, 17, WOOD[1]);
  R(232, 182, 14, 6, GOLD[2]); R(233, 181, 12, 1, GOLD[3]); R(236, 184, 6, 1, GOLD[1]);
  R(334, 156, 10, 3, GOLD[2]); R(336, 159, 6, 51, WOOD[2]); R(336, 159, 2, 51, WOOD[3]);
  R(426, 168, 10, 3, GOLD[2]); R(428, 171, 6, 39, WOOD[2]); R(428, 171, 2, 39, WOOD[3]);
  R(340, 186, 88, 10, WOOD[1]); R(340, 186, 88, 1, WOOD[2]); R(342, 196, 4, 14, WOOD[1]); R(422, 196, 4, 14, WOOD[1]);
  R(340, 180, 88, 6, '#d3ceae'); R(340, 185, 88, 1, '#a99f88'); R(343, 174, 18, 6, '#e7d9af'); R(344, 174, 16, 1, '#f5ecd2');
  R(362, 178, 66, 10, '#9e4051'); R(362, 178, 66, 2, '#d77869'); for (let x = 366; x < 426; x += 12) R(x, 182, 4, 3, GOLD[2]);
}
const SETS = [hartSet, millSet, campSet, chapelSet, cottageSet];
const cache = new Map();
function setCanvas(stage) {
  if (cache.has(stage)) return cache.get(stage);
  const cv = document.createElement('canvas'); cv.width = W; cv.height = H;
  SETS[stage]?.(cv.getContext('2d')); cache.set(stage, cv); return cv;
}

// --- animated pieces (drawn on a context already scaled 2x) -------------------------------------
function lantern(c, x, y, time, reduced) {
  const { R } = painter(c);
  R(x - 1, y - 20, 2, 8, IRON[2]); R(x - 5, y - 13, 10, 2, IRON[3]);
  R(x - 4, y - 11, 8, 11, IRON[1]); const f = reduced ? 0 : Math.floor(time * 5) % 3;
  R(x - 3, y - 10, 6, 9, GOLD[2]); R(x - 2, y - 9, 4, 7, f ? GOLD[3] : GOLD[4]); R(x - 1, y - 7 - f, 2, 3, GOLD[4]);
  R(x - 5, y, 10, 2, IRON[3]); R(x - 1, y - 11, 2, 11, IRON[1]);
}
function flame(c, x, y, time, reduced, size = 1) {
  const { R } = painter(c);
  const f = reduced ? 0 : Math.floor(time * 8) % 3, h = Math.round((10 + f * 2) * size);
  for (let i = 0; i < h; i++) { const w = Math.max(1, Math.round((h - i) / h * 7 * size)), sway = Math.round(Math.sin(time * 9 + i * .5) * (i / h) * 1.5);
    R(x - w + sway, y - i, w * 2, 1, i < h * .3 ? FIRE[1] : i < h * .6 ? FIRE[2] : FIRE[3]); R(x - w + sway, y - i, 1, 1, FIRE[0]); }
  R(x - 1, y - Math.round(h * .45), 2, Math.round(h * .3), FIRE[4]);
}
function wheel(c, cx, cy, time, reduced) {
  const { R, D } = painter(c);
  const a0 = reduced ? 0 : time * .16, rad = 64, MOSS = ['#3a3f1e', '#5a6226', '#7e8832'];
  const at = (t, r, w) => [cx + Math.cos(t) * r - Math.sin(t) * w, cy + Math.sin(t) * r + Math.cos(t) * w];
  // spokes first (behind the rim): three-pixel timbers with a lit and a shaded edge
  for (let i = 0; i < 8; i++) {
    const t = a0 + i * Math.PI / 4 + Math.PI / 16;
    for (let r = 9; r < rad - 6; r++) for (let w = -2; w <= 2; w++) { const [x, y] = at(t, r, w); D(x, y, w === -2 || w === 2 ? WOOD[0] : w === -1 ? WOOD[3] : w === 1 ? WOOD[1] : WOOD[2]); }
  }
  // rim: plank segments, lit along the top, iron band with rivets down the middle
  for (let k = 0; k < 720; k++) {
    const t = k * Math.PI / 360, seg = Math.floor(((t - a0) % (Math.PI * 2) + Math.PI * 2) / (Math.PI / 9)) % 2, lit = Math.sin(t) < -.35 ? 1 : Math.sin(t) > .45 ? -1 : 0;
    for (let d = 0; d < 9; d++) {
      const x = cx + Math.cos(t) * (rad - d), y = cy + Math.sin(t) * (rad - d);
      if (d === 0 || d === 8) D(x, y, WOOD[0]);
      else if (d === 4) D(x, y, IRON[2]);
      else D(x, y, WOOD[Math.max(1, Math.min(4, 2 + seg + lit + (d < 3 ? 1 : 0)))]);
    }
  }
  for (let i = 0; i < 16; i++) { const t = a0 + i * Math.PI / 8; D(cx + Math.cos(t) * (rad - 4), cy + Math.sin(t) * (rad - 4), IRON[4]); }
  // boxy paddles: front face, shaded side and an outline, moss on the wet lower ones
  for (let i = 0; i < 16; i++) {
    const t = a0 + i * Math.PI / 8;
    for (let r = rad - 1; r < rad + 10; r++) for (let w = -3; w <= 3; w++) {
      const [x, y] = at(t, r, w), edge = r === rad + 9 || w === -3 || w === 3;
      D(x, y, edge ? WOOD[0] : w < -1 ? WOOD[4] : w > 1 ? WOOD[1] : r > rad + 6 ? WOOD[2] : WOOD[3]);
    }
    if (Math.sin(t) > .5) { const [x, y] = at(t, rad + 8, 0); D(x, y, MOSS[1]); D(x + 1, y, MOSS[2]); }
  }
  // iron hub with rivets
  for (let y = -9; y <= 9; y++) for (let x = -9; x <= 9; x++) { const d = x * x + y * y; if (d <= 81) D(cx + x, cy + y, d > 64 ? IRON[0] : d > 42 ? IRON[1] : x + y < -4 ? IRON[4] : IRON[3]); }
  for (let i = 0; i < 6; i++) { const t = a0 + i * Math.PI / 3; D(cx + Math.cos(t) * 6, cy + Math.sin(t) * 6, IRON[0]); }
  R(cx - 2, cy - 2, 4, 4, IRON[2]);
  // water pouring off the paddles into the race: unbroken strands with drifting gaps
  const f = reduced ? 0 : time * 60;
  for (let i = 0; i < 8; i++) {
    const x = cx + 32 + i * 3, y0 = cy + 22 + (i % 3) * 3;
    for (let y = y0; y < 200; y++) if ((y + f + i * 7) % 17 > 2) R(x, y, 2, 1, (y + i * 5) % 9 < 3 ? '#cfe8ea' : '#93c2c8');
  }
  for (let x = cx + 28; x < cx + 60; x += 2) R(x, 196 + Math.round(Math.sin(x + f * .2)), 2, 2, '#e3f1f0');
}
function hangingChain(c, x0, x1, y, sag) {
  const { R, D } = painter(c);
  for (let x = x0, k = 0; x <= x1; x += 4, k++) {
    const t = (x - x0) / (x1 - x0), yy = Math.round(y + sag * 4 * t * (1 - t));
    if (k % 2) { R(x - 1, yy, 5, 2, IRON[2]); R(x, yy, 3, 1, IRON[3]); }
    else { R(x, yy - 2, 4, 5, IRON[1]); R(x + 1, yy - 1, 2, 3, IRON[0]); D(x, yy - 2, IRON[4]); D(x + 3, yy + 2, IRON[0]); }
  }
}
function bell(c, x, y, time, ringing) {
  const { R, D } = painter(c);
  R(x - 14, y - 32, 28, 4, WOOD[2]); R(x - 14, y - 32, 28, 1, WOOD[3]); R(x - 1, y - 60, 2, 28, WOOD[1]);
  const sway = ringing ? Math.round(Math.sin(time * 3) * 2) : 0;
  for (let i = 0; i < 26; i++) {
    const t = i / 25, half = Math.round(5 + 4 * t * t + (t > .82 ? (t - .82) * 30 : 0)), yy = y - 26 + i;
    for (let dx = -half; dx <= half; dx++) D(x + sway + dx, yy, dx === -half || dx === half ? GOLD[0] : dx < -half * .45 ? GOLD[3] : dx < half * .2 ? GOLD[2] : GOLD[1]);
  }
  R(x + sway - 3, y - 22, 1, 14, GOLD[4]); R(x + sway - 14, y - 1, 29, 2, GOLD[0]); R(x + sway - 1, y + 1, 3, 3, IRON[2]);
}
function cocoon(c, x, y, time) {
  const { R, D } = painter(c);
  for (let i = 0; i < 34; i++) {
    const t = i / 33, half = Math.round(11 * Math.sin(Math.PI * Math.min(1, t * 1.05)) + 1);
    for (let dx = -half; dx <= half; dx++) { const band = (i + Math.round(dx * .6)) % 5 === 0; D(x + dx, y - 17 + i, band ? SILK[0] : dx < -half * .3 ? SILK[3] : dx > half * .5 ? SILK[1] : SILK[2]); }
  }
  R(x - 1, y - 60, 1, 43, SILK[2]);
}

// Painted concept props per arena, in world units (context scaled back from set pixels).
function props(c, images, stage) {
  if (!images) return;
  c.save(); c.scale(.5, .5);
  if (stage === 0) { drawProp(c, images, 'fernrock', 64, 420, .45); drawProp(c, images, 'fernrock', 900, 420, .42, { flip: true }); drawProp(c, images, 'shrooms', 800, 420, .32); drawProp(c, images, 'ruins', 230, 422, .3); }
  if (stage === 1) drawProp(c, images, 'tower', 92, 420, .38);
  if (stage === 2) { drawProp(c, images, 'rootcol', 64, 420, .45); drawProp(c, images, 'roots', 300, 80, .5, { top: true }); drawProp(c, images, 'roots', 700, 80, .42, { top: true, flip: true }); drawProp(c, images, 'shrooms', 610, 420, .3); }
  if (stage === 3) {
    drawProp(c, images, 'ivyarch', 480, 420, .62);
    for (const [x, f] of [[62, false], [212, true], [748, false], [898, true]]) drawProp(c, images, 'pillar', x, 420, .5, { flip: f });
    drawProp(c, images, 'shrine', 150, 420, .28); drawProp(c, images, 'shrine', 810, 420, .28);
  }
  c.restore();
}
export function drawArena(c, stage, time, reduced, world, images) {
  const t = reduced ? 0 : time;
  c.save(); c.imageSmoothingEnabled = false;
  c.drawImage(setCanvas(stage), 0, 0, W, H);
  props(c, images, stage);
  if (stage === 0) { lantern(c, 76, 178, t, reduced); lantern(c, 403, 178, t, reduced); }
  if (stage === 1) { wheel(c, 385, 128, t, reduced); hangingChain(c, 14, 467, 86, 10); lantern(c, 84, 154, t, reduced); }
  if (stage === 2) { flame(c, 127, 205, t, reduced, 1.1); lantern(c, 411, 170, t, reduced); }
  if (stage === 3) {
    bell(c, 240, 100, t, !world?.boss || world.boss.hp <= 0);
    cocoon(c, 240, 174, t);
  }
  if (stage === 4) flame(c, 95, 203, t, reduced, 1.3);
  c.restore();
}

// Boss hazards in the same pixel language (context is in world units).
export function drawHazardArt(c, h, time) {
  c.save(); c.imageSmoothingEnabled = false; c.translate(Math.round(h.x / 2) * 2, Math.round(h.y / 2) * 2); c.scale(2, 2);
  const { R, D } = painter(c), hw = Math.round(h.w / 4), hh = Math.round(h.h / 2);
  const blob = (cx, cy, r, ramp, seed) => { for (let y = -r; y <= r; y++) for (let x = -r; x <= r; x++) { const d = (x * x + y * y) / (r * r); if (d <= 1 && !(d > .6 && hash(seed + x * 7 + y * 3) > .55)) D(cx + x, cy + y, ramp[(x + y < -r * .4) ? 2 : d > .5 ? 0 : 1]); } };
  if (h.kind === 'axe') {
    // spinning woodcutter's axe: haft and a broad bearded head
    const a = time * 18, ca = Math.cos(a), sa = Math.sin(a), at = (u, v, col) => D(Math.round(ca * u - sa * v), Math.round(sa * u + ca * v), col);
    for (let u = -12; u <= 8; u++) { at(u, 0, WOOD[3]); at(u, 1, WOOD[1]); }
    for (let u = 3; u <= 12; u++) for (let v = -7; v <= 2; v++) { const edge = v <= -6 + Math.abs(u - 8) * .6; if (v >= -7 + Math.abs(u - 8) * .5) at(u, v, edge ? IRON[4] : v > 0 ? IRON[2] : IRON[3]); }
  } else if (h.kind === 'ring') {
    // sound rings rolling out of the bell
    for (let k = 0; k < 3; k++) for (let a = 0; a <= 40; a++) {
      const t = Math.PI + a / 40 * Math.PI, rx = hw + k * 3, ry = hh + k * 2;
      R(Math.cos(t) * rx, Math.sin(t) * ry, 2, 1, k === 0 ? '#ffffff' : k === 1 ? SILK[2] : SILK[0]);
    }
  } else if (h.kind === 'silk') {
    // silk curtain: wavy strands sheeting down, gathering in a pale drift at the floor
    for (let x = -hw; x <= hw; x += 2) {
      const ph = hash(x * 3.1) * 6, len = hh - Math.floor(hash(x) * 10);
      for (let y = 0; y < len; y++) { const xx = x + Math.round(Math.sin(y * .12 + ph + time * 4) * 1.4); D(xx, -y, (y + Math.floor(ph * 3)) % 11 < 2 ? SILK[3] : x % 4 ? SILK[1] : SILK[2]); }
    }
    for (let x = -hw - 3; x <= hw + 3; x++) { const t = 1 - Math.abs(x) / (hw + 4); R(x, -Math.round(3 * t), 1, Math.round(3 * t) + 1, x % 3 ? SILK[3] : SILK[2]); }
  } else if (h.kind === 'roots') {
    // briar canes bursting from cracked earth
    for (let x = -hw; x <= hw; x += 3) {
      const len = Math.round(hh * (.55 + hash(x + 3) * .45)), lean = (hash(x * 5) - .5) * 6;
      for (let i = 0; i < len; i++) { const xx = x + Math.round(lean * i / len); R(xx, -i, 2, 1, i > len - 3 ? BRIAR[0] : BRIAR[1]); D(xx + 1, -i, BRIAR[2]); if (i % 4 === 2) D(xx + (i % 8 < 4 ? -1 : 2), -i, BRIAR[0]); }
      if (hash(x * 9) > .5) { R(x + Math.round(lean) - 1, -len - 1, 3, 3, P.ivy[1]); D(x + Math.round(lean), -len - 1, P.ivy[3]); }
    }
    for (let k = 0; k < 6; k++) blob(-hw + k * (hw / 2.5), -1, 2, ['#3a2a22', '#5a4030', '#7a5a40'], k);
  } else {
    // slam / landing: dust billowing out, debris flung up, cracks in the floor
    for (let k = 0; k < 7; k++) { const x = -hw + k * hw / 3, r = 3 + Math.round(hash(k * 7) * 3); blob(x, -r + 1, r, ['#5d5160', '#8a7e86', '#c9bec2'], k * 13); }
    for (let k = 0; k < 9; k++) { const x = -hw + hash(k * 3) * hw * 2, y = -hh * (.4 + hash(k * 5) * .6); R(x, y, 2, 2, k % 2 ? P.stone[3] : P.stone[2]); D(x, y, P.stone[4]); }
    for (let x = -hw; x <= hw; x += 2) if (hash(x * 1.3) > .5) D(x, 0, '#15141e');
  }
  c.restore();
}
