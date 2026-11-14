-- The Wolf: final story boss. A hunched, upright big_bad_wolf in its palette: grey-mauve fur,
-- lavender moonlight along the back, cream muzzle and claws, yellow eyes.
-- attack = rear back and bite, special = crouch, leap and land with a claw swipe.
-- Run inside Aseprite: dofile(".../boss_gen/wolf_boss.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local B = dofile(HERE .. "/blib.lua")
local L = B.L

local FUR = B.ramp({ "#1f191e", "#3c3139", "#483d43", "#5a4b57", "#6f5e65", "#7d6c74" })
local CREAM = B.ramp({ "#8f7a72", "#cdaa91", "#e2c8b4" })
local MOON = L.rgb("#9c98c2")
local CLAW = L.rgb("#e2c8b4")
local MOUTH = L.rgb("#5e1a24")

-- p: x/y offset, lean (torso tilt, + = forward), head (+ = chin down), jaw (0..3 open),
-- armN/armF (near/far arm swing, + = forward), legN/legF (thigh swing), tail (+ = up), crouch (0..1)
local function wolf(p)
  local c = L.canvas()
  local ox, oy = 21 + (p.x or 0), 26 + (p.y or 0) + (p.crouch or 0) * 4
  local tf = L.xf(ox, oy, (p.lean or .25))
  local crouch = p.crouch or 0
  local function leg(a, bias)
    local m = L.canvas()
    local hx, hy = tf(-3, 7)
    local kx, ky = hx + math.sin(a + .5 + crouch * .4) * 6, hy + math.cos(a + .5 + crouch * .4) * 6
    local ax, ay = kx + math.sin(a - .9 - crouch * .5) * 6, ky + math.cos(a - .9 - crouch * .5) * 6
    local fy = math.min(47, ay + 2)
    m:seg(hx, hy, kx, ky, 2.6, B.MASK)
    m:seg(kx, ky, ax, ay, 1.6, B.MASK)
    m:seg(ax, ay, ax + 3, fy, 1.3, B.MASK)
    L.shade(c, m, FUR, bias)
    c:set(ax + 4, fy, CLAW); c:set(ax + 3, fy, CLAW)
  end
  local function arm(a, bias)
    local m = L.canvas()
    local sx, sy = tf(5, -5)
    local ex, ey = sx + math.sin(a) * 7, sy + math.cos(a) * 7
    local hx, hy = ex + math.sin(a + .5) * 6, ey + math.cos(a + .5) * 6
    m:seg(sx, sy, ex, ey, 2.2, B.MASK)
    m:seg(ex, ey, hx, hy, 1.7, B.MASK)
    L.shade(c, m, FUR, bias)
    for k = 0, 2 do c:set(hx + k, hy + 2, CLAW) end; c:set(hx + 1, hy + 3, CLAW)
  end
  -- tail behind everything
  B.part(c, FUR, -.05, function(m, k)
    local bx, by = tf(-8, 6)
    local t = p.tail or 0
    m:curve(bx, by, bx - 5, by + 1 - t * 3, bx - 8, by - 3 - t * 5, k, function(s) return 3.6 - s * 1.6 end)
    m:poly({ { bx - 10, by - 4 - t * 5 }, { bx - 6, by - 6 - t * 5 }, { bx - 7, by - 1 - t * 4 } }, k)
  end)
  arm(p.armF or 0, -.3)
  leg(p.legF or 0, -.28)
  -- torso: deep chest, narrow waist
  B.part(c, FUR, 0, function(m, k)
    m:poly(L.ellPoly(tf, 1, -1, 9.5, 9.5), k)
    m:poly(L.ellPoly(tf, -3, 7, 6, 4.5), k)
    -- shaggy ruff over the shoulders and back
    for j = 0, 5 do
      local a = -2.6 + j * .42
      local bx, by = 1 + math.cos(a) * 8.5, -1 + math.sin(a) * 8.5
      local tx, ty = 1 + math.cos(a - .25) * 12.5, -1 + math.sin(a - .25) * 12.5
      m:poly(L.mapPts(tf, { { bx - 1.6, by + 1 }, { tx, ty }, { bx + 1.8, by + .2 } }), k)
    end
  end)
  B.part(c, CREAM, -.2, function(m, k) m:poly(L.ellPoly(tf, 4.5, 1, 3.2, 6.5), k) end)
  -- head
  local nx, ny = tf(5, -9)
  local htf = L.pivot(L.xf(nx, ny, 0), 0, 0, p.head or 0)
  local jaw = p.jaw or 0
  B.part(c, FUR, .1, function(m, k)
    m:poly(L.ellPoly(htf, 3, -2, 6, 4.8), k)
    local ax, ay = htf(6, -1); local bx, by = htf(14, .5)
    m:seg(ax, ay, bx, by, 2.8, k)
    -- ears
    m:poly(L.mapPts(htf, { { -2, -4 }, { -3, -12 }, { 3, -6 } }), k)
    m:poly(L.mapPts(htf, { { 2, -6 }, { 5, -13 }, { 7, -5 } }), k)
  end)
  -- lower jaw drops when the mouth opens
  B.part(c, CREAM, 0, function(m, k)
    local ax, ay = htf(6, 2.5 + jaw * .4); local bx, by = htf(13, 2.5 + jaw)
    m:seg(ax, ay, bx, by, 1.4, k)
  end)
  if jaw >= 1 then
    for j = 1, jaw do local mx, my = htf(8 + j, 1.5 + j * .5); c:set(mx, my, MOUTH); local tx, ty = htf(8 + j * 1.5, 1.5); c:set(tx, ty, CLAW) end
  end
  local nx2, ny2 = htf(15.5, -.5); c:set(nx2, ny2, FUR[1]); c:set(nx2 - 1, ny2, FUR[1])                                   -- nose
  local ex, ey = htf(5.5, -3)
  c:set(ex, ey, p.blink and FUR[2] or B.EYE); c:set(ex + 1, ey, p.blink and FUR[2] or B.EYE)
  leg(p.legN or 0, 0)
  arm(p.armN or 0, .05)
  -- moonlight on the top edge of the fur (the big_bad_wolf's lavender streaks)
  local add = {}
  for k, v in pairs(c.p) do
    if v == FUR[5] or v == FUR[6] or v == FUR[4] then
      local x, y = k % 48, k // 48
      if not c:get(x, y - 1) and x >= ox - 9 and y < oy + 4 then add[#add + 1] = k end
    end
  end
  for _, k in ipairs(add) do c.p[k] = MOON end
  return c
end

local function dust(c, x, y, r, seed) L.puff(c, x, y, r, B.DUST, seed) end

local function draw(tag, i, n)
  if tag == "idle" then
    local b = (i == 1 or i == 2) and 1 or 0
    return B.finish(wolf({ y = b, armN = b * .08, armF = -b * .05, tail = (i % 2) * .3, blink = i == 3, jaw = 0 }))
  elseif tag == "run" then
    local S = { .6, .1, -.6, -.1 }
    local c = L.canvas()
    if i == 0 or i == 2 then dust(c, 14, 46, 1.4, i + 2) end
    c:over(wolf({ y = (i % 2 == 1) and -1 or 0, lean = .45, legN = S[i + 1], legF = -S[i + 1], armN = -S[i + 1] * .9, armF = S[i + 1] * .9, tail = .4 + (i % 2) * .2 }))
    return B.finish(c)
  elseif tag == "attack" then
    -- 0-2 rear back with the jaws opening, 3-4 lunge and snap, 5 settle
    if i <= 2 then
      return B.finish(wolf({ x = -i, lean = .1 - i * .08, head = -.15 - i * .1, jaw = i + 1, armN = -.4, armF = -.2, tail = .6 }))
    end
    if i == 5 then return B.finish(wolf({ jaw = 1 })) end
    local c = wolf({ x = i == 3 and 4 or 3, lean = .65, head = .15, jaw = i == 3 and 3 or 1, armN = 1.1, armF = .8, legN = -.3, legF = .4 })
    B.finish(c)
    B.arc(c, 34, 22, 9, -1.4, 1.1, L.FLASH, L.MARK2)
    L.streaks(c, 10, 14, 3, 5, L.MARK2, 3 + i)
    return c
  elseif tag == "special" then
    -- crouch (0-1), spring (2), airborne (3-4), land in a swipe (5-6), rise (7)
    local c = L.canvas()
    if i <= 1 then if i == 1 then dust(c, 18, 46, 1.6, 41) end return B.finish(c:over(wolf({ crouch = .5 + i * .5, lean = .5, armN = -.6, armF = -.5, jaw = 1, tail = .2 }))) end
    if i == 2 then dust(c, 16, 46, 2, 42); return B.finish(c:over(wolf({ y = -4, lean = .2, legN = -.5, legF = -.3, armN = -1.4, armF = -1.2, jaw = 2, tail = .8 }))) end
    if i <= 4 then return B.finish(wolf({ y = -9 + (i - 3) * 3, lean = .5, legN = .9, legF = .7, armN = 1.6, armF = 1.3, jaw = 3, tail = 1 })) end
    if i <= 6 then
      dust(c, 30, 46, 2.4 - (i - 5) * .6, 50 + i); dust(c, 10, 46, 1.6, 52 + i)
      c:over(wolf({ crouch = 1 - (i - 5) * .5, lean = .8, armN = 1.5 - (i - 5) * .8, armF = 1.1, jaw = 2 }))
      B.finish(c)
      if i == 5 then B.arc(c, 30, 32, 11, -1.0, 1.4, L.FLASH, L.MARK2) end
      return c
    end
    return B.finish(wolf({ jaw = 1 }))
  elseif tag == "hit" then
    if i == 0 then return wolf({ x = -1, lean = 0, head = -.2 }):flash() end
    local c = B.finish(wolf({ x = i == 1 and -3 or -2, lean = -.05, head = -.3, jaw = 2, armN = -.3, tail = .5 }))
    if i < 3 then L.impact(c, 32, 4 + i) end
    return c
  elseif tag == "death" then
    -- stagger back, drop to the knees, fall forward flat; X eyes and a dizzy swirl
    if i <= 1 then return B.finish(wolf({ x = -2, lean = -.1, head = -.3, jaw = 2, crouch = i * .6, blink = i == 1 })) end
    local c = L.canvas()
    if i == 2 then return B.finish(c:over(wolf({ crouch = 1, lean = .9, head = .4, armN = 1.2, armF = 1, blink = true }))) end
    if i == 3 then dust(c, 22, 46, 2.4, 61); dust(c, 36, 46, 1.8, 62) end
    c:over(wolf({ x = -2, y = 13, lean = 1.45, head = .2, armN = 1.6, armF = 1.5, legN = -1.2, legF = -1.1, blink = true, tail = -.4 }))
    B.finish(c)
    if i >= 4 and i <= 6 then L.dizzy(c, 30, 26 - (i - 4) // 2, i) end
    return c
  end
end

return B.build("wolf_boss", draw)
