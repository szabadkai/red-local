-- Living Tree at red-local scale: a big enemy, 26 px tall next to Red's 18.
-- Leafy crown for a "hood", glowing eyes on the trunk, branch arms, stubby root feet.
-- attack = branch slam into the ground, special = roots erupt from the ground in front.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local K = dofile(HERE .. "/kit.lua")

local MAP = {
  G = "#5cc23e", g = "#2b8a46", l = "#b8ee5c",   -- leaves: base, shade, lit tips
  B = "#b8763c", b = "#74402c",                  -- bark
  x = "#000000", m = "#000000", o = "#b8763c",   -- brows, mouth, mouth extension (bark until opened)
  Y = "#ffe14a", y = "#ffe14a",                  -- glowing eyes (top / bottom pixel)
}
local function A(rows) return K.art(rows, MAP) end
local MARK, MARK2 = K.MARK, K.MARK2
local LEAF, LEAF_DK, LIT = K.rgb(MAP.G), K.rgb(MAP.g), K.rgb(MAP.l)

------------------------------------------------------------------ crown (20 cols, 12 rows)
local CROWN = {
  rest = A {
    ".......gGGGl........",
    "...gggGGGGGGl.gGl...",
    "..ggggGGGGGGGgGGGGl.",
    ".gggggGGGGGGGGGGGGGl",
    ".ggggggGGGGGGGGGGGGG",
    "gggggggGGGGGGGGGGGGG",
    "ggggggggGGGGGGGGGlGG",
    "gggggggggGGGGGGGGGGG",
    ".ggggggggggGGGGGGGGg",
    ".gggggggggggggGGGGgg",
    "..gggggggggggggggggg",
    "....gggg..ggggg..gg.",
  },
  -- top clumps lag to the left (figure moving right / leaning forward)
  swayL = A {
    "......gGGGl.........",
    "..gggGGGGGGl.gGl....",
    ".ggggGGGGGGGgGGGGl..",
    ".ggggGGGGGGGGGGGGGl.",
    ".ggggggGGGGGGGGGGGGl",
    "gggggggGGGGGGGGGGGGG",
    "ggggggggGGGGGGGGGlGG",
    "gggggggggGGGGGGGGGGG",
    ".ggggggggggGGGGGGGGg",
    ".gggggggggggggGGGGgg",
    "..gggggggggggggggggg",
    "....gggg..ggggg..gg.",
  },
  -- top clumps lag to the right (figure pushed left)
  swayR = A {
    "........gGGGl.......",
    "....gggGGGGGGl.gGl..",
    "..gggggGGGGGGGgGGGGl",
    ".gggggGGGGGGGGGGGGGl",
    ".ggggggGGGGGGGGGGGGG",
    "gggggggGGGGGGGGGGGGG",
    "ggggggggGGGGGGGGGlGG",
    "gggggggggGGGGGGGGGGG",
    ".ggggggggggGGGGGGGGg",
    ".gggggggggggggGGGGgg",
    "..gggggggggggggggggg",
    "....gggg..ggggg..gg.",
  },
  -- squashed after an impact: one row lower, clumps flatter and wider
  squash = A {
    "....................",
    "......gggGGGl.......",
    "..gggggGGGGGGGl.gGl.",
    ".ggggggGGGGGGGGgGGGl",
    "gggggggGGGGGGGGGGGGG",
    "gggggggGGGGGGGGGGGGG",
    "ggggggggGGGGGGGGGlGG",
    "gggggggggGGGGGGGGGGG",
    "gggggggggggGGGGGGGGg",
    ".gggggggggggggGGGGgg",
    "..gggggggggggggggggg",
    "....gggg..ggggg..gg.",
  },
}

