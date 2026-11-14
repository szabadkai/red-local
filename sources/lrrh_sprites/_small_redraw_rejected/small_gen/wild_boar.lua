-- Wild boar at red-local scale (about 12 px tall x 20 long, next to Red at 18).
-- "Charging brute - Tough / Charge / Knockback".
-- idle = stands snorting, run = trot, attack = tusk gore, special = hoof scrape then a charge with dust.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local K = dofile(HERE .. "/kit.lua")

local MAP = {
  B = "#a8623a", b = "#6b3a26",                  -- hide: base, shade
  m = "#45261e",                                 -- bristle mane, far legs, hooves
  p = "#ff9f89", P = "#d0646a",                  -- snout
  t = "#fffff2", T = "#b2af9a",                  -- tusks
  e = "#000000",                                 -- eye
}
local function A(rows) return K.art(rows, MAP) end
local MARK, MARK2 = K.MARK, K.MARK2

------------------------------------------------------------------ heads (facing right)
local HEAD = A {
  "..mB......",
  ".mBB......",
  "bbBBBBB...",
  "bbBBeBBB..",
  "bBBBBBBBBp",
  "bbBBBBBBPp",
  "bbbBBBtb..",
  ".bbbbtt...",
}
local HEAD_BLINK = K.swap(HEAD, { e = "b" }, MAP)
local HEAD_UP = A {    -- gore: snout tossed up, tusk sweeping
  "........pp",
  "..mB...BPp",
  ".mBB..BBBt",
  "bbBBBBBBtt",
  "bbBBeBBBb.",
  "bBBBBBBb..",
  "bbBBBBbb..",
  ".bbbbbb...",
}
local HEAD_LOW = A {   -- head down, tusks first
  "..........",
  "..mB......",
  ".mBBBB....",
  "bbBBeBBB..",
  "bbBBBBBBB.",
  "bbbBBBBBtp",
  ".bbbBBBtPp",
  "..bbbbb...",
}
local HEAD_HURT = A {
  ".mB.......",
  "mBB.......",
  "bbBBBBB...",
  "bbBbbBBB..",
  "bBBBBBBBBp",
  "bbBBBBBBPp",
  "bbbBBBtb..",
  ".bbbbtt...",
}
local HEAD_KO = K.swap(HEAD_HURT, {}, MAP)

------------------------------------------------------------------ body
local TORSO = A {
  "........m.m..",
  ".....m.m.mmm.",
  "...m.mmmmmmmm",
  "..mmmmmmmmmmm",
  ".bBBBBBBBBBBB",
  "bbBBBBBBBBBBB",
  "bbBBBbBBBBBBB",
  "bbbBBbbBBBBBB",
  ".bbbbbbbbbbbb",
}
local TORSO_UP = A {   -- bristles raised for the charge
  ".......m.m.m.",
  "...m.m.mmmmm.",
  ".m.mmmmmmmmmm",
  ".mmmmmmmmmmmm",
  ".bBBBBBBBBBBB",
  "bbBBBBBBBBBBB",
  "bbBBBbBBBBBBB",
  "bbbBBbbBBBBBB",
  ".bbbbbbbbbbbb",
}
local TAIL = { down = A { "m.", "bm", ".b" }, up = A { "m.", ".m", ".b" }, flick = A { "..", "mm", ".b" } }
-- legs: col 0 = torso col 0. far legs dark (m), near legs lit (bB)
local LEGS = {
  stand = A {
    "mb.bB..mb.bB",
    "mb.bB..mb.bB",
    "mm.mm..mm.mm",
  },
  t1 = A {   -- near front + far hind reach, the other pair planted
    ".mb.bB..mb..bB",
    "mb..bB..mb...bB",
    "mm..mm..mm....mm",
  },
  t2 = A {   -- passing
    ".mbbB...mbbB",
    ".mbbB...mbbB",
    ".mmmm...mmmm",
  },
  t3 = A {   -- far front + near hind reach
    "..bBmb...bB.mb",
    ".bB..mb..bB..mb",
    "mm....mm.mm...mm",
  },
  scrape = A {   -- near front hoof dragged back
    "mb.bB..mbbB.",
    "mb.bB..mbB..",
    "mm.mm..mmm..",
  },
  brace = A {    -- front legs planted forward
    "mb.bB...mb.bB.",
    "mb.bB....mb.bB",
    "mm.mm....mm.mm",
  },
  stretch = A {  -- charge: legs flung out
    ".mbbB.....mbbB.",
    "mb..bB.....mb.bB",
    "m.....m.....m..m",
  },
  bunch = A {    -- charge: legs gathered
    "..mbbB.mbbB.",
    "...mbB.mbB..",
    "...mmmmmm...",
  },
}

------------------------------------------------------------------ lying on its side (death)
local DOWN = A {
  "......m.m.m.mm.....",
  "...m.mmmmmmmmmm....",
  ".mmmmmmmmmmmmmmB...",
  "bBBBBBBBBBBBBBBBB..",
  "bbBBBBBBBBBBBBBBB..",
  "bbbbbBBBBBBBBBBbb..",
  ".bbbbbbbbbbbbbbb...",
  "...bB.bB...bB.bB...",
  "..mm.mm....mm.mm...",
}

