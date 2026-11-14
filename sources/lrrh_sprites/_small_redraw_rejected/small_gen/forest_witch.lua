-- Forest witch at red-local scale (21 px tall with the hood point): purple pointed hood
-- over a shadowed face with glowing eyes and a long nose, bell cloak, crooked staff.
-- attack = magic orb, special = staff raise that calls purple spikes out of the ground.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local K = dofile(HERE .. "/kit.lua")

local MAP = {
  P = "#8d44d8", p = "#41198a",                 -- hood / cloak
  v = "#1e1038",                                -- face shadow, feet
  G = "#ffc2ff", g = "#ffc2ff",                 -- glowing eyes (top / bottom), magic light
  s = "#f2c4b4",                                -- skin (nose, hand)
  W = "#c08046", w = "#69391f",                 -- staff wood
  m = "#e45cff",                                -- magic
  X = "#f6ecee",                                -- magic core (same white as the marks)
}
local function A(rows) return K.art(rows, MAP) end
local COL = {}
for k, v in pairs(MAP) do COL[k] = K.rgb(v) end

------------------------------------------------------------------ parts (16 cols wide)
local HEAD = A {
  "..pP............",
  "...pPP..........",
  "....pPP.........",
  "....pPPPPP......",
  "...pPPPPPPPP....",
  "..pPPPPPPPPPP...",
  ".pPPPPPPPvvvvP..",
  ".pPPPPPPvvvvvvP.",
  ".pPPPPPPvvGvvGP.",
  ".pPPPPPPvvgvvgss",
  ".ppPPPPPPvvvvvP.",
  "..ppPPPPPPPPPP..",
}
local HEAD_BLINK = K.swap(HEAD, { G = "v" }, MAP)
local HEAD_HURT = K.swap(HEAD, { G = "v", g = "m" }, MAP)
local HEAD_TIP = A {   -- hood point blown back (run / dash)
  "................",
  ".ppP............",
  "...pPP..........",
  "....pPPPPP......",
  "...pPPPPPPPP....",
  "..pPPPPPPPPPP...",
  ".pPPPPPPPvvvvP..",
  ".pPPPPPPvvvvvvP.",
  ".pPPPPPPvvGvvGP.",
  ".pPPPPPPvvgvvgss",
  ".ppPPPPPPvvvvvP.",
  "..ppPPPPPPPPPP..",
}

local BODY = {
  idle = A {
    "...pPPPPPPPPP...",
    "..ppPPPPPPPPPP..",
    "..pPPPPPpPPPPP..",
    ".ppPPPPPpPPPPPP.",
    ".pPPPPPpPPPPPPP.",
    ".pPPPPPpPPPPPPP.",
    "ppPPPPpPPPPPPPPP",
    "pPPPPPpPPPPPPPPP",
    "ppPPPPpPPPPPPPPP",
  },
  idle2 = A {   -- hem sways
    "...pPPPPPPPPP...",
    "..ppPPPPPPPPPP..",
    "..pPPPPPpPPPPP..",
    "..pPPPPPpPPPPPP.",
    ".ppPPPPPpPPPPPP.",
    ".pPPPPPpPPPPPPP.",
    ".pPPPPPpPPPPPPPP",
    "ppPPPPPpPPPPPPPP",
    "pPPPPPpPPPPPPPP.",
  },
  runA = A {    -- hem flung back, near foot out front
    "...pPPPPPPPPP...",
    "..ppPPPPPPPPPP..",
    ".ppPPPPPpPPPPP..",
    "ppPPPPPPpPPPPPP.",
    "pPPPPPPpPPPPPPP.",
    "ppPPPPPpPPPPPPP.",
    "..pPPPpPPPPPPPPP",
    "...ppPpPPPPPPPP.",
    "....vv.....vv...",
  },
  runB = A {
    "...pPPPPPPPPP...",
    "..ppPPPPPPPPPP..",
    ".ppPPPPPpPPPPP..",
    "pPPPPPPPpPPPPPP.",
    "ppPPPPPpPPPPPPP.",
    ".ppPPPPpPPPPPPP.",
    "..ppPPpPPPPPPPP.",
    "...ppPpPPPPPPP..",
    ".......vvv......",
  },
  crouch = A {  -- squashed: bracing / slumping
    "..ppPPPPPPPPPP..",
    ".ppPPPPPpPPPPPP.",
    ".pPPPPPpPPPPPPP.",
    "ppPPPPPpPPPPPPPP",
    "pPPPPPpPPPPPPPPP",
    "ppPPPPpPPPPPPPPP",
    "pppPPpPPPPPPPPPP",
  },
}
-- crooked staff, 19 tall: crook curls back over the hand, shaft in col 3
local STAFF = A {
  ".WW.", "W..W", "w..W", "...W", "...W", "...w", "...W", "...W", "...W", "...W",
  "...W", "...w", "...W", "...W", "...W", "...W", "...W", "...w", "...W",
}
local HEAP = A {  -- collapsed: cloak puddle, hood flopped on top (eyes dark)
  "........ppPP....",
  "......ppPPPPPP..",
  "...pPPPPPPPvvvP.",
  "..pPPPPPPPvvvvss",
  ".pPPPPPPPPPvvvP.",
  "ppPPPPPPpPPPPPPP",
}
local ORB_S = A { ".m.", "mGm", ".m." }
local ORB_L = A { ".mm.", "mGGm", "mGXm", ".mm." }

