-- Forest stag enemy: "Swift - Leaping - Territorial" (concepts/enemies_concept_2.png, row 2).
-- Frames are built from the 9 hand-fixed concept poses in forest_stag_poses.lua:
--   1 stand  2 crouch  3 push-off  4 rising  5 apex  6 descending  7 landing  8 absorb  9 stand
-- attack = lowered-antler charge (pose 2), special = the full leap (2 > 9), death = collapse on its side.
-- Run inside Aseprite:  _G.REVIEW = "<png>"; spr = dofile(".../enemy_gen/forest_stag.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local K, P = L.poses(HERE .. "/forest_stag_poses.lua")
local DUST = { L.MARK2, K.a, K.b }

local function pose(n, dx, dy) return P[n]:shifted(dx or 0, dy or 0) end
local function eyes(c, mode) return L.eyes(c, K.y, mode, K.o, K["4"]) end
local function sink(c, line, d) return c:move(function(_, y) return y < line end, 0, d) end
-- head, neck top and antlers move together
local function nod(c, dx, dy, y1) return c:move(function(x, y) return x >= 9 and y <= (y1 or 18) end, dx, dy) end
-- tail flash flicks up
local function tail(c, d)
  return c:move(function(x, y, v) return x <= 8 and y >= 19 and y <= 24 and (v == K.b or v == K.c) end, 0, -d)
end
local function dust(c, x, y, r, seed) L.puff(c, x, y, r, DUST, seed) end
local function swoosh(c, x0, y0, cx, cy, x1, y1, col, w)
  c:curve(x0, y0, cx, cy, x1, y1, col, function(t) return 0.2 + w * math.sin(t * math.pi) end, 10)
end

local function draw(tag, i, n)
  if tag == "idle" then
    if i == 0 then return pose(1) end
    if i == 1 then return tail(sink(pose(1), 26, 1), 1) end
    if i == 2 then return nod(sink(pose(1), 26, 1), 0, 1) end
    return nod(pose(1), 0, 1)

  elseif tag == "run" then
    local c = L.canvas()
    if i == 0 then dust(c, 3, 29.6, 1.5, 3) end
    if i == 3 then dust(c, 2, 29.4, 1.3, 7) end
    local s = ({ { 3, 0, 0 }, { 4, 0, 2 }, { 6, 0, 2 }, { 8, 0, 0 } })[i + 1]
    return c:over(pose(s[1], s[2], s[3]))

  elseif tag == "attack" then
    if i == 0 then return eyes(tail(pose(1, -1), 1), "angry") end
    if i == 1 then return pose(2, -2) end
    if i == 2 or i == 3 then
      local c = pose(2, 2)
      if i == 2 then swoosh(c, 25, 7, 34, 13, 30, 24, L.FLASH, 1.0)
      else swoosh(c, 28, 10, 33, 16, 30, 23, L.MARK2, 0.5) end
      return c:despeckle()
    end
    if i == 4 then return pose(8) end
    return pose(9)

  elseif tag == "special" then
    local c = L.canvas()
    if i >= 2 and i <= 4 then L.shadow(c, 16, 30.6, ({ 6, 5, 6 })[i - 1], L.rgb("#24202a")) end
    if i == 1 then dust(c, 4, 29.6, 1.6, 21) end
    c:over(pose(i + 2))
    if i == 6 then dust(c, 26, 29.8, 1.3, 23) end
    return c

  elseif tag == "hit" then
    if i == 0 then return pose(1, -1):flash() end
    if i == 3 then return pose(1) end
    local c = eyes(tail(pose(1, i == 1 and -1 or 0), 1), "shut")
    if i == 1 then L.impact(c, 26, 9) else L.impact(c, 27, 10) end
    return c

  elseif tag == "death" then
    if i == 0 then return eyes(pose(1, -1), "shut") end
    if i == 1 then return eyes(pose(8), "shut") end
    if i == 2 then return eyes(sink(pose(2), 28, 2), "x") end
    -- the stretched mid-air pose laid on the ground reads as a stag fallen on its side
    local c = L.canvas()
    if i == 3 then dust(c, 3, 29.6, 1.7, 61); dust(c, 28, 29.8, 1.5, 62) end
    if i == 4 then dust(c, 2, 29.2, 1.2, 63) end
    local body = eyes(pose(6, -1, 7), "x")
    if i == 4 or i == 6 then body = sink(body, 27, 1) end
    c:over(body)
    if i >= 4 and i <= 6 then L.dizzy(c, 23, 9 - (i - 4) // 2, i) end
    return c:despeckle()
  end
end

return L.build("forest_stag", HERE .. "/..", function(...) return draw(...):despeckle() end, REVIEW)
