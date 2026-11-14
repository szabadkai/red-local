-- Rogue hunter at red-local scale (20 px tall): green hood with a floppy tip,
-- leather jerkin, bow. attack = bow shot, special = sets a bear trap that snaps shut.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local K = dofile(HERE .. "/kit.lua")

local MAP = {
  G = "#4fae3b", g = "#1d5c2f",                 -- hood / mantle
  h = "#3a2316",                                -- hair, far leg, boots
  s = "#f5c08f",                                -- skin
  E = "#000000", e = "#000000",                 -- eye top / eye bottom
  L = "#b8723a", l = "#6c391e",                 -- leather
  P = "#3e3b57",                                -- trousers (near leg)
  W = "#f0c467",                                -- bow wood
  w = "#f6ecee",                                -- bow string, fletching (same white as the marks)
  M = "#bfc8d2", m = "#5c6877",                 -- trap / arrowhead metal
}
local function A(rows) return K.art(rows, MAP) end
local COL = {}
for k, v in pairs(MAP) do COL[k] = K.rgb(v) end

------------------------------------------------------------------ parts (16 cols wide)
local HEAD = A {
  ".gg.............",
  "..gGG...........",
  "...gGGGGGG......",
  "..gGGGGGGGGGG...",
  ".gGGGGGGGGGGGGG.",
  ".gGGGGGGGGGGGGGG",
  ".gGGGGGGghhhhhGG",
  ".gGGGGGGghhhhhhG",
  ".gGGGGGGgsEssEsG",
  ".ggGGGGGgsessesG",
  "..ggGGGGGgsssss.",
}
local HEAD_BLINK = K.swap(HEAD, { E = "s" }, MAP)
local HEAD_HURT = K.swap(HEAD, { E = "s", e = "h" }, MAP)
local HEAD_DOWN = A {   -- looking down at the trap
  "................",
  ".gg.............",
  "..gGG...........",
  "...gGGGGGG......",
  "..gGGGGGGGGGG...",
  ".gGGGGGGGGGGGGG.",
  ".gGGGGGGGGGGGGGG",
  ".gGGGGGGghhhhhhG",
  ".gGGGGGGghhhhhhG",
  ".ggGGGGGgseshesG",
  "..ggGGGGGgsssss.",
}

local BODY = {
  idle = A {
    "..ggGGGGGGGGLL..",
    "..gGGGGGGGGLLL..",
    "..ggGGGGGgLLLL..",
    "...lLLLLLLLLLL..",
    "...hhhhhhhhMhh..",
    "...lLLLLLLLLLL..",
  },
  idle2 = A {   -- mantle hem lifts a pixel
    "..ggGGGGGGGGLL..",
    "..gGGGGGGGGLLL..",
    "...gGGGGGgLLLL..",
    "...lLLLLLLLLLL..",
    "...hhhhhhhhMhh..",
    "...lLLLLLLLLLL..",
  },
  runA = A {    -- mantle blown back
    ".gggGGGGGGGGLL..",
    "ggGGGGGGGGGLLL..",
    "..ggGGGGGgLLLL..",
    "...lLLLLLLLLLL..",
    "...hhhhhhhhMhh..",
    "...lLLLLLLLLLL..",
  },
  runB = A {
    "..ggGGGGGGGGLL..",
    ".ggGGGGGGGGLLL..",
    "gg.gGGGGGgLLLL..",
    "...lLLLLLLLLLL..",
    "...hhhhhhhhMhh..",
    "...lLLLLLLLLLL..",
  },
  crouch = A {  -- squashed for kneeling / bracing
    "..ggGGGGGGGGLL..",
    ".ggGGGGGGGgLLL..",
    "..lLLLLLLLLLLL..",
    "..hhhhhhhhhMhh..",
    "..lLLLLLLLLLLL..",
  },
}
local LEGS = {
  stand = A { ".....hh..PP.....", ".....hh..PP.....", ".....hhh.lll...." },
  r1 = A { "......hh.PP.....", ".....hh...PP....", "...hhh.....lll.." },  -- near leg forward
  r2 = A { "......hhPP......", "....hhh.PP......", "........lll....." },  -- passing, far leg lifted
  r3 = A { "......PP.hh.....", ".....PP...hh....", "...lll.....hhh.." },  -- far leg forward
  r4 = A { "......PPhh......", "....lPP.hh......", "........hhh....." },  -- passing, near leg lifted
  wide = A { ".....hh...PP....", "....hh.....PP...", "...hhh.....lll.." }, -- braced
  kneel = A { "....hhhhPPPP....", "..hhhh.....lll.." },                     -- near knee up
}
-- bow, belly to the right; string runs down col 0, grip at (2, 4)
local BOW = A { "W..", ".W.", "..W", "..W", "..l", "..W", "..W", ".W.", "W.." }
local BOW_BACK = K.flip(BOW)   -- carried in the far hand behind the back (grip at (0, 4))
local TRAP_OPEN = A { "M.M...M.M", "mMmmmmmMm" }
local TRAP_SHUT = A { ".M.M.M.", "MMmMmMM", "M.....M", "mmmmmmm" }
local TRAP_HELD = A { ".M.M.", "MmMmM" }
local DOWN = A {  -- flat on his front, mantle over the back (head drawn separately)
  ".........ggGGGGG",
  ".......ggGGGGGGG",
  "hh..PPlgGGGGGGGG",
  "hhhPPPlLLLLLGGGG",
  "hhhPPPlLLLLLLLgg",
}

