-- The Bell Widow: story boss of the Ruined Chapel. A great spider whose head is a cream silk
-- hood (like the ghost hunter's) with yellow eyes; a gold bell hangs under her abdomen.
-- attack = rear the forelegs and spit silk, special = shake the bell (sound rings).
-- Run inside Aseprite: dofile(".../boss_gen/bell_widow.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local B = dofile(HERE .. "/blib.lua")
local L = B.L

local BODY = B.ramp({ "#15141e", "#2a2232", "#3d2f45", "#55405e", "#685169", "#7c6380" })
local HOOD = B.ramp({ "#7d6f7a", "#b8a9b0", "#d8c9c7", "#ece2dc" })
local GOLD = B.ramp({ "#6e4f26", "#bc9560", "#e6c48a" })
local SILK = L.rgb("#ece2dc")
local FACE = L.rgb("#15141e")

-- p: x/y offset, lift (forelegs raised 0..1), abd (abdomen tilt up 0..1), step (leg phase), bell (swing)
local function widow(p)
  local c = L.canvas()
  local ox, oy = 22 + (p.x or 0), 30 + (p.y or 0)
  local step = p.step or 0
  -- legs splay out from the cephalothorax: high knees, tips spread along the ground
  local KNEE = { { 12, -12 }, { 6, -14 }, { -3, -14 }, { -11, -11 } }
  local TIP = { 21, 12, -7, -19 }
  local function leg(j, far)
    local m = L.canvas()
    local rx, ry = ox + 2, oy
    local ph = (j + (far and 1 or 0) + step) % 2 == 0 and 1 or -1
    local shift = far and (TIP[j] > 0 and -4 or 4) or 0
    local tipx = ox + TIP[j] + shift + ph * (p.walk or 0)
    local tipy = 47 - ((p.walk or 0) > 0 and ph > 0 and 2 or 0)
    local kx, ky = ox + KNEE[j][1] + shift * .5, oy + KNEE[j][2] + (far and 2 or 0) + (ph > 0 and (p.walk or 0) > 0 and -1 or 0)
    if j == 1 and (p.lift or 0) > 0 and not far then
      tipx, tipy = ox + 18 - p.lift * 2, oy - 4 - p.lift * 12
      kx, ky = ox + 11, oy - 14 - p.lift * 3
    end
    m:seg(rx, ry, kx, ky, 1.25, B.MASK)
    m:seg(kx, ky, tipx, tipy, .8, B.MASK)
    L.shade(c, m, BODY, far and -.35 or .08)
    if not far then c:set(kx, ky - 1, HOOD[2]) end     -- knee glint
  end
  for j = 4, 1, -1 do leg(j, true) end
  -- bell on its silk under the abdomen
  local bx, by = ox - 9 + (p.bell or 0), oy + 9
  c:line(ox - 9, oy + 4, bx, by - 3, SILK)
  B.part(c, GOLD, 0, function(m, k)
    m:poly({ { bx - 2, by - 3 }, { bx + 2, by - 3 }, { bx + 3, by + 1 }, { bx + 4, by + 3 }, { bx - 4, by + 3 }, { bx - 3, by + 1 } }, k)
  end)
  c:set(bx, by + 4, GOLD[1])
  -- abdomen, tilting up for the bell shake
  local a = (p.abd or 0)
  B.part(c, BODY, .02, function(m, k)
    m:poly(L.ellPoly(L.xf(ox - 9, oy - 3 - a * 4, -a * .4), 0, 0, 10, 8), k)
  end)
  -- pale hourglass-like silk mark on the abdomen
  local mx, my = ox - 10, oy - 6 - a * 4
  c:set(mx, my, HOOD[2]); c:set(mx + 1, my, HOOD[2]); c:set(mx, my + 1, HOOD[1]); c:set(mx - 1, my - 1, HOOD[1])
  -- cephalothorax
  B.part(c, BODY, .1, function(m, k) m:ell(ox + 3, oy - 1, 6, 4.5, k) end)
  for j = 1, 4 do leg(j, false) end
  -- hooded head
  local hx, hy = ox + 8, oy - 8 + (p.bob or 0)
  B.part(c, HOOD, 0, function(m, k)
    m:poly({ { hx - 5, hy + 6 }, { hx - 4, hy - 2 }, { hx - 1, hy - 7 }, { hx + 2, hy - 8 }, { hx + 3, hy - 4 }, { hx + 6, hy + 2 }, { hx + 6, hy + 7 } }, k)
  end)
  c:ell(hx + 2, hy + 1, 2.6, 3.2, FACE)
  local open = p.spit
  c:set(hx + 2, hy, p.blink and FACE or B.EYE); c:set(hx + 4, hy, p.blink and FACE or B.EYE)
  if open then c:set(hx + 3, hy + 3, HOOD[1]) end
  return c
end

local function dust(c, x, y, r, seed) L.puff(c, x, y, r, B.DUST, seed) end
-- expanding sound rings from the bell
local function rings(c, x, y, k)
  for r = 1, 2 do
    local rad = 3 + k * 2 + r * 3
    for a = 0, 23 do
      local t = a / 24 * L.TAU
      if a % 3 ~= 0 then c:set(x + math.cos(t) * rad, y + math.sin(t) * rad * .6, r == 1 and L.FLASH or L.MARK2) end
    end
  end
end

local function draw(tag, i, n)
  if tag == "idle" then
    return B.finish(widow({ y = (i == 1 or i == 2) and 1 or 0, step = i % 2, bell = ({ 0, 1, 0, -1 })[i + 1], blink = i == 3 }))
  elseif tag == "run" then
    local c = L.canvas()
    if i % 2 == 0 then dust(c, 6, 46, 1.2, i + 1) end
    return B.finish(c:over(widow({ y = (i % 2), step = i, walk = 2, bell = (i % 2) * 2 - 1 })))
  elseif tag == "attack" then
    -- 0-2 rear the forelegs, 3-4 spit a silk spray forward, 5 settle
    if i <= 2 then return B.finish(widow({ x = -i, lift = .4 + i * .3, bob = -i, abd = .1 * i })) end
    if i == 5 then return B.finish(widow({ lift = .2 })) end
    local c = B.finish(widow({ x = 1, lift = .6, bob = 1, spit = true }))
    for s = 0, 4 do
      local y0 = 23 + s - 2
      for x = 34, 47, 2 do if (x + s * 3) % 5 ~= 0 then c:set(x, y0 + (x - 34) * (s - 2) * .15, s == 2 and L.FLASH or SILK) end end
    end
    return c
  elseif tag == "special" then
    -- abdomen lifts and the bell swings (0-3), rings spread (4-7)
    local swing = ({ 0, -2, 2, -3, 3, -2, 2, 0 })[i + 1]
    local c = B.finish(widow({ abd = math.min(1, i * .3), bell = swing, y = i >= 4 and 1 or 0, bob = i % 2 }))
    if i >= 3 then rings(c, 13 + swing, 39, i - 3) end
    return c
  elseif tag == "hit" then
    if i == 0 then return widow({ x = -1 }):flash() end
    local c = B.finish(widow({ x = i == 1 and -3 or -2, bob = 1, abd = .2, bell = 2 }))
    if i < 3 then L.impact(c, 32, 9 + i) end
    return c
  elseif tag == "death" then
    -- legs fold in, the body drops, the bell falls silent beside her
    local c = L.canvas()
    if i <= 1 then return B.finish(widow({ x = -1, y = i * 3, lift = 0, bob = 2, blink = i == 1 })) end
    if i == 2 then dust(c, 22, 46, 2.2, 71); dust(c, 8, 46, 1.6, 72) end
    c:over(widow({ x = 0, y = 9, bob = 3, blink = true, bell = -2 }))
    B.finish(c)
    if i >= 4 and i <= 6 then L.dizzy(c, 28, 22 - (i - 4) // 2, i) end
    return c
  end
end

return B.build("bell_widow", draw)
