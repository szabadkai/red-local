-- Raven enemy: "Aerial - Harassing - Mob" (concepts/enemies_concept_2.png, row 3).
-- Frames are built from the 9 hand-fixed concept poses in raven_poses.lua:
--   1 perched  2 take-off  3 wings up  4 downstroke  5 glide  6 hover  7 flap  8 landing  9 perched
-- run = flight loop, attack = swooping peck, special = calls a mob of ravens and dives with them,
-- death = tumbles to the ground in a puff of feathers.
-- Run inside Aseprite:  _G.REVIEW = "<png>"; spr = dofile(".../enemy_gen/raven.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local K, P = L.poses(HERE .. "/raven_poses.lua")
local FEATHER = { K["2"], K["3"], K["4"] }

-- the eye is the top-left yellow pixel (the beak is yellow too)
local function eyeAt(c)
  local f = c:find(K.y)
  return f[1][1], f[1][2]
end
local function pose(n, dx, dy) return P[n]:shifted(dx or 0, dy or 0) end
-- flight poses are lined up on the eye so the bird hovers in place; dy is the wingbeat bob
local function fly(n, dx, dy)
  local x, y = eyeAt(P[n])
  local c = P[n]:shifted(21 - x + (dx or 0), 11 - y + (dy or 0))
  c:set(31, 0, nil); c:set(0, 0, nil)         -- the wings-up span is wider than the frame; keep corners clear
  return c
end
local function eye(c, mode)
  local x, y = eyeAt(c)
  if mode == "shut" then c:set(x, y, K["2"]); c:set(x, y + 1, K.o); c:set(x - 1, y + 1, K.o)
  elseif mode == "x" then
    c:set(x, y, K["2"]); c:set(x, y + 1, K["2"])
    c:dots({ { x - 1, y - 1 }, { x + 1, y - 1 }, { x, y }, { x - 1, y + 1 }, { x + 1, y + 1 } }, K.y)
  end
  return c
end
local function sink(c, line, d) return c:move(function(_, y) return y < line end, 0, d) end
-- loose feathers: short two-pixel quills
local function feathers(c, pts)
  for k, q in ipairs(pts) do
    local col = FEATHER[(k % 3) + 1]
    c:set(q[1], q[2], col); c:set(q[1] + (q[3] or 1), q[2] + 1, col)
  end
  return c
end
-- far-off mob ravens: little "v" silhouettes, wings up (1) or down (0)
local function mini(c, x, y, up)
  local rows = up == 1 and { "o.....o", "oo...oo", ".ooooo.", "...o..." } or { ".......", "..ooo..", "ooooooo", "o..o..o" }
  return L.grid(rows, { o = K.o }, x, y, c)
end

local function draw(tag, i, n)
  if tag == "idle" then
    local nod = function(c) return c:move(function(x, y) return x >= 18 and y <= 22 end, 0, 1) end
    return ({ pose(1), sink(pose(1), 27, 1), nod(sink(pose(1), 27, 1)), nod(pose(1)) })[i + 1]

  elseif tag == "run" then
    return ({ fly(3, -1, 3), fly(4, 0, 0), fly(6, 0, 1), fly(7, 0, 0) })[i + 1]

  elseif tag == "attack" then
    if i == 0 then return pose(2) end
    if i == 1 then return fly(3, -1, 2) end
    local c = L.canvas()
    if i == 2 then L.streaks(c, 9, 9, 3, 6, L.MARK2, 2); c:over(fly(5, 1, 3)) end
    if i == 3 then
      c:over(fly(5, 3, 4))
      L.sparkle(c, 30, 18, L.MARK2, 1, L.FLASH)
    end
    if i == 4 then c:over(pose(8)) end
    if i == 5 then c:over(pose(1)) end
    return c

  elseif tag == "special" then
    local c = L.canvas()
    local mob = {
      {}, { { 3, 2, 1 } }, { { 2, 3, 0 }, { 26, 1, 1 } }, { { 1, 2, 1 }, { 25, 0, 0 }, { 8, 0, 1 } },
      { { 3, 4, 0 }, { 27, 2, 1 }, { 10, 1, 0 } }, { { 6, 8, 1 }, { 1, 14, 0 } }, { { 1, 4, 0 } }, {},
    }
    for _, m in ipairs(mob[i + 1]) do mini(c, m[1], m[2], m[3]) end
    if i == 0 then return c:over(pose(1)) end
    if i == 1 then return c:over(pose(2)) end
    if i == 2 then return c:over(fly(3, -1, 2)) end
    if i == 3 then return c:over(fly(4, 0, -1)) end
    if i == 4 then L.streaks(c, 10, 10, 3, 7, L.MARK2, 5); return c:over(fly(5, 1, 3)) end
    if i == 5 then c:over(fly(5, 2, 5)); return feathers(c, { { 29, 22 }, { 27, 26, -1 }, { 30, 27 } }) end
    if i == 6 then return c:over(fly(6, 0, 0)) end
    return c:over(pose(8))

  elseif tag == "hit" then
    if i == 0 then return pose(1, -1):flash() end
    if i == 3 then return pose(1) end
    local c = eye(pose(1, i == 1 and -2 or -1), "shut")
    feathers(c, i == 1 and { { 6, 20 }, { 4, 23, -1 } } or { { 5, 19 }, { 3, 24, -1 } })
    if i == 1 then L.impact(c, 25, 15) else L.impact(c, 26, 16) end
    return c

  elseif tag == "death" then
    if i == 0 then return eye(pose(1, -1), "shut") end
    if i == 1 then return eye(fly(2, 0, 4), "x") end
    -- glide pose dropped on the ground: wings splayed, belly down
    local x0, y0, x1, y1 = L.bounds(P[5])
    local down = eye(pose(5, 0, 31 - y1), "x")
    if i == 3 or i == 5 then down = sink(down, 29, 1) end
    local c = L.canvas()
    c:over(down)
    if i == 2 then feathers(c, { { 6, 10 }, { 14, 6, -1 }, { 24, 8 }, { 9, 14 } }) end
    if i == 3 then feathers(c, { { 5, 13 }, { 13, 10, -1 }, { 25, 12 }, { 8, 18 } }) end
    if i == 4 then feathers(c, { { 4, 17 }, { 12, 15, -1 }, { 26, 17 } }) end
    if i == 5 then feathers(c, { { 3, 22 }, { 27, 22 } }) end
    if i >= 4 and i <= 6 then L.dizzy(c, 15, 12 - (i - 4) // 2, i) end
    return c
  end
end

return L.build("raven", HERE .. "/..", function(...) return draw(...):despeckle() end, REVIEW)
