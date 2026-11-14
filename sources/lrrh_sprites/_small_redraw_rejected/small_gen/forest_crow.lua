-- Forest crow at red-local scale (bird about 9 px tall perched, 11 with the branch; Red is 18).
-- idle = perched on a branch, run = flapping flight, attack = dive peck,
-- special = swooping glide, death = tumbles down, feathers scatter.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local K = dofile(HERE .. "/kit.lua")

local MAP = {
  k = "#2a2540", K = "#7a74a8",                  -- feathers: base, sheen (top / edges)
  y = "#ffe27a",                                 -- eye
  f = "#e8a95a",                                 -- feet
  r = "#7a4632", R = "#b8774a",                  -- branch
  o = "#94031a",                                 -- open beak
}
local function A(rows) return K.art(rows, MAP) end
local MARK, MARK2 = K.MARK, K.MARK2

------------------------------------------------------------------ perched (facing right)
local PERCH = A {
  "....KKKK....",
  "...KkkkkK...",
  "...kkkkykKKK",
  "...kkkkkkKK.",
  "..KKkkkkk...",
  ".KkKKkkkk...",
  "KkkkKKkkk...",
  "kk.kkkKkk...",
  "k....f.f....",
}
local PERCH_BLINK = K.swap(PERCH, { y = "k" }, MAP)
local PERCH_FLUFF = A {   -- feathers puffed, head sunk a pixel
  "............",
  "....KKKK....",
  "...KkkkkK...",
  "..KkkkkykKKK",
  "..KkkkkkkKK.",
  ".KKKkkkkkk..",
  "KkkKKkkkk...",
  "kk.kkkKkk...",
  "k....f.f....",
}
local PERCH_CAW = A {
  "....KKKK..K.",
  "...KkkkkKKK.",
  "...kkkkykoo.",
  "...kkkkkkKKK",
  "..KKkkkkk...",
  ".KkKKkkkk...",
  "KkkkKKkkk...",
  "kk.kkkKkk...",
  "k....f.f....",
}
local CROUCH = A {        -- about to spring off
  "............",
  "............",
  "...KKKK.....",
  "..KkkkkK....",
  "..kkkkykKKK.",
  ".KKkkkkkkKK.",
  "KkKKKkkkk...",
  "kk.kkkKkk...",
  "k...f.f.....",
}
local BRANCH = A {
  "rRRRRRRRRRRRRRR",
  "..rrrrrrrrrrr.r",
}

------------------------------------------------------------------ flight
local BODY = A {
  "........KKKK...",
  "KK....KKkkkkK..",
  "kkKKKkkkkkkykKK",
  ".kkkkkkkkkkkkK.",
  "...kkkkkkkkk...",
  ".....kkkkk.....",
}
local BODY_TALON = A {   -- feet thrown forward
  "........KKKK...",
  "KK....KKkkkkK..",
  "kkKKKkkkkkkykKK",
  ".kkkkkkkkkkkkK.",
  "...kkkkkkkkk...",
  ".....kkkkkff...",
  "..........f.f..",
}
local BODY_HURT = A {    -- eye squeezed, beak open, feet out
  "........KKKK...",
  "KK....KKkkkkKK.",
  "kkKKKkkkkkkkko.",
  ".kkkkkkkkkkkkKK",
  "...kkkkkkkkk...",
  ".....kkkkkff...",
  "..........f.f..",
}
-- wings: root (where the wing meets the back) at the art's (rx, ry)
local WING = {
  up = { rx = 7, ry = 7, a = A {
    "K.K......",
    "KKKK...k.",
    "kKKKK..kk",
    ".kkKKK.kk",
    ".kkkKKKkk",
    "..kkkKKKk",
    "...kkkKKK",
    "....kkkKK",
  } },
  mid = { rx = 8, ry = 3, a = A {
    "K.........",
    "KKK.......",
    ".kKKKKK...",
    "..kkkkKKKK",
    "...k.kkkkK",
  } },
  down = { rx = 7, ry = 0, a = A {
    "....kkkKK",
    "...kkkKKK",
    "..kkkKKK.",
    ".kkKKKK..",
    "kkKKK....",
    "KKK......",
    "K.K......",
  } },
  glide = { rx = 10, ry = 1, a = A {
    "KKKKKKK....",
    "kkkkkkKKKKK",
    "k.k.kkkkkkK",
  } },
}
-- flying bird: body top-left at (x, y); wing root on the back at body col 9, row 1
local function fly(c, x, y, wing, body, col)
  body = body or BODY
  wing = wing or WING.mid
  local opts = col and { col = col }
  K.put(c, body, x, y, opts)
  K.put(c, wing.a, x + 8 - wing.rx, y + 1 - wing.ry, opts)
  return c
end

