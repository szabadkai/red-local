-- Little Red Riding Hood at red-local scale (18 px tall, like the game's Red).
-- attack = basket swing, special = cape dash.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local K = dofile(HERE .. "/kit.lua")

local MAP = {
  R = "#fd3150", r = "#94031a",                 -- hood / cape
  h = "#3b1f2b",                                -- hair, far leg
  s = "#ffeec8", b = "#ff9f89", o = "#ffeec8",  -- skin, blush, mouth (skin until opened)
  E = "#000000", e = "#000000",                 -- eye top / eye bottom, near leg
  d = "#fffff2", D = "#b2af9a",                 -- dress
  k = "#d08a48", K = "#8a4a2a",                 -- basket
}
local function A(rows) return K.art(rows, MAP) end
local SKIN, DRESS, MARK, MARK2 = K.rgb(MAP.s), K.rgb(MAP.d), K.MARK, K.MARK2

------------------------------------------------------------------ parts (16 cols wide)
local HEAD = A {
  "......RRRRR.....",
  "....RRRRRRRRR...",
  "..RRRRRRRRRRRRR.",
  ".rRRRRRRRhhhhhR.",
  ".rRRRRRRhhhhhhhR",
  ".rRRRRRRhhhhhshR",
  ".rRRRRRRhsEssEsh",
  ".rRRRRRRhsessesh",
  ".rrRRRRRhbssssbh",
  "..rrRRRRRrssoss.",
}
local HEAD_BLINK = K.swap(HEAD, { E = "s" }, MAP)
local HEAD_HURT = K.swap(HEAD, { E = "s", e = "h", o = "r" }, MAP)

local BODY = {
  idle = A {
    "..rrRRRRRRrrRR..",
    "..rrRRRRRddddR..",
    "..rrRRRRdddddd..",
    ".rrRRRRRdddddd..",
    ".rrRRRRDdddddd..",
    "rrRRRRRDdddddd..",
  },
  idle2 = A {   -- hem swings a pixel
    "..rrRRRRRRrrRR..",
    "..rrRRRRRddddR..",
    "..rrRRRRdddddd..",
    "..rRRRRRdddddd..",
    ".rrRRRRDdddddd..",
    ".rRRRRRDdddddd..",
  },
  runA = A {    -- cape blown back
    ".rrRRRRRRRrrRR..",
    "rrRRRRRRRddddR..",
    "RRRRRRRRdddddd..",
    "rrRRRRRRdddddd..",
    "..rrRRRDdddddd..",
    "....rrRDdddddd..",
  },
  runB = A {
    "..rrRRRRRRrrRR..",
    "rrRRRRRRRddddR..",
    "rRRRRRRRdddddd..",
    ".rrRRRRRdddddd..",
    "...rrRRDdddddd..",
    ".....rRDdddddd..",
  },
  dash = A {    -- cape streaming straight back
    "rrrRRRRRRRrrRR..",
    "RRRRRRRRRddddR..",
    "rrRRRRRRdddddd..",
    "..rrrRRRdddddd..",
    ".....rRDdddddd..",
    ".......Dddddd...",
  },
  crouch = A {  -- squashed for anticipation / landing
    "..rrRRRRRRrrRR..",
    ".rrRRRRRRddddR..",
    ".rrRRRRRdddddd..",
    "rrRRRRRDdddddd..",
    "rRRRRRRDdddddd..",
  },
}
local LEGS = {
  stand = A { "........hh.ee...", ".......hhh.eee.." },
  r1 = A { ".......hh...ee..", "......hh.....ee." },   -- near leg forward
  r2 = A { ".........hhee...", "..........eee..." },   -- passing, far leg lifted
  r3 = A { ".......ee...hh..", "......ee.....hh." },   -- far leg forward
  r4 = A { ".........eehh...", "..........hhh..." },   -- passing, near leg lifted
  wide = A { "......hh....ee..", ".....hh......ee." },  -- braced
}
local BASKET = A { ".KK.", "kRRk", "KkkK" }
local DOWN = A {  -- flat on her front, head up, cape over the body (head drawn separately)
  "......rrRRRRRR",
  "....rrRRRRRRRR",
  "hh.rrRRRRRRRRR",
  "hhhdDrrRRRRRRR",
  "eeeDDDdrrrRRRR",
}

------------------------------------------------------------------ figure
local OX, OY = 8, 14   -- top-left of the 16x18 figure box when standing (feet on y = 31)
-- o: ox, oy (whole figure), hx, hy (head offset), head, body, legs,
--    hand = {x, y} (front hand, figure coords), basket = {x, y} or false, armFrom = {x, y}
local function fig(o)
  local c = K.canvas()
  local X, Y = OX + (o.ox or 0), OY + (o.oy or 0)
  local body = o.body or BODY.idle
  K.put(c, o.legs or LEGS.stand, X, Y + 16)
  K.put(c, body, X, Y + 16 - body.h + (o.by or 0))
  K.put(c, o.head or HEAD, X + (o.hx or 0), Y + (o.hy or 0))
  local hand = o.hand or { 13, 12 }
  local from = o.armFrom or { 12, 11 }
  c:line(X + from[1], Y + from[2], X + hand[1] - (hand[1] >= from[1] and 1 or -1), Y + hand[2], DRESS)
  c:set(X + hand[1], Y + hand[2], SKIN)
  if o.basket ~= false then
    local b = o.basket or { 12, 13 }
    K.put(c, BASKET, X + b[1], Y + b[2])
  end
  return c
end

------------------------------------------------------------------ animation
local function draw(tag, i)
  if tag == "idle" then
    local P = {
      { },
      { hy = 1, body = BODY.idle },
      { hy = 1, body = BODY.idle2, head = HEAD_BLINK },
      { body = BODY.idle2, hand = { 13, 12 }, basket = { 12, 13 } },
    }
    return fig(P[i + 1])
  end

  if tag == "run" then
    local P = {
      { hx = 1, body = BODY.runA, legs = LEGS.r1, hand = { 14, 11 }, basket = { 13, 12 } },
      { hx = 1, oy = -1, body = BODY.runB, legs = LEGS.r2, hand = { 13, 12 }, basket = { 12, 13 } },
      { hx = 1, body = BODY.runA, legs = LEGS.r3, hand = { 12, 12 }, basket = { 10, 13 } },
      { hx = 1, oy = -1, body = BODY.runB, legs = LEGS.r4, hand = { 13, 12 }, basket = { 12, 13 } },
    }
    local c = fig(P[i + 1])
    if i == 0 or i == 2 then K.dust(c, OX + 5, 31, i) end
    return c
  end

  if tag == "attack" then
    -- wind up behind, swing over, basket thrust forward with a swoosh, settle
    local P = {
      { hx = -1, hy = 1, body = BODY.crouch, legs = LEGS.wide, armFrom = { 9, 11 }, hand = { 5, 11 }, basket = { 2, 10 } },
      { hx = -1, body = BODY.idle, legs = LEGS.wide, armFrom = { 10, 10 }, hand = { 8, 8 }, basket = { 6, 5 } },
      { hx = 2, body = BODY.runA, legs = LEGS.wide, armFrom = { 12, 11 }, hand = { 16, 10 }, basket = { 17, 9 } },
      { hx = 2, body = BODY.runA, legs = LEGS.wide, armFrom = { 12, 11 }, hand = { 16, 11 }, basket = { 17, 11 } },
      { hx = 1, body = BODY.runB, legs = LEGS.wide, armFrom = { 12, 11 }, hand = { 15, 12 }, basket = { 14, 13 } },
      { body = BODY.idle2 },
    }
    local c = fig(P[i + 1])
    local X, Y = OX, OY
    if i == 2 then
      c:curve(X + 6, Y + 3, X + 15, Y - 3, X + 22, Y + 8, MARK)
      c:curve(X + 8, Y + 4, X + 15, Y, X + 21, Y + 9, MARK2)
    elseif i == 3 then
      c:curve(X + 13, Y - 1, X + 22, Y + 1, X + 22, Y + 11, MARK2)
      K.bang(c, X + 22, Y + 4)
    end
    return c
  end

  if tag == "special" then
    -- crouch, then a dash with the cape streaming, then brake
    local P = {
      { hy = 2, body = BODY.crouch, legs = LEGS.stand },
      { hx = 1, hy = 2, body = BODY.crouch, legs = LEGS.wide },
      { ox = 1, hx = 2, hy = 1, body = BODY.dash, legs = LEGS.r1, hand = { 13, 12 }, basket = { 11, 13 } },
      { ox = 2, hx = 2, hy = 1, body = BODY.dash, legs = LEGS.r3, hand = { 13, 12 }, basket = { 11, 13 } },
      { ox = 3, hx = 2, hy = 1, body = BODY.dash, legs = LEGS.r1, hand = { 13, 12 }, basket = { 11, 13 } },
      { ox = 3, hx = 2, hy = 1, body = BODY.dash, legs = LEGS.r3, hand = { 13, 12 }, basket = { 11, 13 } },
      { ox = 3, hx = -1, hy = 1, body = BODY.runB, legs = LEGS.wide },
      { ox = 1, body = BODY.idle2 },
    }
    local c = fig(P[i + 1])
    if i >= 2 and i <= 5 then
      local x = OX + (P[i + 1].ox or 0) - 1
      K.speed(c, x, OY + 9 + (i % 2), 3, 4 + i % 2 * 2, MARK, i)
    elseif i == 6 then
      K.dust(c, OX + 16, 31, 0); K.dust(c, OX + 9, 31, 1)
    end
    return c
  end

  local HURT = { hx = -1, head = HEAD_HURT, body = BODY.idle2, legs = LEGS.wide, armFrom = { 11, 11 }, hand = { 14, 9 }, basket = { 14, 13 } }
  if tag == "hit" then
    if i == 0 then return K.flashOf(fig(HURT)) end
    if i == 3 then return fig({ hy = 1, body = BODY.idle2 }) end
    local c = fig({ hx = -1 - (i - 1), ox = -(i - 1), head = HEAD_HURT, body = BODY.idle2, legs = LEGS.wide,
                    armFrom = { 11, 11 }, hand = { 14, 9 }, basket = { 14, 13 } })
    K.bang(c, OX + 16 - (i - 1), OY - 1 + (i - 1))
    return c
  end

  if tag == "death" then
    if i == 0 then
      local c = fig(HURT); K.bang(c, OX + 16, OY - 1); return c
    end
    if i == 1 then
      return fig({ hx = -2, hy = 2, head = HEAD_HURT, body = BODY.crouch, legs = LEGS.wide, armFrom = { 11, 12 }, hand = { 15, 11 }, basket = { 18, 9 } })
    end
    if i == 2 then
      return fig({ ox = 1, hx = 1, hy = 4, head = HEAD_HURT, body = BODY.crouch, legs = LEGS.wide, hand = { 15, 13 }, basket = { 19, 12 } })
    end
    -- flat on the ground: cape heap on the left, head resting at the right, basket rolled away
    local c = K.canvas()
    local dy = (i == 3) and -1 or 0
    K.foot(c, DOWN, 4, 31 + dy)
    K.foot(c, HEAD_HURT, 11, 31 + dy)
    K.put(c, BASKET, 27, 29)
    if i == 3 then K.dust(c, 4, 31, 0); K.dust(c, 28, 28, 1) end
    if i >= 4 and i <= 6 then K.dizzy(c, 18, 15 - (i - 4), i) end
    return c
  end
end

return K.build("little_red_riding_hood", draw)
