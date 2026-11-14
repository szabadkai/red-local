-- Mother at red-local scale (20 px tall, a little taller than Red).
-- attack = finger-pointing scold, special = golden shield arc thrown up in front of her.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local K = dofile(HERE .. "/kit.lua")

local MAP = {
  H = "#6a3346", h = "#3a1626",                 -- hair (bun at the back), far leg
  s = "#ffeec8", b = "#ff9f89", o = "#ffeec8",  -- skin, blush, mouth (skin until opened)
  E = "#000000", e = "#000000",                 -- eye top / eye bottom, near leg
  P = "#8048a8", p = "#4e2470",                 -- dress (bodice, sleeves, skirt)
  w = "#fffff2", W = "#b2af9a",                 -- apron
  G = "#ffd24a", g = "#d98a1e",                 -- golden shield
}
local function A(rows) return K.art(rows, MAP) end
local C = {}
for k, v in pairs(MAP) do C[k] = K.rgb(v) end
local MARK, MARK2 = K.MARK, K.MARK2

------------------------------------------------------------------ parts (14 cols wide)
local HEAD = A {
  ".hh...HHHHH...",
  "hhhh.HHHHHHHH.",
  "hhhhHHHHHHHHHH",
  ".hhHHHHHHHHHHH",
  "..hHHHHHHHssHH",
  "..hHHHHHsssssH",
  "..hhHHHsEssEsH",
  "...hHHHsessesH",
  "...hhHHbssssbs",
  "....hhhhssoss.",
}
local HEAD_BLINK = K.swap(HEAD, { E = "s" }, MAP)
local HEAD_HURT = K.swap(HEAD, { E = "s", e = "h", o = "h" }, MAP)
local HEAD_SHOUT = K.swap(HEAD, { o = "h" }, MAP)

local BODY = {
  idle = A {
    ".....pPPPPP...",
    "....pPPPPPPP..",
    "....pPPwwwwP..",
    "....pPPwwwwP..",
    "...pPPwwwwwwP.",
    "...pPPWwwwwwP.",
    "..ppPPWwwwwwPP",
    "..pppPWWWWWWpp",
  },
  idle2 = A {   -- hem swings a pixel
    ".....pPPPPP...",
    "....pPPPPPPP..",
    "....pPPwwwwP..",
    "....pPPwwwwP..",
    "....pPwwwwwwP.",
    "...pPPWwwwwwP.",
    "...pPPWwwwwwPP",
    "..pppPWWWWWWpp",
  },
  runA = A {    -- skirt blown back
    ".....pPPPPP...",
    "....pPPPPPPP..",
    "...ppPPwwwwP..",
    "..pPPPPwwwwP..",
    ".pPPPPwwwwwwP.",
    "ppPPPPWwwwwwP.",
    ".ppPPPWwwwwwP.",
    "...ppPWWWWWWp.",
  },
  runB = A {
    ".....pPPPPP...",
    "....pPPPPPPP..",
    "....pPPwwwwP..",
    "...pPPPwwwwP..",
    "..pPPPwwwwwwP.",
    ".ppPPPWwwwwwP.",
    "..ppPPWwwwwwPP",
    "...ppPWWWWWWp.",
  },
  crouch = A {  -- squashed: anticipation, bracing, landing
    "....pPPPPPP...",
    "...pPPPwwwwP..",
    "...pPPwwwwwwP.",
    "..pPPPWwwwwwP.",
    "..ppPPWwwwwwPP",
    ".ppppPWWWWWWpp",
  },
}
local LEGS = {
  stand = A { "......hh.ee...", ".....hhh.eee.." },
  r1 = A { ".....hh...ee..", "....hh.....ee." },   -- near leg forward
  r2 = A { ".......hhee...", "........eee..." },   -- passing, far leg lifted
  r3 = A { ".....ee...hh..", "....ee.....hh." },   -- far leg forward
  r4 = A { ".......eehh...", "........hhh..." },   -- passing, near leg lifted
  wide = A { "....hh....ee..", "...hh......ee." },  -- braced
}
local DOWN = A {   -- flat on her front, head drawn separately at the right
  "......pPPPPP..",
  "hh..ppPPPPPPP.",
  "hhhpPPPPwwwww.",
  "eeeppppWWWWWW.",
}

