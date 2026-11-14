-- Shared helpers for the story bosses: the roster's lib.lua on 48x48 cells, plus rig helpers.
-- Same conventions as the roster: one light from the upper right, near-black outline,
-- 2 px yellow eyes, white hit flash, "!!" impact marks, dizzy swirl on the death pose.
-- Sheets land in lrrh_sprites/bosses/ in the roster layout (idle run attack special hit death).
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
_G.LIB_SIZE = 48
local L = dofile(HERE .. "/../enemy_gen/lib.lua")
_G.LIB_SIZE = nil

local B = { L = L, OUT_DIR = HERE .. "/../bosses", S = 48, GROUND = 47 }
B.OUT = L.rgb("#15141e")
B.EYE = L.rgb("#f3cb29")
B.MASK = L.rgb("#ffffff")
B.DUST = { L.MARK2, L.rgb("#5d5160"), L.rgb("#3a3340") }

function B.ramp(list) local o = {} for i, h in ipairs(list) do o[i] = L.rgb(h) end return o end

-- Shade a part: fn(m, col) paints its silhouette into a fresh mask, which is then lit into dst.
function B.part(dst, ramp, bias, fn)
  local m = L.canvas()
  fn(m, B.MASK)
  L.shade(dst, m, ramp, bias)
  return m
end
-- Limb from a hip: upper segment at angle a1, lower at a2 (radians, 0 = straight down).
function B.limb(m, col, hx, hy, l1, a1, l2, a2, r1, r2)
  local kx, ky = hx + math.sin(a1) * l1, hy + math.cos(a1) * l1
  local fx, fy = kx + math.sin(a2) * l2, ky + math.cos(a2) * l2
  m:seg(hx, hy, kx, ky, r1, col)
  m:seg(kx, ky, fx, fy, r2, col)
  return fx, fy, kx, ky
end
-- Thorny vine along a quadratic curve: dark stem, alternating 1 px thorns, optional red buds.
function B.vine(c, x0, y0, cx, cy, x1, y1, stem, thorn, bud, seed)
  local steps = 14
  local px_, py_ = x0, y0
  for i = 1, steps do
    local t = i / steps
    local a, b = (1 - t) ^ 2, 2 * (1 - t) * t
    local x, y = a * x0 + b * cx + t * t * x1, a * y0 + b * cy + t * t * y1
    c:line(px_, py_ + 1, x, y + 1, stem[2])
    c:line(px_, py_, x, y, stem[1])
    if i % 3 == 0 then
      local nx, ny = -(y - py_), x - px_
      local len = math.sqrt(nx * nx + ny * ny) + 1e-6
      local s = (i // 3) % 2 == 0 and 1 or -1
      c:set(x + nx / len * 1.6 * s, y + ny / len * 1.6 * s + (s > 0 and 0 or 1), thorn)
    end
    if bud and i % 6 == (seed or 3) % 6 then
      c:set(x, y - 1, bud[1]); c:set(x + 1, y - 1, bud[1]); c:set(x, y - 2, bud[2]); c:set(x + 1, y, bud[1])
    end
    px_, py_ = x, y
  end
end
-- Chain of links along a straight run: alternating light/dark 2 px links.
function B.chain(c, x0, y0, x1, y1, ramp)
  local n = math.max(1, math.floor(math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2) / 2))
  for i = 0, n do
    local t = i / n
    local x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
    if i % 2 == 0 then c:set(x, y, ramp[3]); c:set(x + 1, y, ramp[2]); c:set(x, y + 1, ramp[1]); c:set(x + 1, y + 1, ramp[1])
    else c:set(x, y, ramp[2]); c:set(x, y + 1, ramp[1]) end
  end
end
-- White swoosh arc for strikes (like the roster's attack arcs).
function B.arc(c, cx, cy, r, a0, a1, col, col2)
  local steps = math.floor(math.abs(a1 - a0) * r) + 2
  for i = 0, steps do
    local a = a0 + (a1 - a0) * i / steps
    c:set(cx + math.cos(a) * r, cy + math.sin(a) * r, i < steps * .7 and col or (col2 or col))
    if i > steps * .25 and i < steps * .8 then c:set(cx + math.cos(a) * (r - 1), cy + math.sin(a) * (r - 1), col2 or col) end
  end
end
function B.finish(c) c:outline(B.OUT); return c:despeckle() end

function B.build(name, draw)
  return L.build(name, B.OUT_DIR, draw, B.OUT_DIR .. "/" .. name .. "_review_x4.png")
end
return B