------------------------------------------------------------------ figure
-- torso left edge at x; feet on the ground unless lifted; head at torso col 10
local function quad(o)
  local c = K.canvas()
  local legs = o.legs or LEGS.stand
  local torso = o.torso or TORSO
  local x = o.x or 6
  local y = 32 - legs.h - torso.h - (o.lift or 0)
  K.put(c, o.tail or TAIL.down, x - 1, y + 4)
  K.put(c, legs, x, y + torso.h)
  K.put(c, torso, x, y)
  K.put(c, o.head or HEAD, x + 10 + (o.hx or 0), y + 1 + (o.hy or 0))
  return c
end
local function puff(c, x, y, k)   -- snort / dust puff, 3-4 px
  c:set(x, y, MARK2); c:set(x + 1, y, MARK2); c:set(x + (k % 2), y - 1, MARK2)
  if k % 2 == 0 then c:set(x - 1, y + 1, MARK2) end
end

------------------------------------------------------------------ animation
local function draw(tag, i)
  if tag == "idle" then
    local P = {
      { },
      { hy = 1, tail = TAIL.flick },
      { hy = 1, head = HEAD_BLINK, tail = TAIL.flick },
      { tail = TAIL.up },
    }
    local c = quad(P[i + 1])
    if i == 1 then puff(c, 27, 27, 0) elseif i == 2 then puff(c, 28, 26, 1) end
    return c
  end

  if tag == "run" then
    local P = {
      { legs = LEGS.t1, hy = 1 },
      { legs = LEGS.t2, lift = 1, tail = TAIL.up },
      { legs = LEGS.t3, hy = 1 },
      { legs = LEGS.t2, lift = 1, tail = TAIL.up },
    }
    local c = quad(P[i + 1])
    if i == 0 then K.dust(c, 5, 31, 0) elseif i == 2 then K.dust(c, 6, 31, 1) end
    return c
  end

  if tag == "attack" then
    local P = {
      { head = HEAD_LOW, hy = 1, legs = LEGS.brace },
      { x = 5, head = HEAD_LOW, hy = 2, legs = LEGS.brace, torso = TORSO_UP },
      { x = 8, hy = -2, head = HEAD_UP, legs = LEGS.t1, torso = TORSO_UP, tail = TAIL.up },
      { x = 8, hy = -2, head = HEAD_UP, legs = LEGS.stand, torso = TORSO_UP, tail = TAIL.up },
      { x = 7, hy = 1, legs = LEGS.stand },
      { x = 6 },
    }
    local c = quad(P[i + 1])
    if i == 2 then
      c:curve(27, 29, 31, 24, 27, 16, MARK, nil, 12)
    elseif i == 3 then
      c:curve(28, 25, 30, 20, 26, 16, MARK2, nil, 10)
      K.bang(c, 29, 12)
    end
    return c
  end

  if tag == "special" then
    local P = {
      { head = HEAD_LOW, hy = 1, legs = LEGS.scrape },
      { head = HEAD_LOW, hy = 1, legs = LEGS.stand, torso = TORSO_UP },
      { head = HEAD_LOW, hy = 1, legs = LEGS.scrape, torso = TORSO_UP },
      { x = 7, head = HEAD_LOW, hy = 1, legs = LEGS.stretch, torso = TORSO_UP, tail = TAIL.up },
      { x = 8, head = HEAD_LOW, lift = 1, legs = LEGS.bunch, torso = TORSO_UP, tail = TAIL.up },
      { x = 9, head = HEAD_LOW, hy = 1, legs = LEGS.stretch, torso = TORSO_UP, tail = TAIL.up },
      { x = 9, hy = -1, legs = LEGS.brace },
      { x = 8 },
    }
    local c = quad(P[i + 1])
    if i == 0 or i == 2 then
      puff(c, 15, 30, i); K.dust(c, 13, 31, i)
    elseif i >= 3 and i <= 5 then
      local x = P[i + 1].x
      K.speed(c, x - 2, 21 + (i % 2), 2, 4 + (i % 2) * 2, MARK, i)
      puff(c, x - 1, 30, i); puff(c, x - 4, 29, i + 1)
    elseif i == 6 then
      puff(c, 26, 30, 0); K.dust(c, 28, 31, 1)
    end
    return c
  end

  local HURT = { x = 5, hy = -1, head = HEAD_HURT, legs = LEGS.brace, tail = TAIL.up }
  if tag == "hit" then
    if i == 0 then return K.flashOf(quad(HURT)) end
    if i == 3 then return quad({ x = 6, hy = 1 }) end
    local c = quad({ x = 5 - (i - 1), hy = -1 + (i - 1), head = HEAD_HURT, legs = LEGS.brace, tail = TAIL.up })
    K.bang(c, 26 - (i - 1), 15 + (i - 1))
    return c
  end

  if tag == "death" then
    if i == 0 then
      local c = quad(HURT); K.bang(c, 26, 15); return c
    end
    if i == 1 then return quad({ x = 5, hy = 1, head = HEAD_HURT, legs = LEGS.t2 }) end
    if i == 2 then return quad({ x = 5, hy = 2, lift = -1, head = HEAD_KO, legs = LEGS.bunch }) end
    local c = K.canvas()
    local dy = (i == 3) and -1 or 0
    K.foot(c, DOWN, 4, 31 + dy)
    K.foot(c, HEAD_KO, 18, 30 + dy)
    if i == 3 then K.dust(c, 4, 31, 0); K.dust(c, 27, 31, 1) end
    if i >= 4 and i <= 6 then K.dizzy(c, 20, 15 - (i - 4), i) end
    return c
  end
end

return K.build("wild_boar", draw)
