-- Wolf in disguise at red-local scale (20 px tall, hunched): a grey wolf in grandma's
-- frilly bonnet (ears poking through), purple shawl over the hunched back, tail giving
-- the game away. attack = lunging bite, special = drops the act and roars, shredding
-- the shawl.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local K = dofile(HERE .. "/kit.lua")

local MAP = {
  B = "#f8ecef", b = "#c9a9c0",                 -- bonnet, frill
  F = "#a9a5c0", f = "#59526f",                 -- fur
  E = "#000000", e = "#000000", N = "#000000",  -- eye top / eye bottom, nose
  S = "#b44fa2", s = "#62205d",                 -- shawl
  M = "#c22b44",                                -- open mouth
  w = "#f6ecee",                                -- fangs (same white as the marks)
}
local function A(rows) return K.art(rows, MAP) end
local COL = {}
for k, v in pairs(MAP) do COL[k] = K.rgb(v) end

------------------------------------------------------------------ parts
-- head: 19 cols x 11 rows. A small lacy cap over the crown and the back of the head
-- (ears through it), grey forehead / brow / cheek, long snout, ribbon tie under the jaw
local HEAD = A {
  "......f..fF........",
  "......ff.fFF.......",
  "...bBBffBfFFb......",
  "..bBBBBBBBBBBbF....",
  ".bBBBBBBBBBBbFFF...",
  ".bbBBBBBBBBbFFFFF..",
  ".bbBBBBBBbBfFffFF..",
  ".bbBBBBbBfFFFEFFFNN",
  "..bBbBbBfFFFFeFFFFF",
  "...fffFFFFFfffffff.",
  "..........SS.......",
}
local HEAD_BLINK = K.swap(HEAD, { E = "F" }, MAP)
local HEAD_HURT = K.swap(HEAD, { E = "F", e = "f" }, MAP)
local HEAD_OPEN = A {   -- jaws wide (bite)
  "......f..fF........",
  "......ff.fFF.......",
  "...bBBffBfFFb......",
  "..bBBBBBBBBBBbF....",
  ".bBBBBBBBBBBbFFF...",
  ".bbBBBBBBBBbFFFFF..",
  ".bbBBBBBBbBfFffFFNN",
  ".bbBBBBbBfFFFEFwFw.",
  "..bBbBbBfFFFFeMMMM.",
  "...fffFFFFFffwfwff.",
  "..........SS.......",
}
-- act dropped: cap shoved back off the crown, ears straight up, brow down
local HEAD_WILD = A {
  ".......f..fF.......",
  ".......ff.fF.......",
  "......fff.fFF......",
  "..bBBBffFFFFFF.....",
  ".bBBBBBfFFFFFFF....",
  ".bbBBBBbFFFFFFFF...",
  ".bbBBBBbFFFFffFF...",
  ".bbBBBbBfFFFFEFFFNN",
  "..bBbBbffFFFFeFFFFF",
  "...fffFFFFFfffffff.",
  "..........SS.......",
}
local HEAD_WILD_OPEN = A {
  ".......f..fF.......",
  ".......ff.fF.......",
  "......fff.fFF......",
  "..bBBBffFFFFFF.....",
  ".bBBBBBfFFFFFFF....",
  ".bbBBBBbFFFFFFFF...",
  ".bbBBBBbFFFFffFFFNN",
  ".bbBBBbBfFFFFEFwFw.",
  "..bBbBbffFFFFeMMMM.",
  "...fffFFFFFffwfwff.",
  "..........SS.......",
}

