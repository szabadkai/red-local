-- Grandmother: animation fix (2026-11-10). Her art is the user's hand-imported grandmother, unchanged;
-- only the composition is new. Source frames come from ../_backup_grandmother_v1/grandmother.aseprite.
--   idle    the two original breathing poses plus a slow dozing nod
--   special the lantern: the painted glow is taken out and redrawn as rings in the same three
--           colours, so it can grow from a flicker, pulse with drifting motes, and fade out
--           (it used to be 8 identical frames)
--   run, attack, hit, death are the original frames.
-- Run inside Aseprite:  _G.REVIEW = "<png>"; spr = dofile(".../enemy_gen/grandmother.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local pc = app.pixelColor

local src = app.open(HERE .. "/../_backup_grandmother_v1/grandmother.aseprite")
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

-- glow ramp as painted: rim, body, inner
local G_RIM, G_MID, G_IN = L.rgb("#907b7f"), L.rgb("#9d806c"), L.rgb("#ad9075")
local MOTE, MOTE2 = L.rgb("#f9d8a6"), L.rgb("#efc099")
local CX, CY = 17, 21                          -- lantern centre
local G_CORE, G_CORE2 = L.rgb("#ca9476"), L.rgb("#cdaa91")
local GLOW = { [G_RIM] = true, [G_MID] = true, [G_IN] = true }
local WARM = { [G_RIM] = true, [G_MID] = true, [G_IN] = true, [G_CORE] = true, [G_CORE2] = true }

-- the lantern pose without its glow: her body (left of x 11) plus the lantern box; glow colours
-- and stray motes everywhere else go
local BASE = F[15]:keep(function(x, y, v)
  if x <= 11 then return not (x >= 10 and GLOW[v]) end
  if x <= 20 and y >= 14 and y <= 27 then return not WARM[v] end
  return false
end)

local function glow(r, seed)
  local c = BASE:copy()
  if r <= 0 then return c end
  for y = 0, 31 do for x = 10, 31 do
    if not c:get(x, y) then
      local d = math.sqrt((x - CX) ^ 2 + (y - CY) ^ 2)
      if d <= r then
        local col = (d > r - 1.3) and G_RIM or ((d > r * 0.62) and G_MID or G_IN)
        if r >= 6 and d <= 4.2 then col = (d <= 3) and G_CORE2 or G_CORE end   -- warm core round the lantern
        c:set(x, y, col)
      end
    end
  end end
  -- a few light motes drifting inside the glow
  if r >= 7 then
    for i = 0, 2 do
      local a = (seed or 0) * 0.7 + i * 2.1
      local mx, my = L.round(CX + math.cos(a) * (r - 3)), L.round(CY + math.sin(a) * (r - 3) * 0.9)
      if c:get(mx, my) and GLOW[c:get(mx, my)] then
        c:set(mx, my, MOTE)
        if c:get(mx + 1, my) and GLOW[c:get(mx + 1, my)] then c:set(mx + 1, my, MOTE2) end
      end
    end
  end
  return c
end

local A, B = F[1], F[3]                        -- the two original idle poses
local function nod(c) return c:move(function(x, y) return y <= 19 end, 0, 1) end

local function draw(tag, i, n)
  if tag == "idle" then
    return ({ A:copy(), B:copy(), nod(B), B:copy() })[i + 1]
  elseif tag == "run" then
    return F[5 + i]:copy()
  elseif tag == "attack" then
    if i == 3 then                             -- originally a copy of the frame before: let the "!!" hop
      local body, fx = F[12]:split()
      return body:over(fx:shifted(1, -1))
    end
    return F[9 + i]:copy()
  elseif tag == "special" then
    -- lift the lantern, light it, full glow, pulse, fade, back to standing
    local R = { 0, 6, 9, 11, 12, 11, 8, nil }
    if i == 7 then return A:copy() end
    return glow(R[i + 1], i)
  elseif tag == "hit" then
    return F[23 + i]:copy()
  elseif tag == "death" then
    return F[27 + i]:copy()
  end
end

return L.build("grandmother", HERE .. "/..", draw, REVIEW)