------------------------------------------------------------------ figure
local OX, OY = 8, 12   -- top-left of the 16x20 figure box when standing (feet on y = 31)

local function arrowAt(c, x0, x1, y)
  c:set(x0, y, COL.w); c:set(x0 + 1, y, COL.w)
  c:line(x0 + 2, y, x1 - 1, y, COL.l)
  c:set(x1, y, COL.M)
end

-- o: ox, oy (whole figure), hx, hy (head offset), head, body, legs, by,
--    bow = {gx, gy} grip (figure coords), pull = {x, y} string drawn to, arrow = true,
--    backBow = {gx, gy} bow carried behind, arm = {fx, fy, hx, hy} near arm,
--    arm2 = far arm (drawn behind the bow), held = trap art in the near hand
local function fig(o)
  local c = K.canvas()
  local X, Y = OX + (o.ox or 0), OY + (o.oy or 0)
  local legs, body = o.legs or LEGS.stand, o.body or BODY.idle
  local lt = Y + 20 - legs.h
  local bt = lt - body.h + (o.by or 0)
  local d = bt - (Y + 11)              -- how far the upper body dropped
  if o.backBow then K.put(c, BOW_BACK, X + o.backBow[1], Y + d + o.backBow[2] - 4) end
  K.put(c, legs, X, lt)
  K.put(c, body, X, bt)
  K.put(c, o.head or HEAD, X + (o.hx or 0), bt - 11 + (o.hy or 0))
  local function arm(a, col)
    local fx, fy, hx, hy = X + a[1], Y + d + a[2], X + a[3], Y + d + a[4]
    c:line(fx, fy, hx - (hx >= fx and 1 or -1), hy, col)
    c:set(hx, hy, COL.s)
  end
  if o.arm2 then arm(o.arm2, COL.g) end
  if o.bow then
    local gx, gy = X + o.bow[1], Y + d + o.bow[2]
    local tx, ty, by_ = gx - 2, gy - 4, gy + 4
    if o.pull then
      local px_, py_ = X + o.pull[1], Y + d + o.pull[2]
      c:line(tx, ty, px_, py_, COL.w); c:line(px_, py_, tx, by_, COL.w)
      if o.arrow then arrowAt(c, px_, gx + 2, py_) end
    else
      c:line(tx, ty, tx, by_, COL.w)
      if o.arrow then arrowAt(c, tx, gx + 2, gy) end
    end
    K.put(c, BOW, tx, ty)
    if o.arrow then c:set(gx + 1, o.pull and Y + d + o.pull[2] or gy, COL.l); c:set(gx + 2, o.pull and Y + d + o.pull[2] or gy, COL.M) end
  end
  if o.arm then arm(o.arm, COL.G) end
  if o.held then K.put(c, o.held, X + o.arm[3] - 2, Y + d + o.arm[4] + 1) end
  return c
end

