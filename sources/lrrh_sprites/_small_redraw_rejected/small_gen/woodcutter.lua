-- Woodcutter at red-local scale (22 px tall: the biggest, broadest human in the roster).
-- attack = overhead axe chop, special = spinning axe sweep.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local K = dofile(HERE .. "/kit.lua")

local MAP = {
  H = "#7a4428", h = "#3e1e14", o = "#7a4428",  -- hair + beard, far boot; mouth (beard until opened)
  s = "#ffe2b4", c = "#ff9f89",                 -- skin (outdoor tan), blush
  E = "#000000", e = "#000000",                 -- eye top / eye bottom, near boot, belt
  R = "#d8463a", r = "#8c2230",                 -- plaid shirt
  P = "#5c4a6a", p = "#36283e",                 -- trousers
  a = "#c07c44",                                -- axe handle
  X = "#c8ccd8", x = "#907b7f", W = "#f6ecee",  -- axe head: steel, shade (= MARK2), edge (= MARK)
}
local function A(rows) return K.art(rows, MAP) end
local C = {}
for k, v in pairs(MAP) do C[k] = K.rgb(v) end
local MARK, MARK2 = K.MARK, K.MARK2

------------------------------------------------------------------ parts
local HEAD = A {
  "....hHHHH....",
  "..hhHHHHHHH..",
  ".hhHHHHHHHHH.",
  "hhHHHHHHHHHHH",
  "hhHHHHHHHHHHH",
  "hhHHHHssssssH",
  "hhHsHsEssEss.",
  "hhHsHsessess.",
  "hhHHHcsssccss",
  ".hhHHHHHHHHH.",
  "..hhHHHoHHHH.",
  "...hhHHHHHH..",
}
local HEAD_BLINK = K.swap(HEAD, { E = "s" }, MAP)
local HEAD_HURT = K.swap(HEAD, { E = "s", e = "h", o = "h" }, MAP)
local HEAD_SHOUT = K.swap(HEAD, { o = "h" }, MAP)
local HEAD_BACK = K.swap(HEAD, { s = "H", E = "H", e = "H", c = "H", o = "H" }, MAP)   -- turned away (spin)

local BODY = {
  idle = A {
    "...rRRrRRrRRR..",
    ".rrRRRrRRrRRRR.",
    "rrRRRRrRRrRRRRR",
    "rrrrrrrrrrrrrrr",
    "rrRRRRrRRrRRRRR",
    "rrRRRRrRRrRRRRR",
    ".rRRRRrRRrRRRR.",
    ".eeeeeeeeeeeee.",
    ".pPPPPPPPPPPPP.",
    ".ppPPPP.PPPPPP.",
  },
  idle2 = A {   -- breath out: chest drops a pixel
    "...............",
    "...rRRrRRrRRR..",
    "rrRRRRrRRrRRRRR",
    "rrrrrrrrrrrrrrr",
    "rrRRRRrRRrRRRRR",
    "rrRRRRrRRrRRRRR",
    ".rRRRRrRRrRRRR.",
    ".eeeeeeeeeeeee.",
    ".pPPPPPPPPPPPP.",
    ".ppPPPP.PPPPPP.",
  },
  lean = A {    -- leaning into a swing / run
    "....rRRrRRrRRR.",
    "..rrRRrRRrRRRRR",
    ".rRRRRrRRrRRRRR",
    "rrrrrrrrrrrrrrr",
    "rrRRRRrRRrRRRRR",
    "rrRRRRrRRrRRRR.",
    ".rRRRRrRRrRRRR.",
    ".eeeeeeeeeeeee.",
    ".pPPPPPPPPPPPP.",
    ".ppPPPP.PPPPPP.",
  },
  crouch = A {  -- squashed
    "..rrRRrRRrRRR..",
    "rrRRRRrRRrRRRRR",
    "rrrrrrrrrrrrrrr",
    "rrRRRRrRRrRRRRR",
    "rrRRRRrRRrRRRRR",
    ".eeeeeeeeeeeee.",
    ".pPPPPPPPPPPPP.",
    "ppPPPPP.PPPPPPP",
  },
}
local LEGS = {
  stand = A { "...hhh..eee....", "..hhhh..eeee..." },
  r1 = A { "..hhh.....eee..", ".hhhh.....eeee." },   -- near leg forward
  r2 = A { ".....hhheee....", ".....hhheeee..." },   -- passing
  r3 = A { "..eee.....hhh..", ".eeee.....hhhh." },   -- far leg forward
  r4 = A { ".....eeehhh....", ".....eeeehhh..." },   -- passing
  wide = A { "..hhh.....eee..", ".hhhh.....eeee." },
}