------------------------------------------------------------------ figure
local OX, OY = 7, 11   -- top-left of the 16x21 figure box when standing (hem on y = 31)
-- o: ox, oy, hx, hy (head offset), head, body, by,
--    staff = {x, y} top-left of the staff (figure coords; nil = no staff),
--    staffArt, hand = {x, y} front hand (figure coords), orb = {x, y, big}
local function fig(o)
  local c = K.canvas()
  local X, Y = OX + (o.ox or 0), OY + (o.oy or 0)
  local body = o.body or BODY.idle
  local bt = Y + 21 - body.h + (o.by or 0)
  local d = bt - (Y + 12)
  K.put(c, body, X, bt)
  K.put(c, o.head or HEAD, X + (o.hx or 0), bt - 12 + (o.hy or 0))
  if o.staff ~= false then
    local st = o.staff or { 15, 2 }
    K.put(c, o.staffArt or STAFF, X + st[1], Y + st[2])
  end
  local hand = o.hand or { 17, 15 }
  local from = o.armFrom or { 12, 14 }
  local hx, hy = X + hand[1], Y + d + hand[2]
  local fx, fy = X + from[1], Y + d + from[2]
  c:line(fx, fy, hx - (hx >= fx and 1 or -1), hy, COL.p)
  c:set(hx, hy, COL.s)
  return c
end