------------------------------------------------------------------ trunk + roots
local TRUNK = A {
  "......bbbbbbbbb.....",
  "......bbbbbbbbb.....",
  "......bbbbbbbbb.....",
  "......bbbBBBBBB.....",
  "......bbBxxBxxB.....",
  "......bbBBYBBYB.....",
  "......bbBByBByB.....",
  "......bbBBBBBBB.....",
  "......bbBBBmmBB.....",
  ".....bbbBBBooBBB....",
  ".....bbbBBBBBBBB....",
  ".....bbbbBBBbBBB....",
  "....bbbbbBBBbBBBB...",
}
local TRUNK_BLINK = K.swap(TRUNK, { Y = "B", y = "x" }, MAP)
local TRUNK_HURT = K.swap(TRUNK, { Y = "x", y = "B", x = "B", o = "m" }, MAP)
local TRUNK_DEAD = K.swap(TRUNK, { Y = "x", y = "x", x = "B", o = "m" }, MAP)
local TRUNK_ROAR = K.swap(TRUNK, { o = "m" }, MAP)
-- a split running down the trunk
local CRACK = A { "x.", "x.", ".x", ".x", "x." }

local ROOTS = {
  stand = A {
    "....bbbbbbBBBBBBB...",
    "...bbbbb..BBBBBBBB..",
    "..bbb.bb...BBB.BBBB.",
  },
  wide = A {    -- braced for the slam
    "...bbbbbbbBBBBBBBB..",
    "..bbbbb.....BBBBBBB.",
    ".bbb.b.......BB.BBBB",
  },
  r1 = A {      -- near root forward, far root back
    "...bbbbbbbBBBBBBBB..",
    "..bbbb.......BBBBBB.",
    ".bbb...........BBBB.",
  },
  r2 = A {      -- passing, far root lifted
    "....bbbbbbBBBBBBB...",
    "....bbb...BBBBBBB...",
    "...........BBBBBB...",
  },
  r3 = A {      -- far root forward, near root back
    "...bbbbbbbbBBBBBBb..",
    "..BBBBB.......bbbbb.",
    ".BBBB...........bbbb",
  },
  r4 = A {      -- passing, near root lifted
    "....bbbbbbBBBBBBB...",
    "....bbbbbbb.BBBB....",
    ".....bbbbb..........",
  },
}

