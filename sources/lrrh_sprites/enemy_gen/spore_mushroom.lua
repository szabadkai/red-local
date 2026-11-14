-- Spore mushroom enemy: "Spore - Explosive - Hazard" (concepts/enemies_concept_2.png, row 4).
-- Frames are built from the 9 hand-fixed concept poses in spore_mushroom_poses.lua:
--   1 idle  2 idle  3 squashed  4 popped up ("!")  5 standing tall  6 spore burst  7 spore cloud  8 reformed  9 idle
-- attack = spore puff (3 > 5 > 6), special = it pops up and explodes into a spore cloud (4 > 7 > 8),
-- death = the cap deflates onto the ground.
-- Run inside Aseprite:  _G.REVIEW = "<png>"; spr = dofile(".../enemy_gen/spore_mushroom.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local K, P = L.poses(HERE .. "/spore_mushroom_poses.lua")
P[7] = P[7]:keep(function(_, _, v) return v ~= K.o end)       -- the spore cloud has no outline
local SPORE = { K.p, K.q, K.w }

-- every pose is re-centred on its body so the mushroom does not slide between poses
local BODY, FX = {}, {}
for n, c in ipairs(P) do
  local b, f = c:split()
  local x0, _, x1 = L.bounds(b)
  local dx = L.round(15.5 - (x0 + x1) / 2)
  BODY[n], FX[n] = b:shifted(dx, 0), f:shifted(dx, 0)
end
local function pose(n, dx, dy) return BODY[n]:shifted(dx or 0, dy or 0) end
local function full(n, dx, dy) return BODY[n]:copy():over(FX[n]):shifted(dx or 0, dy or 0) end
local function eyes(c, mode) return L.eyes(c, K.y, mode, K.o, K["2"], K.y) end
local function sink(c, line, d) return c:move(function(_, y) return y < line end, 0, d) end
local function puff(c, x, y, r, seed) L.puff(c, x, y, r, SPORE, seed) end
local function dim(c) return c:recolor(function(v) return (v == K.w) and K.q or K.p end) end

-- deflated cap lying on the ground (death)
local function flat(k)
  local c = sink(pose(3), 31, 3 + k)
  c = c:keep(function(_, y) return y <= 31 end)
  return eyes(c, "x")
end

local function draw(tag, i, n)
  if tag == "idle" then
    return pose(({ 1, 2, 9, 2 })[i + 1])

  elseif tag == "run" then                                    -- waddling hops on stubby legs
    if i == 0 then return pose(4) end
    if i == 1 then return pose(5, 0, -1) end
    if i == 2 then return sink(pose(4), 26, 1) end
    return pose(5)

  elseif tag == "attack" then
    if i == 0 then return pose(3) end
    if i == 1 then return pose(5) end
    if i == 2 then return full(6) end
    if i == 3 then return pose(6):over(FX[6]:shifted(1, -1)) end
    if i == 4 then return pose(8):over(dim(FX[6]:shifted(2, -2))) end
    return pose(1)

  elseif tag == "special" then
    if i == 0 then return pose(3) end
    if i == 1 then return full(4) end
    if i == 2 then return pose(5) end
    if i == 3 then return full(6) end
    if i == 4 then return full(7) end
    if i == 5 then return dim(full(7, 0, -1)) end
    if i == 6 then return pose(8, 0, 1):over(dim(FX[7]:shifted(0, -2)):keep(function(_, _, v) return v == K.p end)) end
    return pose(8)

  elseif tag == "hit" then
    if i == 0 then return pose(3):flash() end
    if i == 3 then return pose(1) end
    local c = eyes(pose(3, i == 1 and -1 or 0), "shut")
    if i == 1 then L.impact(c, 24, 13) else L.impact(c, 25, 14) end
    return c

  elseif tag == "death" then
    if i == 0 then return eyes(full(4), "shut") end
    if i == 1 then return eyes(pose(3), "x") end
    if i == 2 then return flat(0) end
    local c = L.canvas()
    c:over(flat(1))
    if i == 3 then puff(c, 6, 27, 2.0, 71); puff(c, 25, 26, 1.8, 72) end
    if i == 4 then puff(c, 4, 24, 1.4, 73); puff(c, 27, 23, 1.2, 74) end
    if i >= 4 and i <= 6 then L.dizzy(c, 13, 16 - (i - 4) // 2, i) end
    return c
  end
end

return L.build("spore_mushroom", HERE .. "/..", function(...) return draw(...):despeckle() end, REVIEW)
