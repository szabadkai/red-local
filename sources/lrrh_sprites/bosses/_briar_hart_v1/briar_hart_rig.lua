-- The Briar Hart: story boss of Lantern Wood. A great stag in the forest_stag palette,
-- wrapped in a thorny briar with red buds, a broken chain hanging from its neck.
-- attack = lowered-antler charge, special = rear up and stamp roots out of the ground.
-- Run inside Aseprite: dofile(".../boss_gen/briar_hart.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local B = dofile(HERE .. "/blib.lua")
local L = B.L

local FUR = B.ramp({ "#221d2b", "#423041", "#553b4b", "#694755", "#744c58", "#8a5f66" })
local BELLY = B.ramp({ "#553b4b", "#a98981", "#c9a493" })
local HORN = B.ramp({ "#a98981", "#debba4", "#efd1b9" })
local STEM, THORN = { L.rgb("#5f6e3a"), L.rgb("#2c3326") }, L.rgb("#15141e")
local BUD = { L.rgb("#b11d26"), L.rgb("#dc3a32") }
local CHAIN = B.ramp({ "#1f1d28", "#4d4b5a", "#8e8a9c" })
local HOOF = L.rgb("#221d2b")

-- p: x/y body offset, rot body tilt (neg = rear up), head (neg = chin up, pos = antlers down),
-- legs = {back1, back2, front1, front2} swing angles, bend = knee bend, open (mouth/strain)
local function hart(p)
  local c = L.canvas()
  local tf = L.xf(19 + (p.x or 0), 34 + (p.y or 0), p.rot or 0)
  local hipB = { tf(-8, 3) }
  local hipF = { tf(7, 3) }
  local legs = p.legs or { 0, 0, 0, 0 }
  local bend = p.bend or .35
  local function leg(h, a, bias, lift)
    local m = L.canvas()
    local fx, fy = B.limb(m, B.MASK, h[1], h[2], 5.2, a, 5.2 - (lift or 0), a - bend * (a >= 0 and 1 or -.6), 1.9, 1.2)
    L.shade(c, m, FUR, bias)
    c:set(fx, fy, HOOF); c:set(fx + 1, fy, HOOF)
  end
  -- far legs first, darker
  leg(hipB, legs[2], -.28, p.liftB); leg(hipF, legs[4], -.28, p.liftF)
  B.part(c, FUR, .05, function(m, k) local tx, ty = tf(-12, -3); m:ell(tx - 1, ty - 1, 1.8, 1.3, k) end)
  B.part(c, FUR, 0, function(m, k) m:poly(L.ellPoly(tf, 0, 0, 12, 6.5), k) end)
  -- neck + head on their own pivot
  local nx, ny = tf(7, -3)
  local htf = L.pivot(L.xf(nx, ny, (p.rot or 0) * .6), 0, 0, p.head or 0)
  B.part(c, FUR, .08, function(m, k)
    local x1, y1 = htf(4, -8)
    m:seg(nx, ny, x1, y1, 3.8, k)
  end)
  local hx, hy = htf(6, -11)
  B.part(c, FUR, .12, function(m, k)
    m:poly(L.ellPoly(htf, 6, -11, 4, 3), k)
    local sx, sy = htf(11, -9.5)
    m:seg(hx, hy, sx, sy, 2.1, k)
  end)
  local mx, my = htf(11.5, -9)
  c:set(mx, my, HORN[2]); c:set(mx - 1, my + 1, HORN[1])
  if p.open then c:set(mx - 1, my + 2, B.OUT) end
  B.part(c, FUR, .2, function(m, k) m:poly(L.mapPts(htf, { { 3, -13 }, { 0, -16 }, { 5, -14 } }), k) end)
  -- antlers: two branching beams (the boss's crown)
  local function beam(bx, by, sx, sy, tines, bias)
    local m = L.canvas()
    local ax, ay = htf(bx, by)
    local ex, ey = htf(bx + sx, by + sy)
    m:curve(ax, ay, (ax + ex) / 2 - 2, (ay + ey) / 2 - 1, ex, ey, B.MASK, 1.0)
    for _, t in ipairs(tines) do
      local qx, qy = htf(bx + sx * t[1], by + sy * t[1])
      local tx, ty = htf(bx + sx * t[1] + t[2], by + sy * t[1] + t[3])
      m:seg(qx, qy, tx, ty, .7, B.MASK)
    end
    L.shade(c, m, HORN, bias)
  end
  beam(4, -14, -8, -11, { { .35, -4, -1 }, { .6, 2, -4 }, { .9, -3, -3 } }, -.15)
  beam(7, -14, -1, -13, { { .3, 4, -2 }, { .55, -3, -3 }, { .85, 3, -4 } }, .1)
  -- near legs
  leg(hipB, legs[1], 0, p.liftB); leg(hipF, legs[3], .02, p.liftF)
  -- briar coiling over the back, around the flank and up into the antlers
  local function vine(a, b, cc, seed, tfn) local x0, y0 = (tfn or tf)(a[1], a[2]); local x1, y1 = (tfn or tf)(b[1], b[2]); local x2, y2 = (tfn or tf)(cc[1], cc[2]); B.vine(c, x0, y0, x1, y1, x2, y2, STEM, THORN, BUD, seed) end
  vine({ -12, -2 }, { -3, -9 }, { 8, -4 }, 3)
  vine({ -9, 5 }, { 1, 0 }, { 9, 5 }, 5)
  vine({ 5, -15 }, { 1, -20 }, { -2, -24 }, 1, htf)
  -- broken chain hanging from the collar, swinging with the head
  local cx0, cy0 = htf(3, -4)
  local sway = p.sway or 0
  B.chain(c, cx0, cy0, cx0 - 1 + sway, cy0 + 8, CHAIN)
  local ex, ey = htf(7.5, -12)
  c:set(ex, ey, p.blink and FUR[2] or B.EYE); c:set(ex + 1, ey, p.blink and FUR[2] or B.EYE)
  return c
end

local function dust(c, x, y, r, seed) L.puff(c, x, y, r, B.DUST, seed) end
-- briar spikes bursting from the ground (special strike)
local function roots(c, x, h, seed)
  for i = 0, 2 do
    local bx = x + i * 3 - 3
    local top = 47 - h + (i == 1 and 0 or 3)
    c:line(bx, 47, bx + (i - 1), top, STEM[2])
    c:set(bx + (i - 1), top - 1, THORN)
    c:set(bx - 1, top + 3, THORN); c:set(bx + 1, top + 5, BUD[1])
  end
end

local function draw(tag, i, n)
  if tag == "idle" then
    local bob = (i == 1 or i == 2) and 1 or 0
    local c = hart({ y = bob, head = bob * .05, sway = i % 2, blink = i == 3 })
    return B.finish(c)
  elseif tag == "run" then
    local G = { { .85, .45, -.7, -.35 }, { .3, .8, -.15, -.75 }, { -.7, -.35, .85, .45 }, { -.2, -.75, .3, .8 } }
    local c = L.canvas()
    if i == 0 or i == 2 then dust(c, 8, 46, 1.5, i + 1) end
    local h = hart({ y = (i % 2 == 1) and -1 or 0, legs = G[i + 1], head = .08, sway = (i % 2) * 2 - 1, bend = .5 })
    return B.finish(c:over(h))
  elseif tag == "attack" then
    -- 0-2 lower the antlers and dig in, 3-5 charge forward with a swoosh, settle
    if i <= 2 then
      local c = L.canvas()
      if i == 2 then dust(c, 7, 46, 1.6, 9) end
      return B.finish(c:over(hart({ x = -i, y = 1, head = .35 + i * .12, legs = { -.2, -.1, .25, .3 }, sway = -1, bend = .5 })))
    end
    if i == 5 then return B.finish(hart({ head = .2, sway = 1 })) end
    local c = hart({ x = i == 3 and -1 or -3, y = 0, head = .6, legs = { .5, .4, -.5, -.4 }, sway = -2, open = true, bend = .6 })
    B.finish(c)
    B.arc(c, 28, 28, 15, -1.2, .6, L.FLASH, L.MARK2)
    L.streaks(c, 6, 24, 3, 6, L.MARK2, 7 + i)
    return c
  elseif tag == "special" then
    -- rear up (0-3), slam the forehooves down and roots burst ahead (4-7)
    local c = L.canvas()
    if i <= 3 then
      local r = ({ -.15, -.35, -.5, -.55 })[i + 1]
      return B.finish(c:over(hart({ x = -2, y = -i, rot = r, head = -.25, legs = { .1, .2, -.9, -.6 }, liftF = 2, bend = .9, open = i >= 2 })))
    end
    local k = i - 4
    if k <= 1 then dust(c, 30, 46, 2.2 - k * .4, 20 + k); dust(c, 38, 46, 1.6, 22 + k) end
    c:over(hart({ x = 1, y = 1 - (k == 0 and 0 or 1), head = .3, legs = { .1, .2, .2, .35 }, sway = 2 }))
    B.finish(c)
    if k >= 1 and k <= 2 then roots(c, 43, 7 + k * 3, k) end
    if k == 3 then roots(c, 43, 6, 3) end
    return c
  elseif tag == "hit" then
    if i == 0 then return hart({ x = -1, head = -.2 }):flash() end
    local c = B.finish(hart({ x = i == 1 and -2 or -1, head = -.25, sway = 2, open = i == 1 }))
    if i < 3 then L.impact(c, 36, 8 + i) end
    return c
  elseif tag == "death" then
    -- buckle, fold the legs, sink to the ground; head drops, dizzy swirl
    if i <= 1 then return B.finish(hart({ x = -1, y = i * 2, head = .25 + i * .2, legs = { .4, .3, -.4, -.3 }, bend = .9 + i * .3, blink = i == 1 })) end
    local c = L.canvas()
    if i == 2 then dust(c, 8, 46, 2, 31); dust(c, 32, 46, 1.8, 32) end
    c:over(hart({ x = -5, y = 6, head = .75, legs = { 1.3, 1.2, -1.3, -1.2 }, bend = -1.2, blink = true }))
    B.finish(c)
    if i >= 4 and i <= 6 then L.dizzy(c, 24, 20 - (i - 4) // 2, i) end
    return c
  end
end

return B.build("briar_hart", draw)