------------------------------------------------------------------ arms (front arm art; back arms are mirrored)
local ARM = {
  hang = A {
    "BB....",
    "bBB...",
    ".bBB..",
    "..bBB.",
    "..B.B.",
    ".B..B.",
  },
  hang2 = A {   -- creaks out a little
    "BBB....",
    "bBBB...",
    "..bBB..",
    "...bBB.",
    "...B.BB",
    "..B....",
  },
  fwd = A {     -- run: swung forward
    "BBB.....",
    "bBBBB...",
    "...bBBB.",
    ".....BB.",
    "....B..B",
  },
  bk = A {      -- run: swung back along the trunk
    "BB...",
    "bB...",
    "bBB..",
    ".bB..",
    "B.B..",
  },
  up = A {      -- slam wind-up: raised high in front of the crown
    "...B.B.B",
    "....BBB.",
    "....bBB.",
    "...bBB..",
    "...bBB..",
    "...bBB..",
    "..bBB...",
    "..bBB...",
    "..bBB...",
    ".bBB....",
    ".bBB....",
    ".bBB....",
    "bBB.....",
    "BB......",
  },
  over = A {    -- slam top: bent back over the crown
    "B.B......",
    ".BBB.....",
    "..BBBB...",
    "...bBBB..",
    "....bBBB.",
    "......bBB",
    "......bBB",
    ".....bBB.",
    ".....bBB.",
    "....bBB..",
    "....bBB..",
    "...bBB...",
    "...bBB...",
    "..bBB....",
    ".bBB.....",
    "bBB......",
    "BB.......",
  },
  swing = A {   -- coming down: straight out forward
    ".......B.B",
    "......BBB.",
    ".....bBB..",
    "....bBB...",
    "...bBB....",
    "..bBB.....",
    ".bBB......",
    "bBB.......",
    "BB........",
  },
  slam = A {    -- hand smashed flat on the ground
    "BBB.......",
    "bBBBB.....",
    "..bBBBB...",
    "....bBBB..",
    ".....bBBB.",
    "......bBB.",
    ".......BB.",
    "......BBBB",
    ".....B.B.B",
  },
  mid = A {     -- lifting back up
    "BBB....",
    "bBBBB..",
    "..bBBB.",
    "....bBB",
    "....B.B",
    "...B..B",
  },
  raise = A {   -- special: both arms straight up, summoning
    "..B.B",
    "..BBB",
    "..bB.",
    ".bB..",
    ".bB..",
    ".bB..",
    "bB...",
    "bB...",
    "BB...",
  },
  fling = A {   -- hit: flung up and out
    ".....B.B",
    "......BB",
    "....bBB.",
    "..bBB...",
    "BBB.....",
    "bB......",
  },
  droop = A {   -- death: limp
    "BB...",
    "bB...",
    "bB...",
    ".bB..",
    ".bB..",
    ".B.B.",
  },
}
-- shoulder row inside each arm art (the shoulder is always the art's left column)
local SHOULDER = { up = 13, over = 16, swing = 8, raise = 8, fling = 4 }
local function back(a) return K.swap(K.flip(a), { B = "b" }, MAP) end
local BACK = {}
for k, a in pairs(ARM) do BACK[k] = back(a) end
-- placements as { art, x, y } in figure coords. Front shoulder just right of the trunk,
-- back shoulder hidden behind the trunk's left edge (mirrored art).
local FS, BS, SY = 15, 6, 17
local function front(k, dy) return { ARM[k], FS, SY + (dy or 0) - (SHOULDER[k] or 0) } end
local function rear(k, dy)
  local a = BACK[k]
  return { a, BS - a.w + 1, SY + (dy or 0) - (SHOULDER[k] or 0) }
end

------------------------------------------------------------------ figure
local OX, OY = 6, 6     -- top-left of the 20x26 figure box when standing (roots on y = 31)
-- o: ox, oy (whole figure), crown, cx, cy (crown offset), trunk, ty, roots,
--    arm / barm = { art, x, y } front / back arm in figure coords, crack
local function fig(o)
  local c = K.canvas()
  local X, Y = OX + (o.ox or 0), OY + (o.oy or 0)
  local barm = o.barm or rear("hang")
  K.put(c, barm[1], X + barm[2], Y + barm[3])
  K.put(c, o.trunk or TRUNK, X, Y + 10 + (o.ty or 0))
  if o.crack then K.put(c, CRACK, X + 10, Y + 18 + (o.ty or 0)) end
  K.put(c, o.roots or ROOTS.stand, X, Y + 23)
  K.put(c, o.crown or CROWN.rest, X + (o.cx or 0), Y + (o.cy or 0))
  local arm = o.arm or front("hang")
  K.put(c, arm[1], X + arm[2], Y + arm[3])
  return c
end

------------------------------------------------------------------ fx
-- a single leaf drifting down: 2 px, flips each step
local function leaf(c, x, y, k)
  if k % 2 == 0 then c:set(x, y, LEAF); c:set(x + 1, y, LIT)
  else c:set(x, y, LEAF); c:set(x + 1, y + 1, LEAF_DK) end
end

-- root tendrils bursting out of the ground (bottom on y = 31), by height step
local SPIKE = {
  A {
    ".bB.",
    "bbBB",
  },
  A {
    "..B.",
    ".bB.",
    ".bB.",
    "bbBB",
  },
  A {
    "..lG",
    "..B.",
    ".bB.",
    ".bB.",
    "..bB",
    ".bbB",
    "bbBB",
  },
  A {
    "...lG",
    "...B.",
    "..bB.",
    ".bB..",
    ".bB..",
    ".bB..",
    "..bB.",
    "..bB.",
    ".bbB.",
    "bbbBB",
  },
  A {
    "...GG",
    "..lG.",
    "..bB.",
    ".bB..",
    ".bB..",
    ".bB..",
    "..bB.",
    "..bB.",
    "..bB.",
    ".bbB.",
    ".bbBB",
    "bbbBB",
  },
}

-- mid-fall: tipping over backwards, crown first
local TIP = A {
  "....gggGGl................",
  "..ggggGGGGGl..............",
  ".gggggGGGGGGl.............",
  "ggggggGGGGGGGl............",
  "gggggggGGGGGGG............",
  "ggggggggGGGGGGG...........",
  "gggggggggGGGGGG...........",
  ".ggggggggggGGGgB..........",
  "..gggggggggggggBB.........",
  "...gggggggggggBBBB........",
  ".....ggggg.bbbBBBBm.......",
  "............bbbBBBBB......",
  ".............bbbmBBBB.....",
  "..............bbbBBmmB....",
  "...............bbbBBBBB...",
  "................bbbBBBBB..",
  "...............bbbbbBBBBB.",
  "..............bbb.bbbBBBBB",
}
-- fallen flat: crown heaped on the left, trunk lying along the ground, root stubs at the right
local DOWN = A {
  "....gggGGl...................",
  "..ggggGGGGGl.................",
  ".gggggGGGGGGl................",
  "gggggggGGGGGGbbBBBBBBBBBBBB..",
  "ggggggggGGGGGbbBBmBBBmBBBBBbb",
  "gggggggggGGGGbbBBBBBBmmBBBBbb",
  ".gggggggggggbbbbbbbbbbbbbbbbb",
  "..ggggggggg....bbb..bbb..bbb.",
}

------------------------------------------------------------------ animation
local function draw(tag, i)
  if tag == "idle" then
    local P = {
      { },
      { cy = 1, crown = CROWN.swayR, arm = front("hang2") },
      { cy = 1, trunk = TRUNK_BLINK, arm = front("hang2"), barm = rear("hang2") },
      { crown = CROWN.swayL, barm = rear("hang2") },
    }
    return fig(P[i + 1])
  end

  if tag == "run" then
    -- heavy waddle: roots stride, crown lags behind the bob by a frame
    local P = {
      { roots = ROOTS.r1, crown = CROWN.swayL, cy = -1, arm = front("bk"), barm = rear("fwd") },
      { oy = -1, roots = ROOTS.r2, crown = CROWN.swayL, cy = 1, arm = front("hang"), barm = rear("hang") },
      { roots = ROOTS.r3, crown = CROWN.swayL, cy = -1, arm = front("fwd"), barm = rear("bk") },
      { oy = -1, roots = ROOTS.r4, crown = CROWN.swayL, cy = 1, arm = front("hang"), barm = rear("hang") },
    }
    local c = fig(P[i + 1])
    if i == 0 then K.dust(c, OX + 3, 31, 0) elseif i == 2 then K.dust(c, OX + 18, 31, 1) end
    return c
  end

  if tag == "attack" then
    -- arm up, over the crown, swung down, smashed on the ground, hold, lift
    local P = {
      { cx = 1, crown = CROWN.swayL, roots = ROOTS.wide, arm = front("up") },
      { cx = 1, cy = -1, crown = CROWN.swayR, roots = ROOTS.wide, arm = front("over") },
      { crown = CROWN.swayL, roots = ROOTS.wide, arm = front("swing"), trunk = TRUNK_ROAR },
      { cy = 1, crown = CROWN.squash, roots = ROOTS.wide, arm = front("slam"), trunk = TRUNK_ROAR },
      { cy = 0, crown = CROWN.swayL, roots = ROOTS.wide, arm = front("slam") },
      { crown = CROWN.swayR, arm = front("mid") },
    }
    local c = fig(P[i + 1])
    if i == 2 then
      c:curve(OX + 17, OY - 3, OX + 27, OY - 1, OX + 25, OY + 11, MARK)
      c:curve(OX + 15, OY - 1, OX + 23, OY + 1, OX + 23, OY + 9, MARK2)
    elseif i == 3 then
      K.bang(c, OX + 22, OY + 12)
      K.dust(c, OX + 19, 31, 0); K.dust(c, OX + 24, 30, 1)
    elseif i == 4 then
      K.dust(c, OX + 18, 30, 1); K.dust(c, OX + 24, 29, 0)
    end
    return c
  end

  if tag == "special" then
    -- crouch, arms rise, a clump of roots bursts out of the ground in front, then sinks back
    -- tendril heights per frame: { near (at the foot), middle, far }
    local hs = { { 0, 0, 0 }, { 1, 0, 0 }, { 2, 2, 0 }, { 2, 4, 1 }, { 1, 5, 3 }, { 1, 5, 4 }, { 0, 3, 2 }, { 0, 1, 1 } }
    local up = { arm = front("raise"), barm = rear("raise"), roots = ROOTS.wide, trunk = TRUNK_ROAR }
    local P = {
      { cy = 1, crown = CROWN.squash, roots = ROOTS.wide, arm = front("mid"), barm = rear("mid") },
      { crown = CROWN.swayR, roots = ROOTS.wide, arm = front("raise", 1), barm = rear("raise", 1) },
      { cy = -1, crown = CROWN.rest },
      { cy = -1, crown = CROWN.swayL },
      { cy = -1, crown = CROWN.rest },
      { cy = -1, crown = CROWN.swayR },
      { crown = CROWN.rest, roots = ROOTS.wide, arm = front("mid"), barm = rear("mid") },
      { cy = 1, crown = CROWN.swayL, arm = front("hang2") },
    }
    local o = P[i + 1]
    if i >= 2 and i <= 5 then for k, v in pairs(up) do o[k] = v end end
    local c = fig(o)
    local h = hs[i + 1]
    -- centres 28, 25, 22: the far ones are drawn first so the near one overlaps them
    for k, cx in ipairs({ 28, 25, 22 }) do
      local hh = h[4 - k]
      if hh > 0 then
        local a = SPIKE[hh]
        if k == 2 then a = K.flip(a) end
        K.foot(c, a, math.min(cx - a.w // 2, 30 - a.w + 1))
      end
    end
    if i == 1 then K.dust(c, 22, 31, 0) elseif i == 2 then K.dust(c, 27, 31, 1)
    elseif i == 7 then K.dust(c, 22, 31, 1) end
    return c
  end

  local HURT = { ox = -1, cx = 1, crown = CROWN.swayR, trunk = TRUNK_HURT, arm = front("fling"), barm = rear("fling") }
  if tag == "hit" then
    if i == 0 then return K.flashOf(fig(HURT)) end
    if i == 3 then return fig({ cy = 1, crown = CROWN.swayR, arm = front("hang2") }) end
    local c
    if i == 1 then c = fig(HURT)
    else c = fig({ ox = -1, cx = -1, crown = CROWN.swayL, trunk = TRUNK_HURT, arm = front("mid"), barm = rear("mid") }) end
    K.bang(c, OX + 20 + (i - 1), OY + 9 - (i - 1))
    leaf(c, OX + 18 + i, OY + 9 + i * 4, i)
    return c
  end

  if tag == "death" then
    if i == 0 then
      local c = fig({ ox = -1, cx = 1, crown = CROWN.swayR, trunk = TRUNK_HURT, crack = true, arm = front("fling"), barm = rear("fling") })
      K.bang(c, OX + 20, OY + 9)
      return c
    end
    if i == 1 then
      local c = fig({ ox = -1, cx = -1, cy = 2, ty = 1, crown = CROWN.swayL, trunk = TRUNK_DEAD, crack = true, arm = front("droop", 1), barm = rear("droop", 1) })
      leaf(c, OX + 21, OY + 12, 0); leaf(c, OX - 3, OY + 10, 1)
      return c
    end
    if i == 2 then
      local c = K.canvas()
      K.foot(c, TIP, 2)
      leaf(c, 26, 16, 1); leaf(c, 2, 13, 0)
      return c
    end
    local c = K.canvas()
    K.foot(c, DOWN, 1, (i == 3) and 30 or 31)
    if i == 3 then
      K.dust(c, 2, 31, 0); K.dust(c, 30, 31, 1)
      leaf(c, 8, 16, 0); leaf(c, 24, 14, 1)
    elseif i <= 6 then
      K.dizzy(c, 19, 19 - (i - 4), i)
      leaf(c, 8, 18 + (i - 4) * 3, i); leaf(c, 25, 17 + (i - 4) * 4, i + 1)
    end
    return c
  end
end

return K.build("living_tree", draw)
