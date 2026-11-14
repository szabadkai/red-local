-- Wild boar enemy: "Charging brute - Tough / Charge / Knockback" (2026-11-09 redo after the
-- user's enemies concept sheet; the old ellipse-rig version is in ../_backup_boar_v1/).
-- Frames are built from the hand-drawn key poses in wild_boar_poses.lua:
--   1 stand  2 run reach  3 run gather  4 run contact  5 head down  6 gore  7 charge  8 lying
-- attack = head-down wind-up then an upward tusk gore, special = pawing then a full charge,
-- hit = rears back, death = collapses onto its belly.
-- Run inside Aseprite:  _G.REVIEW = "<png>"; spr = dofile(".../enemy_gen/wild_boar.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local K, RAW = L.poses(HERE .. "/wild_boar_poses.lua")
local P = {}
for n, c in ipairs(RAW) do P[n] = c:copy():outline(K.o) end
local DUST = { L.MARK2, K.T, K.t }

local function pose(n, dx, dy) return P[n]:shifted(dx or 0, dy or 0) end
local function eyes(c, mode) return L.eyes(c, K.y, mode, K.o, K.f) end
-- everything above the legs sinks by d (breathing, crouching)
local function sink(c, d) return c:move(function(_, y) return y < 27 end, 0, d) end
-- head region (right of the shoulder) moves on its own
local function nod(c, dx, dy) return c:move(function(x, y) return x >= 21 and y >= 13 and y < 28 end, dx, dy) end
local function dust(c, x, y, r, seed) L.puff(c, x, y, r, DUST, seed) end
-- highest tusk pixel: where the gore effects start
local function tuskTip(c)
  local t = c:find(K.t)
  return t[1][1], t[1][2]
end

local function draw(tag, i, n)
  if tag == "idle" then
    -- breathe in, breathe out with a snort (head dips), back to rest
    return ({ pose(1), sink(pose(1), 1), nod(sink(pose(1), 1), 0, 1), nod(pose(1), 0, 1) })[i + 1]

  elseif tag == "run" then
    local c = L.canvas()
    if i == 0 then dust(c, 2, 29.5, 1.6, 3) end
    if i == 2 then dust(c, 3, 30, 1.3, 5) end
    return c:over(({ pose(2), pose(3), pose(4), pose(3, 0, 1) })[i + 1])

  elseif tag == "attack" then
    if i == 0 then return pose(5) end                          -- head down, tusks low
    if i == 1 then return pose(5, -1, 0) end                    -- coil back
    if i == 4 then return nod(pose(1), 0, -1) end              -- settle
    if i == 5 then return pose(1) end
    -- toss: the boar steps back 2 px so the white arc has room in front of the snout
    local g = pose(6, i == 2 and -2 or -1, 0)                   -- impact frame overshoots 1 px
    local x, y = tuskTip(g)
    local col = (i == 2) and L.FLASH or L.MARK2
    g:curve(x - 1, y + 8, x + 5, y + 5, x + 3, y - 3, col, i == 2 and 0.7 or 0.5)
    if i == 3 then L.sparkle(g, x + 3, y - 4, L.MARK2, 1, L.FLASH) end
    return g

  elseif tag == "special" then                                  -- the charge
    local c = L.canvas()
    if i == 0 then dust(c, 4, 30, 1.2, 11); return c:over(pose(5)) end            -- paw the ground
    if i == 1 then dust(c, 3.5, 29.5, 1.7, 12); return c:over(sink(pose(5), 1)) end  -- crouch, rump up
    if i >= 2 and i <= 5 then
      L.streaks(c, 9, 13 + (i % 2), 3, 9, L.MARK2, 20 + i)
      dust(c, 2.5 + (i % 2), 29, 2.3 - 0.1 * i, 30 + i)
      dust(c, 6 + (i % 2), 30, 1.4, 50 + i)
      return c:over(({ pose(7), pose(3, 1, 0), pose(7, 1, 0), pose(3, 1, 0) })[i - 1])
    end
    if i == 6 then dust(c, 27, 30, 1.6, 41); return c:over(pose(5)) end           -- skid to a stop
    return c:over(pose(1))

  elseif tag == "hit" then
    if i == 0 then return pose(6, -1, 0):flash() end
    if i == 3 then return pose(1) end
    local c = eyes(pose(6, i == 1 and -2 or -1, 0), "shut")
    local x, y = tuskTip(pose(6))
    if i == 1 then L.impact(c, x - 1, y - 2) else L.impact(c, x, y - 1) end
    return c

  elseif tag == "death" then
    if i == 0 then return eyes(pose(6, -2, 0), "shut") end
    if i == 1 then return eyes(sink(pose(1), 1), "x") end
    if i == 2 then return eyes(sink(pose(5), 2), "x") end
    local c = L.canvas()
    if i == 3 then dust(c, 2, 30, 1.8, 61); dust(c, 29, 30, 1.5, 62) end
    if i == 4 then dust(c, 1, 29.5, 1.3, 63) end
    local body = pose(8)
    if i == 4 or i == 6 then body = sink(body, 1) end          -- slow breaths while knocked out
    c:over(eyes(body, "x"))
    if i >= 4 and i <= 6 then L.dizzy(c, 22, 15 - (i - 4) // 2, i) end
    return c
  end
end

return L.build("wild_boar", HERE .. "/..", function(...) return draw(...):despeckle() end, REVIEW)