-- shawl over the hunched back (16 cols, 7 rows; the hump rises behind the neck)
local BODY = {
  idle = A {
    "..ssSSSS........",
    ".sSSSSSSSSSS....",
    "sSSSSSSSSSSSSS..",
    "sSSSSSSSSSSSSSS.",
    ".sSSSSSSSSSSSSS.",
    "..sSSSSSSSSSSSs.",
    "...sss.ssss.ss..",
  },
  idle2 = A {   -- fringe sways
    "..ssSSSS........",
    ".sSSSSSSSSSS....",
    "sSSSSSSSSSSSSS..",
    "sSSSSSSSSSSSSSS.",
    "ssSSSSSSSSSSSSS.",
    ".ssSSSSSSSSSSs..",
    "..sss.ssss.ss...",
  },
  runA = A {    -- shawl streaming back
    "..ssSSSS........",
    "ssSSSSSSSSSS....",
    "sSSSSSSSSSSSSS..",
    "..sSSSSSSSSSSSS.",
    "....ssSSSSSSSSs.",
    ".....sSSSSSSSs..",
    "......sss.sss...",
  },
  runB = A {
    "..ssSSSS........",
    ".ssSSSSSSSSS....",
    "ssSSSSSSSSSSSS..",
    "sSSSSSSSSSSSSSS.",
    ".ssSSSSSSSSSSSS.",
    "...ssSSSSSSSSs..",
    ".....sss.sss....",
  },
  crouch = A {  -- squashed: wind-up / slump
    ".sssSSSSS.......",
    "sSSSSSSSSSSSSS..",
    "sSSSSSSSSSSSSSS.",
    "ssSSSSSSSSSSSSs.",
    ".sSSSSSSSSSSSs..",
    ".sss.ssss.sss...",
  },
  flare = A {   -- shawl flung open by the roar, grey belly showing
    "..ssSSSS........",
    "ssSSSSSSSSSSSS..",
    "sSSSSSSSSSSSSSS.",
    "sSSSSSSffFFFSSS.",
    ".sSSSSffFFFFFSs.",
    "..ssSsffFFFFs...",
    "....s.ff.FF.....",
  },
}
local LEGS = {
  stand = A { ".....ff...FF....", ".....ff...FF....", "....fff..FFF...." },
  r1 = A { "......ff..FF....", ".....ff....FF...", "...fff......FFF." },  -- near leg forward
  r2 = A { "......ffFF......", "....fff.FF......", "........FFF....." },  -- passing, far leg lifted
  r3 = A { "......FF..ff....", ".....FF....ff...", "...FFF......fff." },  -- far leg forward
  r4 = A { "......FFff......", "....FFF.ff......", "........fff....." },  -- passing, near leg lifted
  wide = A { ".....ff....FF...", "....ff......FF..", "...fff......FFF." }, -- braced
}
-- bushy tail poking out from under the shawl at the back
local TAIL = {
  down = A { "FF..", "fFF.", ".ff." },
  up = A { "FF..", "FFf.", ".fF." },
  wag = A { "....", "FFFf", ".fff" },
}
-- flat on its belly: tail and hind legs out the back, shawl heaped over it (head separate)
local DOWN = A {
  ".........sSSSSSS",
  "......ssSSSSSSSS",
  "FF..ssSSSSSSSSSS",
  "fFFsSSSSSSSSSSSS",
  ".ffsssSSSSSSSSss",
  "...ffFF.ff......",
}
local SCRAP = { A { "S.", "sS" }, A { "Ss", ".S" }, A { ".S", "Ss" } }

------------------------------------------------------------------ figure
local OX, OY = 3, 12   -- top-left of the 23x20 figure box when standing (feet on y = 31)
local HX = 4           -- head column inside the box (jutting forward of the shawl)
-- o: ox, oy, hx, hy (head offset), head, body, by, legs, tail, tailAt = {x, y},
--    paw = {x, y} front paw (figure coords) or false, armFrom = {x, y}
local function fig(o)
  local c = K.canvas()
  local X, Y = OX + (o.ox or 0), OY + (o.oy or 0)
  local legs, body = o.legs or LEGS.stand, o.body or BODY.idle
  local lt = Y + 20 - legs.h
  local bt = lt - body.h + (o.by or 0)
  local d = bt - (Y + 10)
  local ta = o.tailAt or { -2, 14 }
  K.put(c, o.tail or TAIL.down, X + ta[1], Y + d + ta[2])
  K.put(c, legs, X, lt)
  K.put(c, body, X, bt)
  K.put(c, o.head or HEAD, X + HX + (o.hx or 0), bt - 10 + (o.hy or 0))
  if o.paw ~= false then
    local paw, from = o.paw or { 15, 14 }, o.armFrom or { 12, 12 }
    local px_, py_, fx, fy = X + paw[1], Y + d + paw[2], X + from[1], Y + d + from[2]
    c:line(fx, fy, px_ - (px_ >= fx and 1 or -1), py_, COL.f)
    c:set(px_, py_, COL.F)
  end
  return c