-- crystal spike growing out of the ground at column x, h px tall: a light core with
-- a lit right face and a shaded left face that start halfway down; peak = white tip
local function spike(c, x, h, peak)
  if h <= 0 then return end
  local top = 31 - h + 1
  local side = top + math.max(1, h // 2)
  for y = side, 31 do c:set(x - 1, y, COL.p); c:set(x + 1, y, COL.m) end
  for y = top + 1, 31 do c:set(x, y, COL.G) end
  c:set(x, top, peak and K.MARK or COL.m)
end
local function spikes(c, hs, peak)
  local xs = { 18, 22, 25, 29 }
  for k, x in ipairs(xs) do spike(c, x, hs[k] or 0, peak) end
end

------------------------------------------------------------------ animation
local function draw(tag, i)
  if tag == "idle" then
    local P = {
      { },
      { hy = 1 },
      { hy = 1, body = BODY.idle2, head = HEAD_BLINK },
      { body = BODY.idle2, hand = { 17, 14 } },
    }
    return fig(P[i + 1])
  end

  if tag == "run" then
    -- a hurried shuffle: hem swinging, staff carried off the ground
    local P = {
      { hx = 1, head = HEAD_TIP, body = BODY.runA, staff = { 16, 1 }, hand = { 18, 14 } },
      { hx = 1, oy = -1, head = HEAD_TIP, body = BODY.runB, staff = { 16, 1 }, hand = { 18, 14 } },
      { hx = 1, head = HEAD_TIP, body = BODY.runA, staff = { 15, 1 }, hand = { 17, 14 } },
      { hx = 1, oy = -1, head = HEAD_TIP, body = BODY.runB, staff = { 15, 1 }, hand = { 17, 14 } },
    }
    local c = fig(P[i + 1])
    if i == 0 or i == 2 then K.dust(c, OX + 3, 31, i) end
    return c
  end

  if tag == "attack" then
    -- free hand gathers a spark, thrusts, orb flies out, bursts at range, settle
    local P = {
      { hx = -1, body = BODY.idle2, armFrom = { 11, 15 }, hand = { 13, 16 } },
      { hx = 1, armFrom = { 12, 14 }, hand = { 17, 13 } },
      { hx = 1, armFrom = { 12, 14 }, hand = { 18, 13 } },
      { hx = 1, armFrom = { 12, 14 }, hand = { 18, 13 } },
      { body = BODY.idle2, armFrom = { 12, 14 }, hand = { 17, 14 } },
      { body = BODY.idle2, hand = { 17, 15 } },
    }
    local c = fig(P[i + 1])
    local X, Y = OX, OY
    if i == 0 then
      K.sparkle(c, X + 14, Y + 15, COL.m, 1, COL.G)
    elseif i == 1 then
      K.put(c, ORB_S, X + 18, Y + 12)
    elseif i == 2 then
      K.put(c, ORB_L, X + 19, Y + 11)
      c:set(X + 17, Y + 11, COL.m); c:set(X + 16, Y + 14, COL.m)
    elseif i == 3 then
      K.put(c, ORB_L, X + 22, Y + 11)
      c:line(X + 19, Y + 12, X + 21, Y + 12, COL.m); c:set(X + 18, Y + 14, COL.m); c:set(X + 20, Y + 14, COL.G)
    elseif i == 4 then
      K.sparkle(c, 28, Y + 12, COL.m, 2, K.MARK)
      c:set(25, Y + 10, COL.G); c:set(26, Y + 15, COL.m)
    end
    return c
  end

  if tag == "special" then
    -- staff hoisted, crook flares, staff stamps down, spikes erupt in front, sink back
    local P = {
      { hy = 1, body = BODY.idle2, staff = { 15, 0 }, hand = { 17, 13 } },
      { hx = -1, staff = { 15, -3 }, hand = { 17, 10 }, armFrom = { 12, 13 } },
      { hx = 1, by = 1, body = BODY.crouch, staff = { 16, 2 }, hand = { 18, 14 } },
      { hx = 1, by = 1, body = BODY.crouch, staff = { 16, 2 }, hand = { 18, 14 } },
      { hx = 1, staff = { 16, 2 }, hand = { 18, 14 } },
      { hx = 1, body = BODY.idle2, staff = { 16, 2 }, hand = { 18, 15 } },
      { body = BODY.idle2, hand = { 17, 15 } },
      { },
    }
    local c = fig(P[i + 1])
    local X, Y = OX, OY
    if i == 0 then
      K.sparkle(c, X + 17, Y - 1, COL.m, 0)
    elseif i == 1 then
      K.sparkle(c, X + 17, Y - 5, COL.m, 1, K.MARK)
    elseif i == 2 then
      spikes(c, { 1, 2, 1, 0 })
      K.sparkle(c, X + 17, Y + 3, COL.m, 0)
    elseif i == 3 then
      spikes(c, { 4, 6, 3, 2 })
    elseif i == 4 then
      spikes(c, { 6, 9, 7, 4 }, true)
    elseif i == 5 then
      spikes(c, { 5, 7, 8, 6 })
    elseif i == 6 then
      spikes(c, { 2, 3, 4, 3 })
      c:set(20, 24, COL.m); c:set(26, 22, COL.G); c:set(29, 25, COL.m)
    elseif i == 7 then
      c:set(22, 30, COL.m); c:set(27, 29, COL.G)
    end
    return c
  end

  local HURT = { hx = -1, head = HEAD_HURT, body = BODY.idle2, staff = { 14, 2 }, hand = { 16, 14 }, armFrom = { 11, 14 } }
  if tag == "hit" then
    if i == 0 then return K.flashOf(fig(HURT)) end
    if i == 3 then return fig({ hy = 1, body = BODY.idle2 }) end
    local c = fig({ hx = -1 - (i - 1), ox = -(i - 1), head = HEAD_HURT, body = BODY.idle2,
                    staff = { 14 - (i - 1), 2 }, hand = { 16 - (i - 1), 14 }, armFrom = { 11, 14 } })
    K.bang(c, OX + 19 - (i - 1), OY + 1 + (i - 1))
    return c
  end

  if tag == "death" then
    if i == 0 then
      local c = fig(HURT); K.bang(c, OX + 19, OY + 1); return c
    end
    -- the dropped staff on its way down: shaft from the butt (bx, by) to the head (tx, ty)
    local function falling(c, bx, by, tx, ty)
      c:line(bx, by, tx, ty, COL.W)
      c:set(tx - 1, ty - 1, COL.W); c:set(tx - 2, ty - 1, COL.W); c:set(tx - 3, ty, COL.w)
    end
    if i == 1 then   -- sags, the staff tips forward out of her hand
      local c = fig({ hx = -1, hy = 2, head = HEAD_HURT, body = BODY.crouch, staff = false, hand = { 16, 16 }, armFrom = { 11, 15 } })
      falling(c, 22, 31, 28, 15)
      return c
    end
    if i == 2 then   -- folding down onto the cloak
      local c = fig({ hx = 1, hy = 4, head = HEAD_HURT, body = BODY.crouch, staff = false, hand = { 16, 17 }, armFrom = { 11, 16 } })
      falling(c, 15, 31, 30, 23)
      return c
    end
    local c = K.canvas()
    local dy = (i == 3) and -1 or 0
    K.put(c, K.rot(STAFF, 1), 12, 28)
    K.foot(c, HEAP, 5, 31 + dy)
    if i == 3 then K.dust(c, 5, 31, 0); K.dust(c, 22, 31, 1) end
    if i >= 4 and i <= 6 then
      K.dizzy(c, 15, 18 - (i - 4), i)
      c:set(9 + i, 23 - i, COL.m)   -- a last wisp of magic drifting up
    end
    return c
  end
end

return K.build("forest_witch", draw)
