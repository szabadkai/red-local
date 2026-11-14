-- Thorn Brambles at red-local scale: a low thorny bush, 24x13, with a glowing red core.
-- attack = vine whip lash, special = thorny vines burst out in every direction,
-- death = the bush withers and slumps into a dry heap.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local K = dofile(HERE .. "/kit.lua")

local MAP = {
  P = "#8f3a7e", p = "#55204f",                 -- bush mass
  V = "#ecbe74", v = "#ad7444",                 -- vines and thorns
  R = "#fd3150", r = "#94031a", Y = "#ffe08a",  -- core and berries, core glint
}
local function A(rows) return K.art(rows, MAP) end
local MARK, MARK2 = K.MARK, K.MARK2
local C = {}
for k, v in pairs(MAP) do C[k] = K.rgb(v) end

------------------------------------------------------------------ bush (24 cols)
-- outer ring of vines on the dome edge, an inner ring of vines round the core's dark nest
local LOWER = {   -- rows 4..12, shared by the rest and squashed domes
  "....vppppPPPPVVVVPPV....",
  "...vpppppPPPVppppVPPV...",
  "..vpppppPPPvppppppVRPV..",
  ".vppppppPPpvppppppVPPPV.",
  ".vpppRpppppvppppppVPPPV.",
  ".vpppppppppvppppppVPPPV.",
  "vpppppRpppppvppppvPPPPPV",
  "vppppppppppppvvvvpppPPPv",
  ".ppv.ppppvp.pppppp.vpp..",
}
local function dome(top)
  local rows = {}
  for _, r in ipairs(top) do rows[#rows + 1] = r end
  for _, r in ipairs(LOWER) do rows[#rows + 1] = r end
  return A(rows)
end
local MASS = {
  rest = dome {
    "........................",
    "..........vVVV..........",
    ".......vvvPPPPVVV.......",
    ".....vvppPPPPPPPPVV.....",
  },
  -- flattened one row (anticipation, hurt)
  squash = dome {
    "........................",
    ".........vvVVVV.........",
    "......vvvPPPPPPVVV......",
  },
}
-- thorn tips round the rim (rest coordinates); the three sets ripple round the dome
local THORNS = {
  A = { { 9, 0 }, { 14, 0 }, { 7, 1 }, { 16, 1 }, { 4, 3 }, { 19, 3 }, { 2, 5 }, { 21, 5 }, { 0, 7 }, { 23, 8 } },
  B = { { 10, 0 }, { 13, 0 }, { 8, 1 }, { 15, 1 }, { 6, 2 }, { 17, 2 }, { 3, 4 }, { 20, 4 }, { 1, 6 }, { 22, 6 } },
  C = { { 9, 1 }, { 14, 1 }, { 5, 2 }, { 18, 2 }, { 2, 4 }, { 21, 4 }, { 0, 6 }, { 22, 6 }, { 0, 9 }, { 23, 9 } },
}
-- 4x4 core, top-left at (13, 6) of the rest bush
local CORE = {
  normal = A { ".RR.", "RRYR", "rRRR", ".rr." },
  bright = A { ".RR.", "RYYR", "RYYR", ".rr." },
  dim    = A { ".rr.", "rrRr", "rrrr", ".rr." },
  shut   = A { "....", "RRRR", "rrrr", "...." },
  dead   = A { "....", "....", "rrrr", "...." },
}

-- run legs: thin stems under a raised bush (bottom row on the ground)
local LEGS = {
  a1 = A { "..v...v....v.....v..v..." },
  a2 = A { "...v...v....v.....v..v..", "..v...v....v.....v..v..." },
  b1 = A { "...v.v.....v.v....v.v..." },
  b2 = A { "....v...v....v....v...v.", "...v...v....v....v...v.." },
}

-- withered heap (dry colours only)
local HEAP = A {
  ".......v....v....v......",
  "...v..vpv..vpv..vpv.v...",
  "..vpppppppvpppppppppv...",
  ".vppppvpppppprrppvppppv.",
  "vpppppppvpppppppppppppv.",
  ".pp.vpppppp.ppppvppp.pp.",
}

------------------------------------------------------------------ figure
local BX = 4          -- bush left edge; bottom row on the ground
-- o: mass, thorns (set name or false), core, ox, lift (raise the bush, legs drawn under), legs, dry
local function bush(c, o)
  local m = o.mass or MASS.rest
  local x = BX + (o.ox or 0)
  local bottom = 31 - (o.lift or 0)
  local top = bottom - m.h + 1
  local sq = 13 - m.h         -- rows the squashed dome lost
  local dry = o.dry
  local function col(ch)
    if dry then
      if ch == "P" or ch == "V" then return C.v elseif ch == "R" or ch == "Y" then return C.r end
    end
    return C[ch]
  end
  if o.legs then K.foot(c, o.legs, x) end
  for _, p in ipairs(m.px) do c:set(x + p[1], top + p[2], col(p[4])) end
  if o.thorns ~= false then
    for _, t in ipairs(THORNS[o.thorns or "A"]) do
      local ty = t[2] >= 2 and t[2] - sq or t[2]
      c:set(x + t[1], top + ty, (t[1] < 6 or dry) and C.v or C.V)
    end
  end
  local core = o.core or CORE.normal
  for _, p in ipairs(core.px) do c:set(x + 13 + p[1], top + 6 - sq + p[2], col(p[4])) end
  return c
end

------------------------------------------------------------------ vines
local function qb(p0, p1, p2, t)
  local a, b = (1 - t) ^ 2, 2 * (1 - t) * t
  return a * p0[1] + b * p1[1] + t * t * p2[1], a * p0[2] + b * p1[2] + t * t * p2[2]
end
-- 8-connected pixel path along a quadratic curve up to t = g, with L-corners removed
local function path(p0, p1, p2, g)
  local raw = {}
  for k = 0, 80 do
    local x, y = qb(p0, p1, p2, (g or 1) * k / 80)
    x, y = K.round(x), K.round(y)
    local l = raw[#raw]
    if not l or l[1] ~= x or l[2] ~= y then raw[#raw + 1] = { x, y } end
  end
  local out = {}
  for k, p in ipairs(raw) do
    local a, b = out[#out], raw[k + 1]
    local corner = a and b and (a[1] == p[1] or a[2] == p[2]) and (b[1] == p[1] or b[2] == p[2])
                   and a[1] ~= b[1] and a[2] ~= b[2]
    if not corner then out[#out + 1] = p end
  end
  return out
end
-- a thorny vine: lit line, shade pixel on the lower-left for the thick base,
-- thorn nubs every few pixels alternating sides, optional hooked tip and berry.
-- o.thick (0..1 share of the length drawn 2 px wide), o.thorn (spacing), o.hook (-1/1 curl side),
-- o.berry (path index)
local function vine(c, p0, p1, p2, g, o)
  o = o or {}
  local pts = path(p0, p1, p2, g)
  local n = #pts
  local lit, dk = C.V, C.v
  local thick = math.floor(n * (o.thick or 0.5))
  local function dir(k)
    local a, b = pts[math.max(1, k - 1)], pts[math.min(n, k + 1)]
    return b[1] - a[1], b[2] - a[2]
  end
  local function shadeOff(k)
    local dx, dy = dir(k)
    if math.abs(dx) > math.abs(dy) then return 0, 1 end
    return -1, 0
  end
  for k = 1, thick do
    local q, sx, sy = pts[k], shadeOff(k)
    c:set(q[1] + sx, q[2] + sy, dk)
  end
  local sp = o.thorn or 3
  local side = 1
  for k = 3, n - 1 do
    if k % sp == 0 then
      local dx, dy = dir(k)
      local nx, ny = dy, -dx
      if nx - ny < 0 then nx, ny = -nx, -ny end        -- (nx, ny) points up/right of the vine
      local len = math.max(1, math.sqrt(nx * nx + ny * ny))
      nx, ny = K.round(nx / len), K.round(ny / len)
      if side < 0 then
        -- underside thorn, only where the vine is 1 px wide
        if k > thick then c:set(pts[k][1] - nx, pts[k][2] - ny, lit) end
      else
        c:set(pts[k][1] + nx, pts[k][2] + ny, lit)
      end
      side = -side
    end
  end
  for _, q in ipairs(pts) do c:set(q[1], q[2], lit) end
  if o.hook and n >= 3 then
    -- curl the tip back by two pixels
    local q = pts[n]
    local dx, dy = dir(n)
    local hx, hy = K.round(dy * o.hook), K.round(-dx * o.hook)
    c:set(q[1] + hx, q[2] + hy, lit)
    c:set(q[1] + hx - K.round(dx * 0.7), q[2] + hy - K.round(dy * 0.7), dk)
  end
  if o.berry and pts[o.berry] then
    local q = pts[o.berry]
    local sx, sy = shadeOff(o.berry)
    c:set(q[1] - sy, q[2] + sx - 1, C.R)
  end
  return pts
end

------------------------------------------------------------------ animation
-- special: tendrils by { base, ctrl, tip } (canvas coords), drawn behind the bush
local BURST = {
  { { 9, 24 }, { 3, 14 }, { 6, 7 } },
  { { 14, 22 }, { 11, 11 }, { 15, 4 } },
  { { 20, 22 }, { 27, 13 }, { 24, 5 } },
  { { 6, 28 }, { 1, 28 }, { 1, 20 } },
  { { 26, 27 }, { 31, 27 }, { 30, 19 } },
}
local BURST2 = {   -- same tendrils mid-wiggle
  { { 9, 24 }, { 4, 13 }, { 7, 7 } },
  { { 14, 22 }, { 12, 11 }, { 14, 4 } },
  { { 20, 22 }, { 26, 13 }, { 25, 6 } },
  { { 6, 28 }, { 1, 27 }, { 2, 20 } },
  { { 26, 27 }, { 30, 26 }, { 29, 19 } },
}

local function draw(tag, i)
  local c = K.canvas()
  if tag == "idle" then
    local P = {
      { thorns = "A", core = CORE.normal },
      { thorns = "B", core = CORE.bright },
      { thorns = "C", core = CORE.normal },
      { thorns = "B", core = CORE.dim },
    }
    return bush(c, P[i + 1])
  end

  if tag == "run" then
    -- scuttles on its stems: contact, raised, contact, raised; thorns ripple backwards
    local P = {
      { lift = 1, legs = LEGS.a1, thorns = "C" },
      { lift = 2, legs = LEGS.a2, thorns = "B" },
      { lift = 1, legs = LEGS.b1, thorns = "A" },
      { lift = 2, legs = LEGS.b2, thorns = "B", core = CORE.bright },
    }
    bush(c, P[i + 1])
    if i == 0 then K.dust(c, BX + 1, 31, 0) elseif i == 2 then K.dust(c, BX + 2, 31, 1) end
    return c
  end

  if tag == "attack" then
    -- a cane rears up behind, arcs over the top and lashes down in front, then recoils
    local W = {
      { { 8, 25 }, { 1, 13 }, { 9, 10 }, 1, -1, "B", CORE.bright, MASS.squash },
      { { 8, 25 }, { 5, 0 }, { 21, 6 }, 1, 1, "C", CORE.bright },
      { { 8, 25 }, { 17, -6 }, { 29, 13 }, 1, 1, "A", CORE.normal },
      { { 8, 25 }, { 23, -3 }, { 29, 28 }, 1, 1, "B", CORE.bright },
      { { 8, 25 }, { 19, 3 }, { 26, 16 }, 1, 1, "C", CORE.normal },
      { { 8, 25 }, { 9, 14 }, { 16, 15 }, 1, 1, "A", CORE.normal },
    }
    local w = W[i + 1]
    if i == 2 then           -- swish behind the cane
      c:curve(9, 7, 17, -2, 27, 6, MARK)
      c:curve(10, 10, 18, 2, 25, 8, MARK2)
    end
    bush(c, { mass = w[8], thorns = w[6], core = w[7] })
    vine(c, w[1], w[2], w[3], w[4], { thick = 0.55, thorn = 3, hook = w[5], berry = 6 })
    if i == 3 then
      K.bang(c, 24, 13)
      K.dust(c, 30, 30, 1)
    end
    return c
  end

  if tag == "special" then
    -- squeeze, then thorny tendrils burst out on all sides, wiggle, and draw back in
    local g = ({ 0, 0.3, 0.6, 0.9, 1, 1, 0.55, 0.2 })[i + 1]
    local set = (i == 5) and BURST2 or BURST
    if g > 0 then
      for k, t in ipairs(set) do
        vine(c, t[1], t[2], t[3], g, { thick = 0.7, thorn = 2, hook = (g >= 0.9) and ((t[3][1] < 16) and 1 or -1) or nil })
      end
    end
    local P = {
      { mass = MASS.squash, thorns = "B", core = CORE.bright },
      { mass = MASS.squash, thorns = "C", core = CORE.bright },
      { thorns = "A", core = CORE.bright },
      { thorns = "B", core = CORE.bright },
      { thorns = "C", core = CORE.bright },
      { thorns = "A", core = CORE.bright },
      { thorns = "B", core = CORE.normal },
      { thorns = "C", core = CORE.normal },
    }
    bush(c, P[i + 1])
    return c
  end

  local HURT = { ox = -1, mass = MASS.squash, thorns = "C", core = CORE.shut }
  if tag == "hit" then
    if i == 0 then return K.flashOf(bush(c, HURT)) end
    if i == 3 then return bush(c, { thorns = "B", core = CORE.dim }) end
    bush(c, { ox = -1, mass = MASS.squash, thorns = (i == 1) and "C" or "A", core = CORE.shut })
    K.bang(c, 25 + (i - 1), 17 - (i - 1))
    -- a snapped thorn flies off
    c:set(24 + i * 2, 20 + i * 2, C.V); c:set(25 + i * 2, 20 + i * 2 - (i % 2), C.v)
    return c
  end

  if tag == "death" then
    if i == 0 then
      bush(c, HURT); K.bang(c, 25, 17); return c
    end
    if i == 1 then return bush(c, { mass = MASS.squash, thorns = "C", core = CORE.dim }) end
    if i == 2 then return bush(c, { mass = MASS.squash, thorns = false, core = CORE.dead, dry = true }) end
    K.foot(c, HEAP, BX, (i == 3) and 30 or 31)
    if i == 3 then K.dust(c, BX, 31, 0); K.dust(c, BX + 24, 31, 1) end
    if i >= 4 and i <= 6 then K.dizzy(c, 14, 18 - (i - 4), i) end
    return c
  end
end

return K.build("thorn_brambles", draw)
