// Painted concept props (interior-props-v2, bridge-atlas-v1) placed at a chosen scale and reduced
// once onto the game's 2-world-unit pixel grid: smooth downscale to half resolution, hard alpha,
// light posterise, then drawn at 2x. Crops are the props' tight bounds, so the bottom edge is the base.
const PROPS = {
  rootcol: ['concept-interior-props-v2', 31, 8, 353, 418],
  roots: ['concept-interior-props-v2', 455, 9, 419, 373],
  fernrock: ['concept-interior-props-v2', 898, 65, 418, 356],
  shrooms: ['concept-interior-props-v2', 1386, 172, 334, 244],
  pillar: ['concept-interior-props-v2', 65, 446, 270, 433],
  ivyarch: ['concept-interior-props-v2', 454, 449, 417, 422],
  ruins: ['concept-interior-props-v2', 893, 590, 437, 281],
  shrine: ['concept-interior-props-v2', 1330, 445, 349, 428],
  tower: ['concept-bridge-atlas-v1', 24, 30, 550, 575],
  crypt: ['concept-bridge-atlas-v1', 640, 740, 610, 396],
};
const baked = new Map();
function bake(images, name, scale) {
  const key = name + '@' + scale;
  if (baked.has(key)) return baked.get(key);
  const [sheet, sx, sy, sw, sh] = PROPS[name], img = images.get(sheet);
  if (!img || !img.complete || !img.naturalWidth) return null;
  const cv = document.createElement('canvas');
  cv.width = Math.max(1, Math.round(sw * scale / 2)); cv.height = Math.max(1, Math.round(sh * scale / 2));
  const c = cv.getContext('2d');
  c.imageSmoothingEnabled = true; c.imageSmoothingQuality = 'high';
  c.drawImage(img, sx, sy, sw, sh, 0, 0, cv.width, cv.height);
  const d = c.getImageData(0, 0, cv.width, cv.height), p = d.data;
  for (let i = 0; i < p.length; i += 4) {
    if (p[i + 3] < 140) { p[i + 3] = 0; continue; }
    p[i + 3] = 255; for (let k = 0; k < 3; k++) p[i + k] = Math.min(255, Math.round(p[i + k] / 6) * 6);
  }
  c.putImageData(d, 0, 0);
  baked.set(key, cv);
  return cv;
}
// x is the prop's centre, base the world y its bottom rests on (a hanging prop passes top=true).
export function drawProp(ctx, images, name, x, base, scale = .45, { flip = false, top = false } = {}) {
  const art = bake(images, name, scale);
  if (!art) return;
  const w = art.width * 2, h = art.height * 2, left = Math.round((x - w / 2) / 2) * 2, y = Math.round((top ? base : base - h + 2) / 2) * 2;
  ctx.save(); ctx.imageSmoothingEnabled = false;
  if (flip) { ctx.translate(left + w, y); ctx.scale(-1, 1); ctx.drawImage(art, 0, 0, w, h); }
  else ctx.drawImage(art, left, y, w, h);
  ctx.restore();
}
export const propSize = (name, scale = .45) => { const [, , , sw, sh] = PROPS[name]; return { w: Math.round(sw * scale / 2) * 2, h: Math.round(sh * scale / 2) * 2 }; };
