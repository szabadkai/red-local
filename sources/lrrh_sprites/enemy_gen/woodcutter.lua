-- Woodcutter: animation fix (2026-11-10). The art is the user's hand-imported woodcutter, unchanged;
-- only the frame order and composition are new. Source frames are read from
-- ../_backup_woodcutter_v1/woodcutter.aseprite (the original), so this script can be re-run.
--   idle    the two original breathing poses, plus a blink
--   attack  axe raised overhead (borrowed from the old special) > coil > chop: the swing trail
--           runs from behind his head down into the axe bitten into the ground > chips > recover
--   special a real spin: the raised-axe pose alternates with its mirror image, trail and dust
--           swapping sides, ending in a ground chop
--   run, hit, death are the original frames.
-- Run inside Aseprite:  _G.REVIEW = "<png>"; spr = dofile(".../enemy_gen/woodcutter.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local pc = app.pixelColor

local src = app.open(HERE .. "/../_backup_woodcutter_v1/woodcutter.aseprite")
local F = {}
for f = 1, #src.frames do
  local im = Image(32, 32, ColorMode.RGB); im:drawSprite(src, f)
  local c = L.canvas()
  for y = 0, 31 do for x = 0, 31 do
    local p = im:getPixel(x, y)
    if pc.rgbaA(p) > 0 then c:set(x, y, p) end
  end end
  F[f] = c
end
src:close()

local EYE, SKIN = L.rgb("#32181a"), L.rgb("#efc099")
local DUST = { L.MARK2, L.rgb("#b1969d"), L.rgb("#f7e7df") }
local function dust(c, x, y, r, seed) L.puff(c, x, y, r, DUST, seed) end

-- source frames (1-based): idle 1-4, run 5-8, attack 9-14, special 15-22, hit 23-26, death 27-34
local STAND_A, STAND_B = F[1], F[3]                 -- the two original idle poses
local RAISED, SPIN_ARC = F[15]:split()              -- arms up, axe behind the head | chop trail
local CROUCH, ATK_ARC = F[11]:split()               -- axe bitten into the ground | old trail
local STAND_AXE = F[14]                             -- original attack recovery frame

-- blink: the eye column on the face becomes skin, its lowest pixel a closed lid
local function blink(c)
  local o, low = c:copy(), {}
  for _, q in ipairs(c:find(EYE)) do
    if q[1] >= 12 and q[1] <= 17 and q[2] >= 8 and q[2] <= 14 then
      low[q[1]] = math.max(low[q[1]] or -1, q[2])
    end
  end
  for x, ylow in pairs(low) do
    for y = 8, ylow do if o:get(x, y) == EYE then o:set(x, y, (y == ylow) and EYE or SKIN) end end
  end
  return o
end
-- everything above the feet sinks by d (coil before the chop)
local function sink(c, d) return c:move(function(_, y) return y < 29 end, 0, d) end
-- mirror around the feet's centre, so the spin turns in place instead of jumping sideways
local function mirror(c)
  local xs, n = 0, 0
  for k in pairs(RAISED.p) do if k // 32 >= 28 then xs = xs + k % 32; n = n + 1 end end
  local cx = L.round(xs / n)
  return c:flipped():shifted(2 * cx - 31, 0)
end
local function dim(c) return c:copy():recolor(function() return L.MARK2 end) end

local function draw(tag, i, n)
  if tag == "idle" then
    return ({ STAND_A:copy(), STAND_B:copy(), STAND_A:copy(), blink(STAND_B) })[i + 1]

  elseif tag == "run" then
    return F[5 + i]:copy()

  elseif tag == "attack" then
    if i == 0 then return RAISED:copy() end                          -- lift the axe overhead
    if i == 1 then return sink(RAISED, 1) end                        -- coil
    if i == 2 then return CROUCH:copy():over(SPIN_ARC) end           -- chop: trail from behind the head into the blade
    if i == 3 then                                                   -- bite: fading trail, wood chips
      local c = CROUCH:copy():over(dim(ATK_ARC))
      dust(c, 29, 30, 1.4, 7)
      L.sparkle(c, 29, 23, L.MARK2, 1, L.FLASH)
      return c
    end
    if i == 4 then return CROUCH:copy() end
    return STAND_AXE:copy()

  elseif tag == "special" then                                       -- whirlwind spin
    if i == 0 then return sink(RAISED, 1) end                        -- wind up
    if i >= 1 and i <= 5 then
      local c = L.canvas()
      local turned = (i % 2 == 0)
      local spin = RAISED:copy():over(i == 5 and dim(SPIN_ARC) or SPIN_ARC)   -- last turn slows down
      if turned then spin = mirror(spin) end
      dust(c, turned and 21 or 6, 30, 1.5 - 0.1 * i, 40 + i)
      return c:over(spin)
    end
    if i == 6 then                                                   -- finish with a ground chop
      local c = CROUCH:copy():over(SPIN_ARC)
      dust(c, 29, 30, 1.6, 51); dust(c, 2, 30, 1.2, 52)
      return c
    end
    return STAND_AXE:copy()

  elseif tag == "hit" then
    return F[23 + i]:copy()

  elseif tag == "death" then
    return F[27 + i]:copy()
  end
end

return L.build("woodcutter", HERE .. "/..", draw, REVIEW)
