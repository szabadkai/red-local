-- Ghost hunter enemy: "Cursed - Relentless - Melee" (concepts/enemies_concept_2.png, row 6).
-- Frames are built from the 9 hand-fixed concept poses in ghost_hunter_poses.lua:
--   1 stand  2 step  3 crouch  4 lunge  5 thrust  6 recover  7-9 settle back to stand
-- attack = spear thrust (3 > 4 > 5), special = cursed dash (fades to a shade, darts forward, stabs),
-- death = the cloak collapses into an empty heap and the eyes go out.
-- Run inside Aseprite:  _G.REVIEW = "<png>"; spr = dofile(".../enemy_gen/ghost_hunter.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local K, P = L.poses(HERE .. "/ghost_hunter_poses.lua")
local DUST = { L.MARK2, K.c, K.d }

local function pose(n, dx, dy) return P[n]:shifted(dx or 0, dy or 0) end
local function eyes(c, mode) return L.eyes(c, K.y, mode, K.o, K["1"], K.y) end
local function sink(c, line, d) return c:move(function(_, y) return y < line end, 0, d) end
local function dust(c, x, y, r, seed) L.puff(c, x, y, r, DUST, seed) end

-- spear held level: dark shaft, pale blade, own outline so it reads against the body
local function spear(c, x0, x1, y)
  local s = L.canvas()
  s:line(x0, y, x1 - 2, y, K["3"])
  s:line(x1 - 2, y, x1, y, K.f); s:set(x1 - 2, y - 1, K.f); s:set(x1 - 2, y + 1, K.e)
  s:outline(K.o)
  return c:over(s)
end
-- the cursed shade: the pose as a flat silhouette with only the eyes left
local function shade(c)
  return c:recolor(function(v) return (v == K.y) and K.y or ((v == K.o) and K["1"] or K.c) end)
end

local function draw(tag, i, n)
  if tag == "idle" then
    return pose(({ 1, 9, 8, 9 })[i + 1])

  elseif tag == "run" then
    local c = L.canvas()
    if i == 1 then dust(c, 6, 29.6, 1.4, 3) end
    if i == 3 then dust(c, 4, 29.6, 1.3, 7) end
    return c:over(({ pose(2), pose(3), pose(7), sink(pose(3), 26, 1) })[i + 1])

  elseif tag == "attack" then
    if i == 0 then return spear(pose(3, -1), 12, 22, 21) end
    if i == 1 then return spear(pose(4, -2), 14, 29, 21) end
    if i == 2 then
      local c = spear(pose(5, -3), 13, 29, 22)
      c:line(30, 22, 31, 22, L.FLASH); c:line(25, 25, 28, 25, L.FLASH)
      return c
    end
    if i == 3 then
      local c = spear(pose(5, -2), 14, 30, 22)
      c:line(26, 25, 28, 25, L.MARK2)
      return c
    end
    if i == 4 then return spear(pose(6, -1), 16, 28, 21) end
    return pose(1)

  elseif tag == "special" then
    if i == 0 then return pose(3) end
    if i == 1 then return shade(pose(3)) end
    if i == 2 or i == 3 then
      local c = L.canvas()
      L.streaks(c, 10 + 2 * i, 13, 4, 6 + 2 * i, (i == 2) and K.c or L.MARK2, i)
      c:over(shade(pose(4, -4 + 3 * (i - 2))))
      return c
    end
    if i == 4 then
      local c = spear(pose(5, -3), 13, 29, 22)
      c:line(30, 22, 31, 22, L.FLASH); c:line(24, 25, 28, 25, L.FLASH)
      L.streaks(c, 8, 12, 3, 6, L.MARK2, 9)
      return c
    end
    if i == 5 then return spear(pose(6, -1), 16, 28, 21) end
    if i == 6 then return pose(7) end
    return pose(9)

  elseif tag == "hit" then
    if i == 0 then return pose(1, -1):flash() end
    if i == 3 then return pose(1) end
    local c = eyes(pose(1, i == 1 and -2 or -1), "squint")
    if i == 1 then L.impact(c, 25, 2) else L.impact(c, 26, 3) end
    return c

  elseif tag == "death" then
    if i == 0 then return eyes(pose(1, -1), "squint") end
    if i == 1 then return eyes(sink(pose(3), 27, 2), "squint") end
    if i == 2 then return eyes(sink(pose(3), 30, 5), "x") end
    local c = L.canvas()
    if i == 3 then dust(c, 4, 29.6, 1.8, 61); dust(c, 27, 29.8, 1.5, 62) end
    local heap = sink(pose(3, 1), 31, 9 + ((i == 4 or i == 6) and 1 or 0)):keep(function(_, y) return y <= 31 end)
    heap = eyes(heap, "x")
    -- the curse lifts: the eyes go out on the last frame
    if i == 7 then heap = heap:recolor(function(v) return (v == K.y) and K["2"] or v end) end
    c:over(heap)
    if i >= 4 and i <= 6 then L.dizzy(c, 19, 12 - (i - 4) // 2, i) end
    return c
  end
end

return L.build("ghost_hunter", HERE .. "/..", function(...) return draw(...):despeckle() end, REVIEW)