------------------------------------------------------------------ dive (beak first, wings swept back)
local DIVE = A {
  "K...........",
  "KK....K.....",
  ".KK...KK....",
  "..KKK.kK....",
  "...kKKkkK...",
  "....kkkkkK..",
  ".....kkkkkK.",
  "......kkkkKK",
  ".......kkykK",
  "........kKKK",
  ".........KK.",
}
local PECK = A {          -- levelled out, beak stabbing forward, talons out
  "KK..........",
  ".KK..KK.....",
  "..KKKkKK....",
  "...kkkkkKKK.",
  "....kkkkkyKKK",
  ".....kkkkkk..",
  "......fff....",
}

------------------------------------------------------------------ down / feathers
local DOWN = A {          -- lying on its side, wing flopped, feet up
  "......f.f...",
  "......f.f...",
  "..KKKkkkkK..",
  "KKkkkkkkkkKK",
  "kkkKKKKkkkkK",
}
local FEATHER = { A { "KK.", ".kk" }, A { ".K", "Kk", "k." }, A { "kK." , "..k"} }
local function feather(c, x, y, k, col)
  local f = FEATHER[(k % #FEATHER) + 1]
  K.put(c, f, x, y, col and { col = col })
end

------------------------------------------------------------------ animation
local BX, BY = 8, 30      -- branch left, top
local function perch(body, dx, dy)
  local c = K.canvas()
  K.foot(c, BRANCH, BX, 31)
  K.foot(c, body or PERCH, BX + 3 + (dx or 0), BY - 1 + (dy or 0))
  return c
end

local function draw(tag, i)
  if tag == "idle" then
    local P = { PERCH, PERCH_FLUFF, PERCH_BLINK, PERCH_CAW }
    return perch(P[i + 1])
  end

  if tag == "run" then
    local W = { WING.up, WING.mid, WING.down, WING.mid }
    local c = K.canvas()
    local dy = ({ 0, 1, 2, 1 })[i + 1]
    fly(c, 9, 20 + dy, W[i + 1])
    return c
  end

  if tag == "attack" then
    local c
    if i == 0 then
      c = perch(CROUCH)
    elseif i == 1 then
      c = K.canvas(); K.foot(c, BRANCH, BX, 31); fly(c, 8, 17, WING.up)
    elseif i == 2 then
      c = K.canvas(); K.put(c, DIVE, 13, 16)
      K.speed(c, 13, 14, 2, 3, MARK2, 2)
    elseif i == 3 then
      c = K.canvas(); K.put(c, PECK, 15, 22)
      K.bang(c, 28, 19)
      c:set(29, 26, MARK); c:set(30, 25, MARK); c:set(29, 28, MARK); c:set(30, 29, MARK)
    elseif i == 4 then
      c = K.canvas(); fly(c, 12, 18, WING.up)
    else
      c = K.canvas(); K.foot(c, BRANCH, BX, 31); fly(c, 9, 21, WING.down)
    end
    return c
  end

  if tag == "special" then
    -- swoop: drop in from the upper left, skim low, climb out to the upper right
    local path = { { 4, 9 }, { 6, 13 }, { 8, 17 }, { 10, 21 }, { 12, 22 }, { 14, 20 }, { 15, 16 }, { 16, 12 } }
    local W = { WING.up, WING.glide, WING.glide, WING.glide, WING.down, WING.mid, WING.up, WING.mid }
    local p = path[i + 1]
    local c = K.canvas()
    fly(c, p[1], p[2], W[i + 1])
    if i >= 2 and i <= 5 then K.speed(c, p[1] - 1, p[2] + 1, 2, 4 + (i % 2), MARK, i) end
    return c
  end

  local function hurt(col)
    local c = K.canvas()
    fly(c, 8, 18, WING.up, BODY_TALON, col)
    return c
  end
  if tag == "hit" then
    if i == 0 then return hurt(K.FLASH) end
    if i == 3 then return perch() end
    local c = K.canvas()
    fly(c, 7 - (i - 1), 18 + (i - 1), WING.down, BODY_TALON)
    K.bang(c, 25 - (i - 1), 13 + (i - 1))
    feather(c, 4 + i, 14 + i * 2, i)
    return c
  end

  if tag == "death" then
    if i == 0 then
      local c = hurt(); K.bang(c, 25, 13); return c
    end
    if i == 1 then
      local c = K.canvas(); fly(c, 9, 20, WING.down, BODY_TALON)
      feather(c, 6, 15, 0); feather(c, 23, 13, 1); return c
    end
    if i == 2 then
      local c = K.canvas(); K.put(c, K.rot(DIVE, 1), 10, 19)
      feather(c, 5, 18, 2); feather(c, 24, 14, 0); feather(c, 15, 11, 1); return c
    end
    local c = K.canvas()
    K.foot(c, DOWN, 11, 31)
    local spread = (i - 3)
    local F = { { 6, 20 }, { 23, 18 }, { 15, 13 }, { 9, 25 }, { 25, 24 } }
    for k, f in ipairs(F) do
      local fx = f[1] + (f[1] < 16 and -spread or spread)
      local fy = math.min(29, f[2] + spread * 2)
      feather(c, fx, fy, k + i)
    end
    if i >= 4 and i <= 6 then K.dizzy(c, 14, 19 - (i - 4), i) end
    return c
  end
end

return K.build("forest_crow", draw)
