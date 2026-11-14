-- Will-o'-wisp enemy: "Spirit - Ranged - Erratic" (concepts/enemies_concept_2.png, row 5).
-- Frames are built from the 9 hand-fixed concept poses in will_o_wisp_poses.lua:
--   1 idle  2 flicker  3 lean  4 dash start  5 dash  6 full streak  7 glowing orb  8 settle  9 idle
-- attack = spits a fireball, special = erratic blink (streaks off, vanishes, reappears glowing),
-- death = flares white and scatters into embers.
-- Run inside Aseprite:  _G.REVIEW = "<png>"; spr = dofile(".../enemy_gen/will_o_wisp.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local K, P = L.poses(HERE .. "/will_o_wisp_poses.lua")

local function pose(n, dx, dy) return P[n]:shifted(dx or 0, dy or 0) end
local ORB = { ".ooo.", "o5wwo", "owwwo", "o45wo", ".ooo." }
local function orb(c, x, y, tail)
  for k = 1, tail or 0 do c:set(x - k, y + 1 + (k % 2), (k <= 2) and K["3"] or K["2"]) end
  return L.grid(ORB, K, x, y, c)
end
local function sparks(c, pts, big)
  for k, q in ipairs(pts) do L.sparkle(c, q[1], q[2], (k % 2 == 0) and K["4"] or K["3"], big and 1 or 0, K.w) end
  return c
end
-- burning white: the whole flame in its lightest shades
local function white(c)
  return c:recolor(function(v) return (v == K.o) and K["3"] or ((v == K.w or v == K["5"]) and K.w or K["5"]) end)
end

local function draw(tag, i, n)
  if tag == "idle" then
    return pose(({ 1, 2, 9, 8 })[i + 1])

  elseif tag == "run" then
    return ({ pose(3), pose(4), pose(5), pose(4, 0, -1) })[i + 1]

  elseif tag == "attack" then
    if i == 0 then return pose(8, -1) end
    if i == 1 then return pose(7) end
    if i == 2 then return orb(pose(1, -3), 25, 17, 2) end
    if i == 3 then return orb(pose(2, -4), 27, 16, 4) end
    if i == 4 then return sparks(pose(9, -2), { { 30, 15 }, { 28, 20 } }, true) end
    return pose(1)

  elseif tag == "special" then
    if i == 0 then return pose(8) end
    if i == 1 then return pose(4) end
    if i == 2 then return pose(6, 2) end
    if i == 3 then return sparks(L.canvas(), { { 6, 18 }, { 12, 12 }, { 20, 22 }, { 25, 14 }, { 15, 27 } }, true) end
    if i == 4 then return sparks(L.canvas(), { { 10, 16 }, { 15, 13 }, { 19, 20 }, { 22, 15 }, { 14, 24 } }, true) end
    if i == 5 then return pose(7) end
    if i == 6 then return pose(8) end
    return pose(1)

  elseif tag == "hit" then
    if i == 0 then return pose(1):flash() end
    if i == 3 then return pose(1) end
    local c = pose(3, i == 1 and -2 or -1)
    if i == 1 then L.impact(c, 25, 4) else L.impact(c, 26, 5) end
    return c

  elseif tag == "death" then
    if i == 0 then return pose(3, -1) end
    if i == 1 then return pose(7) end
    if i == 2 then return white(pose(7)) end
    local rings = {
      { { 8, 10 }, { 16, 6 }, { 24, 10 }, { 27, 18 }, { 23, 26 }, { 9, 26 }, { 5, 18 }, { 16, 19 } },
      { { 6, 9 }, { 16, 4 }, { 26, 9 }, { 29, 18 }, { 25, 28 }, { 7, 28 }, { 3, 18 } },
      { { 5, 12 }, { 27, 12 }, { 28, 24 }, { 4, 25 }, { 16, 7 } },
      { { 6, 18 }, { 26, 20 }, { 15, 12 } },
      { { 12, 26 }, { 21, 28 } },
    }
    local k = i - 2
    if k <= 5 and rings[k] then return sparks(L.canvas(), rings[k], true) end
    return sparks(L.canvas(), { { 16, 29 } }, true)
  end
end

-- the concept's one-pixel flame flecks read as dirt at 1x, so lone pixels go
return L.build("will_o_wisp", HERE .. "/..", function(...) return draw(...):despeckle() end, REVIEW)