-- axe: base arts point up (blade on the right) and up-right; 'g' marks the grip (hand) pixel
local AMAP = { a = MAP.a, g = MAP.a, X = MAP.X, x = MAP.x, W = MAP.W }
local AXE_V = K.art({
  "..xXW.",
  ".xXXXW",
  "..aXXW",
  "..aXW.",
  "..a...",
  "..a...",
  "..a...",
  "..g...",
}, AMAP)
local AXE_D = K.art({
  "...xX...",
  "..xXXX..",
  "...XXXW.",
  "...aXXW.",
  "..a..WW.",
  ".a......",
  "g.......",
}, AMAP)
local function gripOf(a) for _, p in ipairs(a.px) do if p[4] == "g" then return p[1], p[2] end end end
-- dir: "u", "ur", "r", "dr", "d", "dl", "l", "ul" = where the head points; flip = blade on the other side
local AXES = {}
do
  local base = { u = { AXE_V, 0 }, r = { AXE_V, 1 }, d = { AXE_V, 2 }, l = { AXE_V, 3 },
                 ur = { AXE_D, 0 }, dr = { AXE_D, 1 }, dl = { AXE_D, 2 }, ul = { AXE_D, 3 } }
  for k, v in pairs(base) do AXES[k] = K.rot(v[1], v[2]) end
end
local function axe(c, hx, hy, dir, flip)
  local a = AXES[dir]
  if flip then
    -- mirror across the handle: horizontal handles mirror vertically, others horizontally
    if dir == "l" or dir == "r" then
      local o = { w = a.w, h = a.h, px = {} }
      for k, p in ipairs(a.px) do o.px[k] = { p[1], a.h - 1 - p[2], p[3], p[4] } end
      a = o
    else
      a = K.flip(a)
    end
  end
  local gx, gy = gripOf(a)
  K.put(c, a, hx - gx, hy - gy)
end

------------------------------------------------------------------ figure
local OX, OY = 7, 10   -- top-left of the 15x22 figure box when standing (feet on y = 31)
-- thick arm: 2 px sleeve (lit top, shaded bottom) from shoulder to a 2x2 fist at hand
local function arm(c, x0, y0, x1, y1)
  c:line(x0, y0 + 1, x1, y1 + 1, C.r)
  c:line(x0, y0, x1, y1, C.R)
  c:rect(x1, y1, x1 + 1, y1 + 1, C.s)
end
-- o: ox, oy, hx, hy, head, body, legs, by,
--    hand = {x, y} near fist (figure coords), armFrom = {x, y},
--    axe = {dir, flip} held at the fist (false = none), axeBehind = true (drawn before the body),
--    before/after = fn(c, X, Y)
local function fig(o)
  local c = K.canvas()
  local X, Y = OX + (o.ox or 0), OY + (o.oy or 0)
  local hand = o.hand or { 13, 15 }
  local from = o.armFrom or { 12, 12 }
  local ax = o.axe
  if ax == nil then ax = { "d", true } end
  if o.before then o.before(c, X, Y) end
  if ax and o.axeBehind then axe(c, X + hand[1], Y + hand[2], ax[1], ax[2]) end
  local body = o.body or BODY.idle
  K.put(c, o.legs or LEGS.stand, X, Y + 20)
  K.put(c, body, X, Y + 20 - body.h + (o.by or 0))
  K.put(c, o.head or HEAD, X + 1 + (o.hx or 0), Y + (o.hy or 0))
  if ax and not o.axeBehind then axe(c, X + hand[1], Y + hand[2], ax[1], ax[2]) end
  if o.arm ~= false then arm(c, X + from[1], Y + from[2], X + hand[1], Y + hand[2]) end
  if o.after then o.after(c, X, Y) end
  return c