------------------------------------------------------------------ figure
local OX, OY = 8, 12   -- top-left of the 14x20 figure box when standing (feet on y = 31)
-- o: ox, oy (whole figure), hx, hy (head offset), head, body, legs,
--    hand = {x, y} front hand, armFrom = {x, y}, point = true (2 px pointing hand),
--    hand2 = {x, y} far hand (drawn behind the body), before/after = fn(c, X, Y)
local function fig(o)
  local c = K.canvas()
  local X, Y = OX + (o.ox or 0), OY + (o.oy or 0)
  if o.before then o.before(c, X, Y) end
  if o.hand2 then
    local f2 = o.arm2From or { 6, 11 }
    c:line(X + f2[1], Y + f2[2], X + o.hand2[1], Y + o.hand2[2], C.p)
    c:set(X + o.hand2[1] + (o.hand2[1] >= f2[1] and 1 or -1), Y + o.hand2[2], C.s)
  end
  local body = o.body or BODY.idle
  K.put(c, o.legs or LEGS.stand, X, Y + 18)
  K.put(c, body, X, Y + 18 - body.h + (o.by or 0))
  K.put(c, o.head or HEAD, X + (o.hx or 0), Y + (o.hy or 0))
  local hand = o.hand or { 12, 14 }
  local from = o.armFrom or { 11, 11 }
  local dir = hand[1] >= from[1] and 1 or -1
  c:line(X + from[1], Y + from[2], X + hand[1] - dir, Y + hand[2], C.P)
  c:set(X + hand[1], Y + hand[2], C.s)
  if o.point == true then c:set(X + hand[1] + dir, Y + hand[2], C.s)
  elseif o.point then c:set(X + hand[1] + o.point[1], Y + hand[2] + o.point[2], C.s) end
  if o.after then o.after(c, X, Y) end
  return c
end

-- golden shield: a crescent bulging toward the enemy. Outer edge = circle (cx, cy, r),
-- inner edge = a larger circle set back by d, so the arc is t px thick in the middle and
-- tapers to points; h clips its height while it grows. Shade on the inner (body-side) edge,
-- a white heart in the middle when `heart`, a glint travelling along the rim (k = frame).
local function shield(c, cx, cy, r, h, t, k, heart)
  local e = 3
  local d = t + e
  local function inside(x, y)
    local dx, dy = x - cx, y - cy
    if math.abs(dy) > h or dx < 0 then return false end
    local bx = dx + d
    return dx * dx + dy * dy <= (r + 0.4) ^ 2 and bx * bx + dy * dy > (r + e + 0.4) ^ 2
  end
  for y = cy - r - 1, cy + r + 1 do
    for x = cx, cx + r + 1 do
      if inside(x, y) then c:set(x, y, inside(x - 1, y) and C.G or C.g) end
    end
  end
  if heart then
    local hx = cx + r - t + 2
    K.put(c, K.art({ "W.W", "WWW", ".W." }, { W = "#f6ecee" }), hx, cy - 1)
  end
  local ang = math.rad(-50 + (k % 4) * 30)
  local gx, gy = K.round(cx + math.cos(ang) * (r + 1)), K.round(cy + math.sin(ang) * (r + 1))
  if math.abs(gy - cy) <= h then K.sparkle(c, gx, gy, MARK, k % 2) end
end

