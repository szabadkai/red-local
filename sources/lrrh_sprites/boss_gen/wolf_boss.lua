-- The Wolf: final story boss, the roster's big_bad_wolf grown huge. A scruffy quadruped in its
-- palette (grey-mauve fur, lavender moonlight on the shaggy back, cream muzzle and chest,
-- yellow eyes): hunched shoulders, head low, teeth bared, bushy tail.
-- attack = gather and lunge into a bite, special = crouch, pounce, land in a claw swipe.
-- The first, upright version is kept in ../bosses/_wolf_v1/.
-- Run inside Aseprite: dofile(".../boss_gen/wolf_boss.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local B = dofile(HERE .. "/blib.lua")
local L = B.L

local FUR = B.ramp({ "#1f191e", "#3c3139", "#483d43", "#5a4b57", "#6f5e65", "#83737a" })
local CREAM = B.ramp({ "#8f7a72", "#b8998a", "#cdaa91", "#e2c8b4" })
local MOON = L.rgb("#9c98c2")
local CLAW = L.rgb("#e2c8b4")
local TOOTH = L.rgb("#f6ecee")
local MOUTH = L.rgb("#5e1a24")
local NOSE = L.rgb("#170d10")

-- p: x/y offset, rot body tilt (+ = nose down), head (+ = chin down), jaw (0..4 open),
-- legs = {hindN, hindF, foreN, foreF} swing (+ = forward), bend (knee bend), tail (+ = raised),
-- crouch (0..1 sinks the body), blink
local function wolf(p)
  local c = L.canvas()
  local crouch = p.crouch or 0
  local tf = L.xf(19 + (p.x or 0), 26 + (p.y or 0) + crouch * 5, p.rot or 0)
  local legs = p.legs or { 0, 0, 0, 0 }
  local bend = p.bend or .3
  local function hind(a, bias, dx)
    local m = L.canvas()
    local hx, hy = tf(-8 + dx, 2)
    m:ell(hx + 1, hy, 4.2, 5, B.MASK)                                     -- haunch
    local kx, ky = hx + math.sin(a + .35) * 7, hy + math.cos(a + .35) * (7 - crouch * 2.5)
    local ax, ay = kx + math.sin(a - .55 - bend) * 7, ky + math.cos(a - .55 - bend) * (7 - crouch * 2)
    ay = math.min(ay, 45)
    m:seg(hx, hy, kx, ky, 2.4, B.MASK)
    m:seg(kx, ky, ax, ay, 1.3, B.MASK)
    m:seg(ax, ay, ax + 3, ay + 1.5, 1.3, B.MASK)
    L.shade(c, m, FUR, bias)
    c:set(ax + 4, ay + 2, CLAW); c:set(ax + 3, ay + 2, CLAW)
  end
  local function fore(a, bias, dx)
    local m = L.canvas()
    local sx, sy = tf(7 + dx, 3)
    local ex, ey = sx + math.sin(a) * 8, sy + math.cos(a) * (8 - crouch * 2.5)
    local px_, py_ = ex + math.sin(a * .4 + bend * .3) * 8, ey + math.cos(a * .4 + bend * .3) * (8 - crouch * 2)
    py_ = math.min(py_, 45)
    m:seg(sx, sy, ex, ey, 2.4, B.MASK)
    m:seg(ex, ey, px_, py_, 1.4, B.MASK)
    m:seg(px_, py_, px_ + 3, py_ + 1.5, 1.4, B.MASK)
    L.shade(c, m, FUR, bias)
    c:set(px_ + 4, py_ + 2, CLAW); c:set(px_ + 3, py_ + 2, CLAW); c:set(px_ + 5, py_ + 2, CLAW)
  end
  -- bushy tail behind everything
  B.part(c, FUR, -.08, function(m, k)
    local bx, by = tf(-12, -2)
    local t = p.tail or 0
    m:curve(bx, by, bx - 6, by + 3 - t * 6, bx - 6, by + 12 - t * 13, k, function(s) return 3.0 - s * .8 end, 20)
    m:ell(bx - 6, by + 11 - t * 13, 2.4, 2.4, k)
    m:poly({ { bx - 8, by + 13 - t * 13 }, { bx - 6, by + 16 - t * 14 }, { bx - 4, by + 13 - t * 13 } }, k)
  end)
  hind(legs[2], -.3, 4); fore(legs[4], -.3, -3)
  -- body: deep chest and shoulders, tucked waist, rump
  B.part(c, FUR, 0, function(m, k)
    m:poly(L.mapPts(tf, { { -14, 0 }, { -12, -5 }, { -5, -6 }, { 3, -9 }, { 9, -9 }, { 12, -4 }, { 11, 4 }, { 7, 6 }, { 0, 4 }, { -7, 4 }, { -13, 3 } }), k)
    -- shaggy mane: ragged, uneven tufts swept back over the shoulders
    local TUFT = { { -3, -8, 2 }, { 0, -9, 4 }, { 3, -10, 3 }, { 6, -10, 5 }, { 9, -9, 3 } }
    for j, t in ipairs(TUFT) do
      m:poly(L.mapPts(tf, { { t[1] - 1, t[2] + 2 }, { t[1] - 3 - (j % 2), t[2] - t[3] }, { t[1] + 2, t[2] + 1 } }), k)
    end
    for j = 0, 2 do local bx = 11 - j * 2; m:poly(L.mapPts(tf, { { bx, 4 + j }, { bx - 2 - j, 8 + j }, { bx - 3, 4 + j } }), k) end
  end)
  B.part(c, CREAM, -.15, function(m, k)
    m:poly(L.mapPts(tf, { { 9, -2 }, { 12, -1 }, { 11, 4 }, { 8, 7 }, { 6, 4 } }), k)        -- chest ruff
  end)
  -- head, low and forward, on its own pivot
  local nx, ny = tf(11, -6)
  local htf = L.pivot(L.xf(nx, ny, (p.rot or 0) * .5), 0, 0, p.head or 0)
  local jaw = p.jaw or 0
  B.part(c, FUR, .08, function(m, k)
    m:poly(L.mapPts(htf, { { -3, -3 }, { 3, -7 }, { 9, -5 }, { 10, 3 }, { 3, 6 }, { -3, 4 } }), k)   -- neck + skull
    m:poly(L.mapPts(htf, { { 7, -3 }, { 15, -1 }, { 16, 1 }, { 14, 3 }, { 8, 4 } }), k)               -- long snout
    m:poly(L.mapPts(htf, { { 1, -5 }, { 0, -13 }, { 5, -6 } }), k)                                    -- far ear
    m:poly(L.mapPts(htf, { { 4, -6 }, { 6, -14 }, { 9, -5 } }), k)                                    -- near ear
  end)
  B.part(c, CREAM, .05, function(m, k)
    m:poly(L.mapPts(htf, { { 10, 1 }, { 15, 1 }, { 14, 3 }, { 9, 4 } }), k)                          -- muzzle
    m:poly(L.mapPts(htf, { { 8, 4 + jaw * .4 }, { 13, 4 + jaw }, { 12, 6 + jaw }, { 7, 6 } }), k)     -- lower jaw
  end)
  -- mouth line, teeth, nose, eye with a hard brow
  for j = 0, 5 do
    local x0, y0 = htf(9 + j, 3.6 + jaw * j / 6 * .8)
    c:set(x0, y0, jaw > 0 and MOUTH or FUR[1])
    if jaw > 0 and j % 2 == 0 then local tx, ty = htf(9 + j, 3 + .2); c:set(tx, ty, TOOTH); local bx, by = htf(9 + j, 4.4 + jaw * j / 6); c:set(bx, by, TOOTH) end
  end
  local fx, fy = htf(9, 3.2); c:set(fx, fy, TOOTH)                                       -- fang
  local nsx, nsy = htf(16, 0); c:set(nsx, nsy, NOSE); c:set(nsx - 1, nsy, NOSE)
  local ex, ey = htf(8, -2)
  c:set(ex, ey, p.blink and FUR[2] or B.EYE); c:set(ex + 1, ey, p.blink and FUR[2] or B.EYE)
  c:set(ex - 1, ey - 1, FUR[1]); c:set(ex, ey - 1, FUR[1]); c:set(ex + 1, ey - 1, FUR[1])
  local i1x, i1y = htf(6, -10); c:set(i1x, i1y, CREAM[1])                                  -- inner ear
  -- near legs in front
  hind(legs[1], .02, 0); fore(legs[3], .06, 0)
  -- moonlight on the shaggy back and head (the roster wolf's lavender streaks)
  local add = {}
  for k, v in pairs(c.p) do
    if v == FUR[4] or v == FUR[5] or v == FUR[6] then
      local x, y = k % 48, k // 48
      if not c:get(x, y - 1) then add[#add + 1] = k end
    end
  end
  for _, k in ipairs(add) do c.p[k] = MOON end
  return c
end

local function dust(c, x, y, r, seed) L.puff(c, x, y, r, B.DUST, seed) end

local function draw(tag, i, n)
  if tag == "idle" then
    -- breathing hunch, tail sway, a low growl (jaw ajar), blink on the last frame
    local b = (i == 1 or i == 2) and 1 or 0
    return B.finish(wolf({ y = b, head = b * .04, jaw = (i == 2) and 1 or 0, tail = .1 + (i % 2) * .15, blink = i == 3 }))
  elseif tag == "run" then
    -- loping gallop: gather, push, extend, land
    local G = { { .7, .5, -.6, -.4 }, { .2, .1, .4, .6 }, { -.6, -.5, .9, .7 }, { -.1, .2, .1, -.2 } }
    local c = L.canvas()
    if i == 0 or i == 2 then dust(c, 6, 46, 1.6, i + 7) end
    c:over(wolf({ y = (i == 2) and -2 or (i == 0 and 1 or 0), rot = ({ .05, -.04, -.06, .03 })[i + 1], legs = G[i + 1], bend = .5, tail = .35, jaw = 1, head = .05 }))
    return B.finish(c)
  elseif tag == "attack" then
    -- 0-2 gather back, head low, jaws opening; 3-4 lunge and snap; 5 recover
    if i <= 2 then
      local c = L.canvas()
      if i == 2 then dust(c, 8, 46, 1.6, 21) end
      return B.finish(c:over(wolf({ x = -i, crouch = .3 * i, rot = .06 * i, head = .12 * i, jaw = 1 + i, legs = { .3, .2, -.3, -.2 }, tail = .2 })))
    end
    if i == 5 then return B.finish(wolf({ jaw = 1, tail = .2 })) end
    local c = wolf({ x = i == 3 and 5 or 4, rot = -.08, head = -.15, jaw = i == 3 and 4 or 2, legs = { -.7, -.5, 1.0, .8 }, bend = .6, tail = .5 })
    B.finish(c)
    if i == 3 then B.arc(c, 39, 26, 8, -1.3, 1.2, L.FLASH, L.MARK2) end
    L.streaks(c, 6, 18, 3, 6, L.MARK2, 4 + i)
    return c
  elseif tag == "special" then
    -- crouch (0-1), spring (2), airborne (3-4), land in a swipe (5-6), rise (7)
    local c = L.canvas()
    if i <= 1 then if i == 1 then dust(c, 14, 46, 1.6, 41) end return B.finish(c:over(wolf({ crouch = .5 + i * .5, rot = .1, head = .15, jaw = 2, legs = { .4, .3, -.4, -.3 }, bend = .8, tail = .1 }))) end
    if i == 2 then dust(c, 12, 46, 2.2, 42); return B.finish(c:over(wolf({ y = -5, rot = -.25, head = -.2, jaw = 3, legs = { -.9, -.7, .9, .7 }, tail = .7 }))) end
    if i <= 4 then return B.finish(wolf({ y = -12 + (i - 3) * 5, rot = (i - 3) * .15 - .1, head = .1, jaw = 4, legs = { -1.1, -.9, 1.3, 1.1 }, bend = .2, tail = .9 })) end
    if i <= 6 then
      dust(c, 32, 46, 2.4 - (i - 5) * .6, 50 + i); dust(c, 10, 46, 1.6, 52 + i)
      c:over(wolf({ x = 2, crouch = 1 - (i - 5) * .5, rot = .12, head = .2, jaw = 2, legs = { .5, .3, .9, .6 }, bend = .7 }))
      B.finish(c)
      if i == 5 then B.arc(c, 38, 34, 10, -1.0, 1.3, L.FLASH, L.MARK2) end
      return c
    end
    return B.finish(wolf({ jaw = 1 }))
  elseif tag == "hit" then
    if i == 0 then return wolf({ x = -1, head = -.25, jaw = 2 }):flash() end
    local c = B.finish(wolf({ x = i == 1 and -3 or -2, rot = -.06, head = -.3, jaw = i == 1 and 3 or 2, tail = .5, legs = { .2, .1, .3, .2 } }))
    if i < 3 then L.impact(c, 38, 7 + i) end
    return c
  elseif tag == "death" then
    -- stagger, legs buckle, collapse onto the side; X eyes and a dizzy swirl
    if i <= 1 then return B.finish(wolf({ x = -2, rot = -.05, head = -.2 + i * .3, jaw = 2, crouch = i * .5, blink = i == 1 })) end
    local c = L.canvas()
    if i == 2 then return B.finish(c:over(wolf({ crouch = 1, rot = .15, head = .45, jaw = 1, legs = { .6, .5, -.6, -.5 }, bend = 1.2, blink = true }))) end
    if i == 3 then dust(c, 10, 46, 2.2, 61); dust(c, 34, 46, 1.8, 62) end
    c:over(wolf({ x = -1, y = 9, rot = .05, head = .5, jaw = 1, legs = { 1.3, 1.2, -1.4, -1.3 }, bend = 1.3, blink = true, tail = -.3 }))
    B.finish(c)
    if i >= 4 and i <= 6 then L.dizzy(c, 34, 24 - (i - 4) // 2, i) end
    return c
  end
end

return B.build("wolf_boss", draw)
