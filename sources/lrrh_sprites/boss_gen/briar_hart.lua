-- The Briar Hart: story boss of Lantern Wood. The roster's forest stag, bigger and more detailed:
-- the same 9 concept poses (concepts/enemies_concept_2.png, row 2) converted on a 48 px cell by
-- enemy_gen/concept_convert.py (entry "stag_boss") into stag_boss_poses.lua, hand-fixed there,
-- then cleaned and lit by stag_detail.lua (rim light, body volume, fur strokes, shaded antlers).
-- The animation follows enemy_gen/forest_stag.lua with every coordinate scaled 1.5x:
--   attack = lowered-antler charge, special = the full leap, death = collapse on its side.
-- The first, rigged version (stiff, rejected) is in bosses/_briar_hart_v1/.
-- Run inside Aseprite: dofile(".../boss_gen/briar_hart.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local B = dofile(HERE .. "/blib.lua")
local L = B.L
local K, RAW = L.poses(HERE .. "/stag_boss_poses.lua")
local D = dofile(HERE .. "/stag_detail.lua")(L, K)
local P = {}
for n, c in ipairs(RAW) do P[n] = D.detail(D.clean(c)) end
local DUST = { L.MARK2, K.a, K.b }

local function pose(n, dx, dy) return P[n]:shifted(dx or 0, dy or 0) end
local function eyes(c, mode) return L.eyes(c, K.y, mode, K.o, K["4"]) end
local function sink(c, line, d) return c:move(function(_, y) return y < line end, 0, d) end
-- head, neck top and antlers move together
local function nod(c, dx, dy, y1) return c:move(function(x, y) return x >= 21 and y <= (y1 or 28) end, dx, dy) end
-- tail flash flicks up
local function tail(c, d)
  return c:move(function(x, y, v) return x <= 12 and y >= 28 and y <= 36 and (v == K.b or v == K.c) end, 0, -d)
end
local function dust(c, x, y, r, seed) L.puff(c, x, y, r, DUST, seed) end
local function swoosh(c, x0, y0, cx, cy, x1, y1, col, w)
  c:curve(x0, y0, cx, cy, x1, y1, col, function(t) return 0.3 + w * math.sin(t * math.pi) end, 14)
end

local function draw(tag, i, n)
  if tag == "idle" then
    if i == 0 then return pose(1) end
    if i == 1 then return tail(sink(pose(1), 39, 1), 1) end
    if i == 2 then return nod(sink(pose(1), 39, 1), 0, 1) end
    return nod(pose(1), 0, 1)

  elseif tag == "run" then
    local c = L.canvas()
    if i == 0 then dust(c, 4.5, 44.4, 2.2, 3) end
    if i == 3 then dust(c, 3, 44.1, 2.0, 7) end
    local s = ({ { 3, 0, 0 }, { 4, 0, 3 }, { 6, 0, 3 }, { 8, 0, 0 } })[i + 1]
    return c:over(pose(s[1], s[2], s[3]))

  elseif tag == "attack" then
    if i == 0 then return eyes(tail(pose(1, -2), 2), "angry") end
    if i == 1 then return pose(2, -3) end
    if i == 2 or i == 3 then
      local c = pose(2, 3)
      if i == 2 then swoosh(c, 37, 10, 50, 20, 45, 36, L.FLASH, 1.4)
      else swoosh(c, 42, 15, 49, 24, 45, 35, L.MARK2, 0.7) end
      return c:despeckle()
    end
    if i == 4 then return pose(8) end
    return pose(9)

  elseif tag == "special" then
    local c = L.canvas()
    if i >= 2 and i <= 4 then L.shadow(c, 24, 45.9, ({ 9, 7.5, 9 })[i - 1], L.rgb("#24202a")) end
    if i == 1 then dust(c, 6, 44.4, 2.4, 21) end
    c:over(pose(i + 2))
    if i == 6 then dust(c, 39, 44.7, 2.0, 23) end
    return c

  elseif tag == "hit" then
    if i == 0 then return pose(1, -2):flash() end
    if i == 3 then return pose(1) end
    local c = eyes(tail(pose(1, i == 1 and -2 or 0), 2), "shut")
    if i == 1 then L.impact(c, 40, 14) else L.impact(c, 41, 15) end
    return c

  elseif tag == "death" then
    if i == 0 then return eyes(pose(1, -2), "shut") end
    if i == 1 then return eyes(pose(8), "shut") end
    if i == 2 then return eyes(sink(pose(2), 42, 3), "x") end
    -- the stretched mid-air pose laid on the ground reads as a stag fallen on its side
    local c = L.canvas()
    if i == 3 then dust(c, 4.5, 44.4, 2.5, 61); dust(c, 42, 44.7, 2.2, 62) end
    if i == 4 then dust(c, 3, 43.8, 1.8, 63) end
    local body = eyes(pose(6, -2, 10), "x")
    if i == 4 or i == 6 then body = sink(body, 40, 1) end
    c:over(body)
    if i >= 4 and i <= 6 then L.dizzy(c, 34, 13 - (i - 4) // 2, i) end
    return c:despeckle()
  end
end

return B.build("briar_hart", function(...) return draw(...):despeckle() end)
