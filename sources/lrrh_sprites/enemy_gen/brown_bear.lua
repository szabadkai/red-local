-- Brown bear enemy: "Heavy - Slow - Powerful" (concepts/enemies_concept_2.png, row 1).
-- Frames are built from the 9 hand-fixed concept poses in brown_bear_poses.lua:
--   1 stand  2 step  3 low prowl  4 lunge  5 roar  6 swipe  7 pounce  8 stand low  9 stand
-- attack = rearing claw swipe (poses 3 > 6 > 7), special = roar (5), death = collapse onto its belly.
-- Run inside Aseprite:  _G.REVIEW = "<png>"; spr = dofile(".../enemy_gen/brown_bear.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local K, P = L.poses(HERE .. "/brown_bear_poses.lua")
local DUST = { L.MARK2, K.m, K.n }

local function pose(n, dx, dy) return P[n]:shifted(dx or 0, dy or 0) end
local function eyes(c, mode) return L.eyes(c, K.y, mode, K.o, K["4"]) end
-- upper body (above the leg line) sinks by d: breathing, crouching, collapsing
local function sink(c, legline, d) return c:move(function(_, y) return y < legline end, 0, d) end
-- head region moves on its own (nod, recoil)
local function nod(c, x0, y1, dx, dy) return c:move(function(x, y) return x >= x0 and y <= y1 end, dx, dy) end
local function dust(c, x, y, r, seed) L.puff(c, x, y, r, DUST, seed) end
local function over(a, b) return a:copy():over(b) end

-- belly-down sprawl for the end of the death: prowl pose without legs, sunk to the ground
local function sprawl(t)
  local c = P[3]:keep(function(_, y) return y < 28 end)
  c = c:shifted(0, 4)
  if t then c = sink(c, 27, 1) end                                  -- slow breaths while knocked out
  eyes(c, "x")
  c:rect(2, 30, 6, 31, K["2"]); c:rect(21, 30, 26, 31, K["3"])     -- paws poking out
  c:set(26, 31, K.N); c:set(25, 31, K.N)
  local out = L.canvas()
  for k, v in pairs(c.p) do if v ~= K.o then out.p[k] = v end end
  return out:outline(K.o)
end

local function draw(tag, i, n)
  if tag == "idle" then
    if i == 0 then return pose(1) end
    if i == 1 then return sink(pose(1), 26, 1) end
    if i == 2 then return nod(sink(pose(1), 26, 1), 19, 21, 0, 1) end
    return nod(pose(1), 19, 21, 0, 1)

  elseif tag == "run" then
    local c = L.canvas()
    if i == 0 then dust(c, 3, 29.5, 1.6, 3) end
    if i == 2 then dust(c, 2, 29, 1.4, 5) end
    return c:over(pose(({ 2, 3, 4, 7 })[i + 1]))

  elseif tag == "attack" then
    if i == 0 then return pose(3) end
    if i == 1 then return (P[6]:split()) end                 -- reared, paw cocked
    if i == 2 then return pose(6) end                        -- swing arc
    local c = pose(7, 1)
    if i == 3 or i == 4 then                                 -- three claw streaks raking down
      local col, k = (i == 3) and L.FLASH or L.MARK2, (i == 3) and 0 or 2
      for j = 0, 2 do c:line(24 + 2 * j + k, 17 + k, 26 + 2 * j, 28 - j, col) end
      return c
    end
    return pose(8)

  elseif tag == "special" then
    if i == 0 then return sink(pose(3), 28, 1) end
    local body, marks = P[5]:split()
    local dim = function() return L.MARK2 end
    if i == 1 then return body end
    if i == 2 then return over(body, marks) end
    if i == 3 then return over(body:shifted(0, -1), marks:shifted(1, 0)) end
    if i == 4 then return over(body, marks:shifted(1, 0):recolor(dim)) end
    if i == 5 then return over(body, marks:shifted(2, 0):recolor(dim)) end
    if i == 6 then return pose(8) end
    return pose(9)

  elseif tag == "hit" then
    if i == 0 then return nod(pose(1), 19, 21, -1, -1):flash() end
    if i == 3 then return pose(1) end
    local c = eyes(nod(pose(1), 19, 21, i == 1 and -1 or 0, -1), "shut")
    if i == 1 then L.impact(c, 25, 9) else L.impact(c, 26, 10) end
    return c

  elseif tag == "death" then
    if i == 0 then return eyes(nod(pose(1), 19, 21, 0, -1), "shut") end
    if i == 1 then return eyes(sink(pose(3), 28, 1), "shut") end
    if i == 2 then return eyes(sink(pose(3), 28, 3), "x") end
    local c = L.canvas()
    if i == 3 then dust(c, 2, 29.5, 1.8, 61); dust(c, 29, 29.8, 1.5, 62) end
    if i == 4 then dust(c, 1, 29, 1.3, 63) end
    c:over(sprawl(i == 4 or i == 6))
    if i >= 4 and i <= 6 then L.dizzy(c, 20, 14 - (i - 4) // 2, i) end
    return c:despeckle()
  end
end

local function lit(tag, i, n) return L.rim(draw(tag, i, n), K["4"], K["5"], K.o) end

return L.build("brown_bear", HERE .. "/..", lit, REVIEW)
