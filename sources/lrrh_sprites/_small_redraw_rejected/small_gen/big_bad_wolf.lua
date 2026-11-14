-- Big Bad Wolf at red-local scale (about 15 px tall sitting, like the game's Red at 18).
-- idle = sits upright, run = gallop, attack = lunge bite, special = leaping pounce with claw arcs.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local K = dofile(HERE .. "/kit.lua")

local MAP = {
  G = "#9a9ab6", g = "#5a5975", k = "#3a3850",   -- fur: rim light, base, shade
  c = "#efe0c6", C = "#bba68c",                  -- muzzle / chest / belly
  y = "#ffd23a", n = "#000000",                  -- eye, nose
  m = "#94031a", t = "#fd3150",                  -- mouth, tongue
  w = "#f6ecee",                                 -- teeth, claws (same white as the fx marks)
}
local function A(rows) return K.art(rows, MAP) end
local MARK, MARK2 = K.MARK, K.MARK2

------------------------------------------------------------------ heads (facing right)
local HEAD = A {
  "..k...G.....",
  ".kk..gG.....",
  ".kgGGGGGG...",
  "kgggggkkGG..",
  "kgggggykgGGn",
  "kgggggggcccc",
  "kggggccccC..",
}
local HEAD_BLINK = K.swap(HEAD, { y = "k" }, MAP)
local HEAD_EAR = A {   -- near ear flicked back
  "..k.........",
  ".kk.gG......",
  ".kgGGGGGG...",
  "kgggggkkGG..",
  "kgggggykgGGn",
  "kgggggggcccc",
  "kggggccccC..",
}
local HEAD_OPEN = A {  -- jaws wide for the bite
  "..k...G......",
  ".kk..gG......",
  ".kgGGGGGG....",
  "kgggggkkGGG..",
  "kgggggykgGGGn",
  "kggggggwmmw..",
  "kgggggmmmm...",
  "kggggcmmw.w..",
  ".kgcccccc....",
  "..kcccC......",
}
local HEAD_SNAP = A {  -- jaws shut after the bite, teeth showing
  "..k...G......",
  ".kk..gG......",
  ".kgGGGGGG....",
  "kgggggkkGGG..",
  "kgggggykgGGGn",
  "kgggggggwmwmw",
  "kggggcccccc..",
  ".kgcccC......",
}
local HEAD_HURT = A {
  "..k..........",
  ".kk..gG......",
  ".kgGGGGGG....",
  "kggggkggGG...",
  "kgggggkkgGGn.",
  "kgggggggmmcc.",
  "kggggcccmC...",
}
local HEAD_KO = A {    -- ears flat, eye shut, tongue lolling (lying on its side)
  "kGG..........",
  ".kgGGGGGG....",
  "kgggggggGG...",
  "kggggkkkgGGn.",
  "kgggggggmmcc.",
  "kggggcccmtt..",
  "........tt...",
}

------------------------------------------------------------------ sitting body (head sits on top at +9, -7)
local SIT = A {
  ".........kgggccc.....",
  "........GgggggcccG...",
  ".......GgggggkcccgG..",
  "......GggggggkccCgG..",
  "G...GGgggggggkkCcgG..",
  "GG.GgggggggggkkC.gG..",
  "gGGgggggggggkkkk.gG..",
  ".kkkkkkkkkkGGGk.kgGG.",
}
local SIT_TAIL = A {   -- tail tip lifted
  ".........kgggccc.....",
  "........GgggggcccG...",
  "G......GgggggkcccgG..",
  "GG....GggggggkccCgG..",
  ".gG.GGgggggggkkCcgG..",
  "..GGgggggggggkkC.gG..",
  "..ggggggggggkkkk.gG..",
  "..kkkkkkkkkGGGk.kgGG.",
}
local SIT_BREATH = A { -- chest out a pixel
  ".........kgggcccc....",
  "........GgggggccccG..",
  ".......GgggggkcccgG..",
  "......GggggggkccCgG..",
  "G...GGgggggggkkCcgG..",
  "GG.GgggggggggkkC.gG..",
  "gGGgggggggggkkkk.gG..",
  ".kkkkkkkkkkGGGk.kgGG.",
}

------------------------------------------------------------------ standing / running body
local TORSO = A {
  "..GGGGGGGGG..",
  ".GgggggggggGG",
  "Gggggggggggcc",
  "gggggggggkccc",
  "kgggkkkkgkccc",
  ".kkk....kkCc.",
}
local TAIL = {
  up = A { "GG...", "gGG..", ".ggGG", "..kkk" },
  back = A { "GGG..", "ggGGG", ".kkkk" },
  low = A { "...GG", "..gGg", ".gkk.", "kk..." },
}
-- legs: col 3 = torso col 0
local LEGS = {
  stand = A {
    "....kgG.....kgG....",
    "....kgG.....kgG....",
    "....kgG.....kgG....",
    "...kkgGG...kkgGG...",
  },
  crouch = A {
    "...kgG.....kgG.....",
    "..kgG.....kgGG.....",
    "..kkgGG..kkkgGG....",
  },
  r1 = A {   -- stretched out
    "...kgg......kgG....",
    "..kgg........kgG...",
    ".kgG..........kgG..",
    "kgG............kgG.",
  },
  r2 = A {   -- front legs strike, hind legs swing in
    "....kgg.....kgG....",
    ".....kgg....kgG....",
    "......kgG...kgG....",
    "...........kkgGG...",
  },
  r3 = A {   -- gathered under the body
    ".....kgG..kgG......",
    "......kgGkgG.......",
    ".......kgGgG.......",
    "......kkgGGG.......",
  },
  claw = A {   -- front paws out, claws first
    "...kgg.......kgG...",
    "..kgg.........kgG..",
    ".kgG...........kgGw",
    "kgG.............w.w",
  },
  r4 = A {   -- hind legs push, front legs reach
    "...kgG.......kgG...",
    "...kgG........kgG..",
    "..kgG..........kG..",
    ".kkgGG.............",
  },
}

------------------------------------------------------------------ lying on its side (death)
local DOWN = A {
  ".......GGGGGGGG.......",
  ".....GGggggggggGG.....",
  "...GGggggggggggggG....",
  "GGGgggggggggggggggc...",
  "gggggggggggggggcccc...",
  ".kkkkCcccccccccccC....",
  "...kgG.kgG...kgG.kgG..",
  "..kgG.kgG.....kgG.kgG.",
}

------------------------------------------------------------------ figure builders
local BX = 6          -- sitting figure left edge
local function sit(o)
  local c = K.canvas()
  K.foot(c, o.body or SIT, BX + (o.ox or 0), 31 + (o.oy or 0))
  K.put(c, o.head or HEAD, BX + 9 + (o.ox or 0) + (o.hx or 0), 17 + (o.oy or 0) + (o.hy or 0))
  return c
end

-- quadruped: torso left edge at x; legs hang from the torso bottom, feet on the ground
-- unless lifted (lift > 0 = airborne); head at torso col 7
local function quad(o)
  local c = K.canvas()
  local legs = o.legs or LEGS.stand
  local x = o.x or 7
  local y = 32 - legs.h - TORSO.h - (o.lift or 0)
  local tail = o.tail or TAIL.back
  K.put(c, tail, x - tail.w + 2 + (o.tx or 0), y + (o.ty or 0))
  K.put(c, legs, x - 3, y + TORSO.h)
  K.put(c, o.torso or TORSO, x, y)
  K.put(c, o.head or HEAD, x + 7 + (o.hx or 0), y - 4 + (o.hy or 0))
  return c, x, y
end

-- three claw rakes, top-left at (x, y)
local CLAW = { "#..#..#..", ".#..#..#.", ".#..#..#.", "..#..#..#" }
local function claws(c, x, y, col)
  for j, row in ipairs(CLAW) do
    for i = 1, #row do if row:sub(i, i) == "#" then c:set(x + i - 1, y + j - 1, col) end end
  end
end

------------------------------------------------------------------ animation
local function draw(tag, i)
  if tag == "idle" then
    local P = {
      { },
      { body = SIT_BREATH, hy = 1 },
      { body = SIT_BREATH, hy = 1, head = HEAD_BLINK },
      { body = SIT_TAIL, head = HEAD_EAR },
    }
    return sit(P[i + 1])
  end

  if tag == "run" then
    local P = {
      { x = 8, lift = 1, legs = LEGS.r1, tail = TAIL.back },
      { x = 8, legs = LEGS.r2, tail = TAIL.low, hy = 1 },
      { x = 8, lift = 1, legs = LEGS.r3, tail = TAIL.up },
      { x = 8, legs = LEGS.r4, tail = TAIL.back, hy = -1 },
    }
    local c = quad(P[i + 1])
    if i == 1 then K.dust(c, 18, 31, 0) elseif i == 3 then K.dust(c, 6, 31, 1) end
    return c
  end

  if tag == "attack" then
    local P = {
      { x = 7, legs = LEGS.crouch, hy = 1, tail = TAIL.low },
      { x = 5, legs = LEGS.crouch, head = HEAD_OPEN, hy = -1, tail = TAIL.low },
      { x = 10, legs = LEGS.r1, head = HEAD_OPEN, hy = -1, tail = TAIL.back },
      { x = 11, legs = LEGS.r1, head = HEAD_SNAP, tail = TAIL.back },
      { x = 9, legs = LEGS.stand, head = HEAD_SNAP, tail = TAIL.up },
      { x = 7, legs = LEGS.stand, tail = TAIL.up },
    }
    local c = quad(P[i + 1])
    if i == 2 then
      c:curve(26, 17, 31, 21, 28, 27, MARK, nil, 10)
    elseif i == 3 then
      K.bang(c, 29, 15)
    end
    return c
  end

  if tag == "special" then
    local P = {
      { x = 7, legs = LEGS.crouch, hy = 1, tail = TAIL.low },
      { x = 6, legs = LEGS.crouch, lift = -1, hy = 1, tail = TAIL.up },
      { x = 7, legs = LEGS.r4, lift = 4, hy = -1, tail = TAIL.low },
      { x = 8, legs = LEGS.r1, lift = 8, head = HEAD_OPEN, hy = -1, tail = TAIL.back },
      { x = 9, legs = LEGS.claw, lift = 5, head = HEAD_OPEN, tail = TAIL.up },
      { x = 10, legs = LEGS.r2, head = HEAD_SNAP, tail = TAIL.up },
      { x = 10, legs = LEGS.crouch, head = HEAD_SNAP, hy = 1, tail = TAIL.low },
      { x = 8, legs = LEGS.stand, tail = TAIL.back },
    }
    local c = quad(P[i + 1])
    if i == 4 then
      claws(c, 22, 22, MARK)
    elseif i == 5 then
      claws(c, 23, 25, MARK2)
      K.bang(c, 29, 16)
    elseif i == 6 then
      K.dust(c, 8, 31, 0); K.dust(c, 25, 31, 1)
    end
    return c
  end

  local HURT = { x = 6, legs = LEGS.stand, head = HEAD_HURT, hy = -1, tail = TAIL.low }
  if tag == "hit" then
    if i == 0 then return K.flashOf(quad(HURT)) end
    if i == 3 then return quad({ x = 7, legs = LEGS.stand }) end
    local c = quad({ x = 6 - (i - 1), legs = LEGS.stand, head = HEAD_HURT, hy = -1 + (i - 1), tail = TAIL.low })
    K.bang(c, 27 - (i - 1), 15 + (i - 1))
    return c
  end

  if tag == "death" then
    if i == 0 then
      local c = quad(HURT); K.bang(c, 27, 15); return c
    end
    if i == 1 then return quad({ x = 6, legs = LEGS.crouch, head = HEAD_HURT, hy = 1, tail = TAIL.low }) end
    if i == 2 then return quad({ x = 6, legs = LEGS.crouch, lift = -1, head = HEAD_KO, hy = 3, tail = TAIL.low }) end
    local c = K.canvas()
    local dy = (i == 3) and -1 or 0
    K.foot(c, DOWN, 3, 31 + dy)
    K.foot(c, HEAD_KO, 18, 30 + dy)
    if i == 3 then K.dust(c, 5, 31, 0); K.dust(c, 27, 31, 1) end
    if i >= 4 and i <= 6 then K.dizzy(c, 22, 16 - (i - 4), i) end
    return c
  end
end

return K.build("big_bad_wolf", draw)