end
local function with(base, t)
  local o = {}
  for k, v in pairs(base) do o[k] = v end
  for k, v in pairs(t) do o[k] = v end
  return o
end

------------------------------------------------------------------ animation
local function draw(tag, i)
  if tag == "idle" then
    local P = {
      { },
      { hy = 1, tail = TAIL.up },
      { hy = 1, body = BODY.idle2, head = HEAD_BLINK, tail = TAIL.up },
      { body = BODY.idle2, paw = { 15, 13 } },
    }
    return fig(P[i + 1])
  end

  if tag == "run" then
    local P = {
      { hx = 1, hy = 1, body = BODY.runA, legs = LEGS.r1, tail = TAIL.wag, tailAt = { -3, 13 }, paw = { 16, 13 } },
      { hx = 1, oy = -1, body = BODY.runB, legs = LEGS.r2, tail = TAIL.up, tailAt = { -2, 13 }, paw = { 15, 14 } },
      { hx = 1, hy = 1, body = BODY.runA, legs = LEGS.r3, tail = TAIL.wag, tailAt = { -3, 13 }, paw = { 14, 14 } },
      { hx = 1, oy = -1, body = BODY.runB, legs = LEGS.r4, tail = TAIL.up, tailAt = { -2, 13 }, paw = { 15, 14 } },
    }
    local c = fig(P[i + 1])
    if i == 0 or i == 2 then K.dust(c, OX + 4, 31, i) end
    return c
  end

  if tag == "attack" then
    -- rear back, lunge with the jaws wide, snap shut, hold, pull back, settle
    local P = {
      { hx = -1, hy = 1, body = BODY.crouch, legs = LEGS.wide, paw = { 14, 14 } },
      { ox = 1, hx = 2, head = HEAD_OPEN, body = BODY.runA, legs = LEGS.wide, tail = TAIL.up, paw = { 17, 13 } },
      { ox = 1, hx = 2, hy = 1, body = BODY.runA, legs = LEGS.wide, tail = TAIL.wag, tailAt = { -3, 13 }, paw = { 17, 13 } },
      { ox = 1, hx = 2, hy = 1, head = HEAD_BLINK, body = BODY.runB, legs = LEGS.wide, tail = TAIL.wag, tailAt = { -3, 13 }, paw = { 16, 14 } },
      { hx = 1, body = BODY.runB, legs = LEGS.wide, paw = { 16, 14 } },
      { body = BODY.idle2 },
    }
    local c = fig(P[i + 1])
    local tip = OX + 1 + HX + 2 + 18      -- snout tip during the lunge
    if i == 1 then
      K.speed(c, OX - 1, OY + 8, 2, 3, K.MARK2, 2)
    elseif i == 2 then   -- jaws snap: bite flecks in front of the nose
      local y = OY + 7
      c:set(tip + 1, y - 1, K.MARK); c:set(tip + 2, y - 2, K.MARK)
      c:set(tip + 1, y + 2, K.MARK); c:set(tip + 2, y + 3, K.MARK)
    elseif i == 3 then
      K.bang(c, tip, OY + 1)
    end
    return c
  end

  if tag == "special" then
    -- growl, the act drops (ears up, shawl thrown open), roar with shawl shreds flying,
    -- then pull the bonnet straight again
    local P = {
      { hy = 1, head = HEAD_HURT, body = BODY.crouch, legs = LEGS.wide, paw = { 14, 14 } },
      { hx = 1, head = HEAD_WILD, body = BODY.flare, legs = LEGS.wide, tail = TAIL.up, paw = { 17, 12 } },
      { hx = 1, head = HEAD_WILD_OPEN, body = BODY.flare, legs = LEGS.wide, tail = TAIL.wag, tailAt = { -3, 13 }, paw = { 17, 11 } },
      { ox = 1, hx = 1, head = HEAD_WILD_OPEN, body = BODY.flare, legs = LEGS.wide, tail = TAIL.up, paw = { 17, 12 } },
      { hx = 1, head = HEAD_WILD_OPEN, body = BODY.flare, legs = LEGS.wide, tail = TAIL.wag, tailAt = { -3, 13 }, paw = { 17, 11 } },
      { ox = 1, hx = 1, head = HEAD_WILD_OPEN, body = BODY.flare, legs = LEGS.wide, tail = TAIL.up, paw = { 17, 12 } },
      { hx = 1, head = HEAD_WILD, body = BODY.idle2, legs = LEGS.wide, paw = { 16, 13 } },
      { hy = 1, head = HEAD_BLINK, body = BODY.idle2, armFrom = { 12, 11 }, paw = { 13, 9 } },
    }
    local c = fig(P[i + 1])
    -- shawl shreds: torn off the shoulders, flying out up-left and up-right
    local shreds = {
      [2] = { { 3, 19, 1 }, { 22, 20, 2 } },
      [3] = { { 1, 15, 2 }, { 25, 17, 1 }, { 7, 16, 3 } },
      [4] = { { 1, 11, 3 }, { 27, 13, 2 }, { 5, 13, 1 } },
      [5] = { { 3, 8, 1 }, { 2, 10, 2 }, { 28, 9, 3 } },
      [6] = { { 2, 6, 2 } },
    }
    for _, s in ipairs(shreds[i] or {}) do K.put(c, SCRAP[s[3]], s[1], s[2]) end
    if i >= 2 and i <= 5 then K.bang(c, 27 - (i % 2), OY - 2 + (i % 2)) end
    return c
  end

  local HURT = { hx = -1, head = HEAD_HURT, body = BODY.idle2, legs = LEGS.wide, tail = TAIL.up, paw = { 15, 11 }, armFrom = { 12, 12 } }
  if tag == "hit" then
    if i == 0 then return K.flashOf(fig(HURT)) end
    if i == 3 then return fig({ hy = 1, body = BODY.idle2 }) end
    local c = fig(with(HURT, { hx = -1 - (i - 1), ox = -(i - 1) }))
    K.bang(c, OX + 22 - (i - 1), OY + (i - 1))
    return c
  end

  if tag == "death" then
    if i == 0 then
      local c = fig(HURT); K.bang(c, OX + 22, OY); return c
    end
    if i == 1 then
      return fig({ hx = -2, hy = 2, head = HEAD_HURT, body = BODY.crouch, legs = LEGS.wide, tail = TAIL.up, paw = { 16, 13 } })
    end
    if i == 2 then
      return fig({ ox = 1, hy = 5, head = HEAD_HURT, body = BODY.crouch, legs = LEGS.wide, tail = TAIL.wag, tailAt = { -3, 14 }, paw = { 16, 15 } })
    end
    -- flat on its belly: hind legs and tail out to the left, bonnet head resting at the right
    local c = K.canvas()
    local dy = (i == 3) and -1 or 0
    K.foot(c, DOWN, 2, 31 + dy)
    K.foot(c, HEAD_HURT, 11, 31 + dy)
    if i == 3 then K.dust(c, 3, 31, 0); K.dust(c, 29, 31, 1) end
    if i >= 4 and i <= 6 then K.dizzy(c, 16, 14 - (i - 4), i) end
    return c
  end
end

return K.build("wolf_in_disguise", draw)