end

-- whirl trail: part of an ellipse around the waist, angles in degrees (0 = right, 90 = down)
local function trail(c, cx, cy, rx, ry, a0, a1, col)
  local n = math.max(6, math.floor(math.abs(a1 - a0) / 6))
  for k = 0, n do
    local t = math.rad(a0 + (a1 - a0) * k / n)
    c:set(K.round(cx + math.cos(t) * rx), K.round(cy + math.sin(t) * ry), col)
  end
end
local DOWN = A {   -- face down on the ground, boots at the left (head drawn separately)
  "..........rRRRR.",
  "....pPPPPrRRrRRR",
  "hhe.pPPPPrrrrrrr",
  "hheepppppreRrRRR",
}

------------------------------------------------------------------ animation
local function draw(tag, i)
  if tag == "idle" then
    local P = {
      { },
      { hy = 1, body = BODY.idle2, hand = { 13, 16 } },
      { hy = 1, body = BODY.idle2, head = HEAD_BLINK, hand = { 13, 16 } },
      { hx = 1, hand = { 13, 15 } },
    }
    return fig(P[i + 1])
  end

  if tag == "run" then
    -- axe carried at port arms, head up in front, bobbing with his stride
    local P = {
      { hx = 1, body = BODY.lean, legs = LEGS.r1, armFrom = { 11, 13 }, hand = { 14, 14 }, axe = { "ur" } },
      { hx = 1, oy = -1, body = BODY.lean, legs = LEGS.r2, armFrom = { 11, 13 }, hand = { 14, 15 }, axe = { "ur" } },
      { hx = 1, body = BODY.lean, legs = LEGS.r3, armFrom = { 11, 13 }, hand = { 13, 14 }, axe = { "ur" } },
      { hx = 1, oy = -1, body = BODY.lean, legs = LEGS.r4, armFrom = { 11, 13 }, hand = { 14, 15 }, axe = { "ur" } },
    }
    local c = fig(P[i + 1])
    if i == 0 or i == 2 then K.dust(c, OX + 2, 31, i) end
    return c
  end

  if tag == "attack" then
    -- axe hauled up overhead, brought down in a chop that bites the ground in front
    local P = {
      { hx = -1, hy = 2, body = BODY.crouch, legs = LEGS.wide, armFrom = { 11, 13 }, hand = { 5, 15 }, axe = { "dl" }, axeBehind = true },
      { hx = -1, body = BODY.idle, legs = LEGS.wide, armFrom = { 12, 12 }, hand = { 13, 2 }, axe = { "ul" }, axeBehind = true },
      { hx = 1, head = HEAD_SHOUT, body = BODY.lean, legs = LEGS.wide, armFrom = { 12, 12 }, hand = { 16, 9 }, axe = { "ur" } },
      { hx = 2, hy = 1, head = HEAD_SHOUT, body = BODY.lean, legs = LEGS.wide, armFrom = { 12, 13 }, hand = { 16, 14 }, axe = { "dr" } },
      { hx = 2, hy = 2, body = BODY.crouch, legs = LEGS.wide, armFrom = { 12, 14 }, hand = { 16, 15 }, axe = { "dr" } },
      { body = BODY.idle2, hand = { 13, 16 } },
    }
    local c = fig(P[i + 1])
    local X, Y = OX, OY
    if i == 2 then
      c:curve(X + 13, Y - 2, X + 23, Y - 2, X + 24, Y + 8, MARK)
      c:curve(X + 15, Y - 1, X + 22, Y + 1, X + 23, Y + 8, MARK2)
    elseif i == 3 then
      c:curve(X + 22, Y + 2, X + 25, Y + 8, X + 23, Y + 17, MARK2)
      K.bang(c, X + 22, Y + 9)
      K.dust(c, X + 23, 31, 0); K.dust(c, X + 18, 31, 1)
    elseif i == 4 then
      K.dust(c, X + 24, 30, 1)
    end
    return c
  end

  if tag == "special" then
    -- winds up, then spins on the spot with the axe held out: front, back, front, back...
    local cx, cy = OX + 7, OY + 15
    local P = {
      { hx = -1, hy = 2, body = BODY.crouch, legs = LEGS.wide, armFrom = { 11, 13 }, hand = { 2, 15 }, axe = { "l" } },
      { hx = 1, head = HEAD_SHOUT, body = BODY.lean, legs = LEGS.wide, armFrom = { 12, 13 }, hand = { 15, 14 }, axe = { "r" } },
      { head = HEAD_BACK, body = BODY.idle, legs = LEGS.wide, armFrom = { 3, 13 }, hand = { 1, 14 }, axe = { "l" } },
      { hx = 1, head = HEAD_SHOUT, body = BODY.lean, legs = LEGS.wide, armFrom = { 12, 13 }, hand = { 15, 14 }, axe = { "r" } },
      { head = HEAD_BACK, body = BODY.idle, legs = LEGS.wide, armFrom = { 3, 13 }, hand = { 1, 14 }, axe = { "l" } },
      { hx = 1, head = HEAD_SHOUT, body = BODY.lean, legs = LEGS.wide, armFrom = { 12, 13 }, hand = { 15, 14 }, axe = { "r" } },
      { hx = 2, hy = 2, body = BODY.crouch, legs = LEGS.wide, armFrom = { 12, 14 }, hand = { 16, 15 }, axe = { "dr" } },
      { hy = 1, body = BODY.idle2, hand = { 13, 16 } },
    }
    local p = P[i + 1]
    if i >= 1 and i <= 5 then
      local front = (i % 2 == 1)
      p.before = function(c)   -- far half of the whirl, behind him
        trail(c, cx, cy - 1, 13, 4, 190, 350, MARK2)
      end
      p.after = function(c)    -- near half, in front
        if front then trail(c, cx, cy - 1, 13, 4, 10 + i * 4, 170, MARK)
        else trail(c, cx, cy - 1, 13, 4, 10, 170 - i * 4, MARK) end
      end
    elseif i == 6 then
      p.after = function(c) K.dust(c, OX + 21, 31, 0); K.dust(c, OX + 3, 31, 1) end
    end
    return fig(p)
  end

  local HURT = { hx = -1, head = HEAD_HURT, body = BODY.idle2, legs = LEGS.wide, armFrom = { 12, 12 }, hand = { 14, 11 }, axe = { "u" } }
  if tag == "hit" then
    if i == 0 then return K.flashOf(fig(HURT)) end
    if i == 3 then return fig({ hy = 1, body = BODY.idle2, hand = { 13, 16 } }) end
    local s = i - 1
    local c = fig({ ox = -1 - s, hx = -1 - s, head = HEAD_HURT, body = BODY.idle2, legs = LEGS.wide,
                    armFrom = { 12, 12 }, hand = { 14, 11 + s }, axe = { "u" } })
    K.bang(c, OX + 16 - s, OY - 1 + s)
    return c
  end

  if tag == "death" then
    if i == 0 then
      local c = fig(HURT); K.bang(c, OX + 17, OY - 1); return c
    end
    if i == 1 then   -- legs buckle, the axe slips
      return fig({ hx = -1, hy = 3, by = 1, head = HEAD_HURT, body = BODY.crouch, legs = LEGS.wide,
                   armFrom = { 12, 14 }, hand = { 14, 15 }, axe = { "dr" } })
    end
    if i == 2 then   -- on his knees, axe dropped
      local c = fig({ ox = 1, hx = 1, hy = 6, by = 2, head = HEAD_HURT, body = BODY.crouch, legs = LEGS.wide,
                      arm = false, axe = false })
      axe(c, OX + 15, 29, "r", true)
      return c
    end
    -- face down: boots at the left, head resting at the right, axe beside him
    local c = K.canvas()
    local dy = (i == 3) and -1 or 0
    axe(c, 23, 29, "r", true)
    K.foot(c, DOWN, 2, 31 + dy)
    K.foot(c, HEAD_HURT, 14, 31 + dy)
    if i == 3 then K.dust(c, 3, 31, 0); K.dust(c, 29, 30, 1) end
    if i >= 4 and i <= 6 then K.dizzy(c, 19, 12 - (i - 4), i) end
    return c
  end
end

return K.build("woodcutter", draw)