------------------------------------------------------------------ animation
local function draw(tag, i)
  if tag == "idle" then
    local P = {
      { },
      { hy = 1, body = BODY.idle, hand = { 12, 15 } },
      { hy = 1, body = BODY.idle2, head = HEAD_BLINK, hand = { 12, 15 } },
      { body = BODY.idle2, hand = { 12, 14 } },
    }
    return fig(P[i + 1])
  end

  if tag == "run" then
    local P = {
      { hx = 1, body = BODY.runA, legs = LEGS.r1, armFrom = { 9, 11 }, hand = { 13, 13 } },
      { hx = 1, oy = -1, body = BODY.runB, legs = LEGS.r2, armFrom = { 9, 11 }, hand = { 11, 14 } },
      { hx = 1, body = BODY.runA, legs = LEGS.r3, armFrom = { 9, 11 }, hand = { 8, 14 } },
      { hx = 1, oy = -1, body = BODY.runB, legs = LEGS.r4, armFrom = { 9, 11 }, hand = { 11, 14 } },
    }
    local c = fig(P[i + 1])
    if i == 0 or i == 2 then K.dust(c, OX + 4, 31, i) end
    return c
  end

  if tag == "attack" then
    -- draws herself up, then a sharp finger-point scolding with "!!"
    local P = {
      { hx = -1, hy = 1, body = BODY.crouch, legs = LEGS.wide, armFrom = { 11, 12 }, hand = { 13, 12 } },
      { hx = -1, head = HEAD_SHOUT, body = BODY.idle, legs = LEGS.wide, armFrom = { 11, 11 }, hand = { 14, 6 }, point = { 0, -1 } },
      { hx = 1, head = HEAD_SHOUT, body = BODY.runB, legs = LEGS.wide, armFrom = { 10, 11 }, hand = { 16, 11 }, point = true },
      { hx = 1, head = HEAD_SHOUT, body = BODY.runB, legs = LEGS.wide, armFrom = { 10, 11 }, hand = { 16, 10 }, point = true },
      { hx = 1, body = BODY.runB, legs = LEGS.wide, armFrom = { 10, 11 }, hand = { 14, 12 } },
      { body = BODY.idle2, hand = { 12, 15 } },
    }
    local c = fig(P[i + 1])
    local X, Y = OX, OY
    if i == 2 then
      K.bang(c, X + 19, Y + 4)
      c:line(X + 19, Y + 10, X + 20, Y + 10, MARK2)
    elseif i == 3 then
      K.bang(c, X + 20, Y + 3)
      c:line(X + 19, Y + 9, X + 21, Y + 8, MARK2); c:line(X + 19, Y + 12, X + 21, Y + 13, MARK2)
    end
    return c
  end

  if tag == "special" then
    -- braces, throws both hands forward and a golden shield arc swells up in front of her
    local R = { 0, 5, 7, 8, 8, 8, 8, 7 }
    local HT = { 0, 3, 6, 8, 8, 8, 7, 5 }
    local TH = { 0, 2, 4, 5, 5, 5, 4, 2 }
    local P = {
      { hy = 1, body = BODY.crouch, legs = LEGS.wide, armFrom = { 9, 11 }, hand = { 10, 12 } },
      { hx = 1, body = BODY.runB, legs = LEGS.wide, armFrom = { 10, 11 }, hand = { 15, 11 }, hand2 = { 13, 12 } },
      { hx = 1, body = BODY.runB, legs = LEGS.wide, armFrom = { 10, 11 }, hand = { 15, 11 }, hand2 = { 13, 12 } },
      { hx = 1, body = BODY.runB, legs = LEGS.wide, armFrom = { 10, 11 }, hand = { 15, 11 }, hand2 = { 13, 12 } },
      { hx = 1, hy = 1, body = BODY.runB, legs = LEGS.wide, armFrom = { 10, 11 }, hand = { 15, 11 }, hand2 = { 13, 12 } },
      { hx = 1, body = BODY.runB, legs = LEGS.wide, armFrom = { 10, 11 }, hand = { 15, 11 }, hand2 = { 13, 12 } },
      { hx = 1, hy = 1, head = HEAD_BLINK, body = BODY.runB, legs = LEGS.wide, armFrom = { 10, 11 }, hand = { 15, 11 }, hand2 = { 13, 12 } },
      { body = BODY.idle2, legs = LEGS.wide, armFrom = { 9, 11 }, hand = { 12, 13 } },
    }
    local p = P[i + 1]
    if R[i + 1] > 0 then
      p.after = function(c, X, Y) shield(c, X + 13, Y + 11, R[i + 1], HT[i + 1], TH[i + 1], i, i >= 3 and i <= 6) end
    end
    return fig(p)
  end

  local HURT = { hx = -1, head = HEAD_HURT, body = BODY.idle2, legs = LEGS.wide, armFrom = { 9, 11 }, hand = { 12, 9 } }
  if tag == "hit" then
    if i == 0 then return K.flashOf(fig(HURT)) end
    if i == 3 then return fig({ hy = 1, body = BODY.idle2, hand = { 12, 15 } }) end
    local s = i - 1
    local c = fig({ ox = -1 - s, hx = -1 - s, head = HEAD_HURT, body = BODY.idle2, legs = LEGS.wide,
                    armFrom = { 9, 11 }, hand = { 12, 9 + s } })
    K.bang(c, OX + 14 - s, OY - 1 + s)
    return c
  end

  if tag == "death" then
    if i == 0 then
      local c = fig(HURT); K.bang(c, OX + 14, OY - 1); return c
    end
    if i == 1 then
      return fig({ hx = -2, hy = 2, head = HEAD_HURT, body = BODY.crouch, legs = LEGS.wide, armFrom = { 9, 12 }, hand = { 13, 11 } })
    end
    if i == 2 then
      return fig({ ox = 1, hx = 1, hy = 5, by = 1, head = HEAD_HURT, body = BODY.crouch, legs = LEGS.wide, armFrom = { 9, 14 }, hand = { 14, 15 } })
    end
    -- flat on the ground: skirt on the left, head resting at the right
    local c = K.canvas()
    local dy = (i == 3) and -1 or 0
    K.foot(c, DOWN, 3, 31 + dy)
    K.foot(c, HEAD_HURT, 13, 31 + dy)
    if i == 3 then K.dust(c, 3, 31, 0); K.dust(c, 28, 31, 1) end
    if i >= 4 and i <= 6 then K.dizzy(c, 19, 14 - (i - 4), i) end
    return c
  end
end

return K.build("mother", draw)
