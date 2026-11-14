-- Wild boar enemy: "Charging brute - Tough / Charge / Knockback" (concepts/enemies_concept_1.png, boar row).
-- Third take (2026-11-10): the poses are the concept's own frames, downscaled by concept_convert.py
-- into wild_boar_poses.lua and fixed by hand. Older versions: ../_backup_boar_v1/ (ellipse rig) and
-- ../_backup_boar_v2/ (hand-drawn dark plum boar the user rejected).
--   1 idle A  2 idle B  3 run reach  4 run gather  5 attack wind-up  6 gore  7 charge
--   8 hit (rears, head up)  9 hit recover  10 lying with X eye
-- attack = head-down wind-up then a tusk gore, special = pawing then a full charge,
-- hit = rears back, death = keels over onto its side.
-- Run inside Aseprite:  _G.REVIEW = "<png>"; spr = dofile(".../enemy_gen/wild_boar.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local K, P = L.poses(HERE .. "/wild_boar_poses.lua")
local DUST = { L.MARK2, K.d, K.S }

local function pose(n, dx, dy) return P[n]:shifted(dx or 0, dy or 0) end
local function eyes(c, mode) return L.eyes(c, K.e, mode, K.o, K["4"]) end
-- everything above the leg line sinks by d (breathing, crouching)
local function sink(c, legline, d) return c:move(function(_, y) return y < legline end, 0, d) end
-- head region moves on its own (snort, recoil)
local function nod(c, x0, dx, dy) return c:move(function(x, y) return x >= x0 and y >= 17 and y < 28 end, dx, dy) end
-- legs below the belly line, front (x >= split) or back, swing by dx
local function legs(c, belly, split, front, dx)
  return c:move(function(x, y) return y >= belly and ((x >= split) == front) end, dx, 0)
end
local function dust(c, x, y, r, seed) L.puff(c, x, y, r, DUST, seed) end

local function draw(tag, i, n)
  if tag == "idle" then
    -- the concept's two idle poses with a breath between them; blink on the last frame
    if i == 0 then return pose(1) end
    if i == 1 then return sink(pose(1), 27, 1) end
    if i == 2 then return pose(2) end
    return eyes(sink(pose(2), 27, 1), "shut")

  elseif tag == "run" then
    -- gather (feet down, dust kicked back) > push off > reach (airborne) > land
    local c = L.canvas()
    if i == 0 then dust(c, 3, 29.5, 1.5, 3) end
    if i == 3 then dust(c, 4, 30, 1.2, 5) end
    return c:over(({ pose(4), pose(4, 0, -1), pose(3, 0, -1), pose(3, 0, 1) })[i + 1])

  elseif tag == "attack" then
    if i == 0 then return pose(5) end                                    -- head down, eyes on target
    if i == 1 then return sink(pose(5, -1, 0), 28, 1) end                -- coil back
    if i == 5 then return pose(1) end
    if i == 4 then return pose(5) end                                    -- settle
    local g = pose(6, i == 2 and 1 or 0, 0)                              -- gore: lunge 1 px in
    local col = (i == 2) and L.FLASH or L.MARK2
    g:curve(26, 30, 31, 25, 28, 17, col, i == 2 and 0.7 or 0.5)          -- upward tusk toss arc
    if i == 3 then L.sparkle(g, 28, 15, L.MARK2, 1, L.FLASH) end
    return g

  elseif tag == "special" then                                           -- the charge
    local c = L.canvas()
    if i == 0 then dust(c, 6, 30, 1.2, 11); return c:over(pose(5)) end             -- paw the ground
    if i == 1 then dust(c, 4, 29.5, 1.7, 12); return c:over(sink(pose(5), 28, 1)) end -- crouch
    if i >= 2 and i <= 5 then
      local up = (i % 2 == 1) and -1 or 0
      local b = pose(7, 0, up)
      if up ~= 0 then b = legs(legs(b, 26, 15, true, -1), 26, 15, false, 1) end   -- legs tuck mid-stride
      dust(c, 2 + (i % 2), 29, 2.2 - 0.15 * (i - 2), 30 + i)
      c:over(b)
      L.streaks(c, 7 - (i % 2), 9 + (i % 2), 2, 6, L.MARK2, 20 + i)                -- speed lines over the rump
      return c
    end
    if i == 6 then dust(c, 28, 30, 1.6, 41); return c:over(pose(5, 1, 0)) end      -- skid to a stop
    return c:over(pose(1))

  elseif tag == "hit" then
    if i == 0 then return pose(8, -1, 0):flash() end
    if i == 3 then return pose(9) end
    local c = pose(8, i == 1 and -2 or -1, 0)
    if i == 1 then L.impact(c, 24, 8) else L.impact(c, 25, 9) end
    return c

  elseif tag == "death" then
    if i == 0 then return eyes(pose(8, -2, 0), "shut") end
    if i == 1 then return eyes(sink(pose(9), 28, 1), "x") end
    local c = L.canvas()
    if i == 2 then return c:over(pose(10, 0, -2)) end                    -- keels over
    if i == 3 then dust(c, 3, 30, 1.8, 61); dust(c, 29, 30, 1.5, 62) end
    if i == 4 then dust(c, 2, 29.5, 1.3, 63) end
    local body = pose(10)
    if i == 4 or i == 6 then body = sink(body, 29, 1) end                -- slow breaths while knocked out
    c:over(body)
    if i >= 4 and i <= 6 then L.dizzy(c, 14, 8 - (i - 4) // 2, i) end
    return c
  end
end

-- muted rim on the top edge of the near-black mane so the bristles don't sink into dark levels
-- (only where there is mane below, never on 1 px fx). The wolf/crow moonlight #9c98c2 was tried
-- and read as a lavender crest the concept doesn't have, so this uses a fur-coloured mauve.
local RIM = L.rgb("#7d6478")
local MANE = { [K["1"]] = true, [K["2"]] = true, [K["3"]] = true }
local function rim(c)
  local add = {}
  for k, v in pairs(c.p) do
    if MANE[v] then
      local x, y = k % 32, k // 32
      local up, down = c:get(x, y - 1), c:get(x, y + 1)
      if (not up or up == K.o) and down and down ~= K.o then add[#add + 1] = k end
    end
  end
  for _, k in ipairs(add) do c.p[k] = RIM end
  return c
end

return L.build("wild_boar", HERE .. "/..", function(...) return rim(draw(...):despeckle()) end, REVIEW)