local REST = { bow = { 15, 15 }, arm = { 11, 12, 15, 15 } }   -- bow tip resting on the ground
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
      with(REST, {}),
      with(REST, { hy = 1 }),
      with(REST, { hy = 1, body = BODY.idle2, head = HEAD_BLINK }),
      with(REST, { body = BODY.idle2, arm = { 11, 12, 15, 14 }, bow = { 15, 14 } }),
    }
    return fig(P[i + 1])
  end

  if tag == "run" then
    -- bow slung on the back, near arm pumping
    local P = {
      { hx = 1, body = BODY.runA, legs = LEGS.r1, backBow = { -1, 12 }, arm = { 11, 12, 9, 15 } },
      { hx = 1, oy = -1, body = BODY.runB, legs = LEGS.r2, backBow = { -1, 13 }, arm = { 11, 12, 12, 15 } },
      { hx = 1, body = BODY.runA, legs = LEGS.r3, backBow = { -1, 12 }, arm = { 11, 12, 15, 13 } },
      { hx = 1, oy = -1, body = BODY.runB, legs = LEGS.r4, backBow = { -1, 13 }, arm = { 11, 12, 12, 15 } },
    }
    local c = fig(P[i + 1])
    if i == 0 or i == 2 then K.dust(c, OX + 4, 31, i) end
    return c
  end

  if tag == "attack" then
    -- raise and nock, draw, full draw, release (arrow away), arrow far off, lower
    local P = {
      { legs = LEGS.wide, bow = { 17, 13 }, arm2 = { 10, 12, 17, 13 }, arm = { 11, 12, 15, 13 }, arrow = true },
      { legs = LEGS.wide, bow = { 17, 13 }, arm2 = { 10, 12, 17, 13 }, pull = { 13, 13 }, arm = { 11, 12, 13, 13 }, arrow = true },
      { hx = -1, legs = LEGS.wide, bow = { 18, 13 }, arm2 = { 10, 12, 18, 13 }, pull = { 11, 13 }, arm = { 10, 12, 11, 13 }, arrow = true },
      { legs = LEGS.wide, bow = { 18, 13 }, arm2 = { 10, 12, 18, 13 }, pull = { 17, 13 }, arm = { 10, 12, 9, 12 } },
      { legs = LEGS.wide, bow = { 17, 13 }, arm2 = { 10, 12, 17, 13 }, arm = { 10, 12, 10, 14 } },
      with(REST, { body = BODY.idle2, bow = { 16, 14 }, arm = { 11, 12, 16, 14 } }),
    }
    local c = fig(P[i + 1])
    local ay = OY + 13
    if i == 3 then        -- arrow just off the string
      arrowAt(c, 27, 33, ay)
    elseif i == 4 then    -- only its streak is left at the edge
      c:line(28, ay, 30, ay, K.MARK); c:line(27, ay - 2, 28, ay - 2, K.MARK2)
    end
    return c
  end

  if tag == "special" then
    -- pull a trap off the belt, kneel and set it, step back, it snaps shut
    local TX, TY = 21, 30   -- open trap top-left on the ground
    local P = {
      { head = HEAD_DOWN, backBow = { -1, 12 }, arm = { 11, 12, 12, 15 }, held = TRAP_HELD },
      { head = HEAD_DOWN, hx = 1, body = BODY.crouch, legs = LEGS.kneel, backBow = { -1, 12 }, arm = { 11, 12, 15, 14 }, held = TRAP_HELD },
      { head = HEAD_DOWN, hx = 1, body = BODY.crouch, legs = LEGS.kneel, backBow = { -1, 12 }, arm = { 11, 12, 15, 15 } },
      { ox = -1, backBow = { -1, 12 }, arm = { 11, 12, 13, 15 } },
      { ox = -1, hx = -1, legs = LEGS.wide, head = HEAD_BLINK, backBow = { -1, 12 }, arm = { 11, 12, 12, 13 } },
      { ox = -1, backBow = { -1, 12 }, arm = { 11, 12, 13, 15 } },
      with(REST, { ox = -1, hy = 1 }),
      with(REST, { ox = -1 }),
    }
    local c = fig(P[i + 1])
    if i == 2 or i == 3 then
      K.put(c, TRAP_OPEN, TX, TY)
    elseif i >= 4 then
      K.put(c, TRAP_SHUT, TX + 1, 28)
      if i == 4 then K.bang(c, TX + 7, 22); c:set(TX - 1, 26, K.MARK); c:set(TX + 8, 26, K.MARK) end
      if i == 5 then K.bang(c, TX + 8, 21) end
    end
    return c
  end

  local HURT = { hx = -1, head = HEAD_HURT, body = BODY.idle2, legs = LEGS.wide, bow = { 16, 15 }, arm = { 11, 12, 16, 15 } }
  if tag == "hit" then
    if i == 0 then return K.flashOf(fig(HURT)) end
    if i == 3 then return fig(with(REST, { hy = 1, body = BODY.idle2 })) end
    local c = fig(with(HURT, { hx = -1 - (i - 1), ox = -(i - 1) }))
    K.bang(c, OX + 16 - (i - 1), OY + 1 + (i - 1))
    return c
  end

  if tag == "death" then
    if i == 0 then
      local c = fig(HURT); K.bang(c, OX + 16, OY + 1); return c
    end
    if i == 1 then
      return fig({ hx = -2, hy = 1, head = HEAD_HURT, body = BODY.crouch, legs = LEGS.wide, bow = { 18, 15 }, arm = { 11, 12, 17, 14 } })
    end
    if i == 2 then
      local c = fig({ ox = 1, hx = 1, hy = 2, head = HEAD_HURT, body = BODY.crouch, legs = LEGS.kneel, arm = { 11, 12, 15, 15 } })
      K.put(c, K.rot(BOW, 1), 22, 28)
      return c
    end
    -- flat on the ground: legs to the left, head resting at the right, bow dropped in front
    local c = K.canvas()
    local dy = (i == 3) and -1 or 0
    K.put(c, K.rot(BOW, 1), 22, 29)
    K.foot(c, DOWN, 2, 31 + dy)
    K.foot(c, HEAD_HURT, 10, 31 + dy)
    if i == 3 then K.dust(c, 3, 31, 0); K.dust(c, 27, 31, 1) end
    if i >= 4 and i <= 6 then K.dizzy(c, 17, 14 - (i - 4), i) end
    return c
  end
end

return K.build("rogue_hunter", draw)
