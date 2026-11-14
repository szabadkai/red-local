-- Wild boar enemy: "Charging brute - Tough / Charge / Knockback".
-- Run inside Aseprite:  REVIEW = "<png>"; spr = dofile(".../enemy_gen/wild_boar.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local TAU, round = L.TAU, L.round

local P = L.pal {
  out = "#1c1014",
  body = { "#40262a", "#643e32", "#8a5a3e", "#b27c52" },
  mane = "#2a1a1e",
  snout = { "#8a4c50", "#d6928a" },
  tusk = { "#c4b49a", "#f2e6d0" },
}
local DUST = { L.MARK2, P.tusk[1], P.tusk[2] }
local OX, OY = 13, 23          -- world position of the body centre when standing
local GROUND = 31
local MARK = 1                 -- any non-nil value marks a mask pixel

-------------------------------------------------- transforms (local -> world)
local function xf(x, y, rot)
  local c, s = math.cos(rot or 0), math.sin(rot or 0)
  return function(lx, ly) return x + lx * c - ly * s, y + lx * s + ly * c end
end
-- rotate a sub-part about local pivot (px, py) by a, then offset, then apply tf
local function pivot(tf, px, py, a, dx, dy)
  local c, s = math.cos(a or 0), math.sin(a or 0)
  dx, dy = dx or 0, dy or 0
  return function(lx, ly)
    local rx, ry = lx - px, ly - py
    return tf(px + rx * c - ry * s + dx, py + rx * s + ry * c + dy)
  end
end
local function mapPts(tf, pts)
  local o = {}
  for i, q in ipairs(pts) do
    local x, y = tf(q[1], q[2])
    o[i] = { x, y }
  end
  return o
end
local function ellPoly(tf, cx, cy, rx, ry)
  local o = {}
  for i = 0, 31 do
    local a = i / 32 * TAU
    o[#o + 1] = { cx + math.cos(a) * rx, cy + math.sin(a) * ry }
  end
  return mapPts(tf, o)
end

-------------------------------------------------- mask shading
local function bounds(m)
  local x0, y0, x1, y1 = 99, 99, -1, -1
  for k in pairs(m.p) do
    local x, y = k % 32, k // 32
    x0, x1 = math.min(x0, x), math.max(x1, x)
    y0, y1 = math.min(y0, y), math.max(y1, y)
  end
  return x0, y0, x1, y1
end
-- vertical gradient + rim light (upper right) + rim shadow (lower left), all from the mask shape
-- rim (optional) is the mask used for edge tests, so a part overlapping another gets no seam
local function shade(dst, m, ramp, bias, rim)
  rim = rim or m
  local x0, y0, x1, y1 = bounds(m)
  for k in pairs(m.p) do
    local x, y = k % 32, k // 32
    local v = (y - y0) / math.max(1, y1 - y0)
    local h = (x - x0) / math.max(1, x1 - x0)
    local i = 0.86 - 0.62 * v + 0.16 * (h - 0.5) + (bias or 0)
    if not rim:get(x, y - 1) or not rim:get(x + 1, y - 1) then i = i + 0.26
    elseif not rim:get(x + 1, y - 2) or not rim:get(x, y - 2) then i = i + 0.1 end
    if not m:get(x, y + 1) or not rim:get(x - 1, y + 1) then i = i - 0.3 end
    dst:set(x, y, L.pick(ramp, i))
  end
end

-------------------------------------------------- the boar
local LEGS = {
  { id = "BF", hip = { -3.5, 2.5 }, x = -3.5, far = true },
  { id = "FF", hip = { 6.5, 2.5 }, x = 6.5, far = true },
  { id = "BN", hip = { -6.5, 3.0 }, x = -6.5 },
  { id = "FN", hip = { 3.5, 3.0 }, x = 3.5 },
}
local HEAD = {
  { 3.0, -5.8 }, { 6.5, -5.6 }, { 9.8, -3.4 }, { 12.8, -0.4 }, { 14.4, 0.8 },
  { 14.4, 3.4 }, { 10.6, 4.6 }, { 6.4, 4.6 }, { 3.4, 3.2 }, { 2.2, -1.0 },
}

local function pose(t)
  local p = { x = OX, y = OY, rot = 0, b = 0, headA = 0, hdx = 0, hdy = 0, feet = {},
    ear = 0, tail = 0, lean = 1, lift = 0, eye = "open" }
  for k, v in pairs(t or {}) do p[k] = v end
  return p
end

local function drawLeg(c, tf, leg, p)
  local d = p.feet[leg.id] or { 0, 0 }
  local gl = p.groundLocal or (GROUND - p.y)
  local hx, hy = tf(leg.hip[1], leg.hip[2])
  local fx, fy = tf(leg.x + d[1], gl + d[2])
  local dark = leg.far and P.body[1] or P.body[2]
  local light = leg.far and P.body[2] or P.body[3]
  c:seg(hx, hy, fx, fy, 0.75, function(x, _, t)
    return (x < hx + (fx - hx) * t) and dark or light
  end)
  c:seg(fx, fy, fx, fy, 0.75, P.mane)  -- hoof
end

local function eye(c, x, y, kind)
  x, y = round(x), round(y)
  if kind == "x" then
    c:dots({ { x - 1, y - 1 }, { x + 1, y - 1 }, { x, y }, { x - 1, y + 1 }, { x + 1, y + 1 } }, P.out)
  elseif kind == "shut" then
    c:dots({ { x - 1, y }, { x, y } }, P.out)
  elseif kind == "angry" then
    c:dots({ { x, y }, { x - 1, y - 1 }, { x, y - 1 } }, P.out)
  else
    c:set(x, y, P.out)
  end
end

local function drawBoar(p)
  local c = L.canvas()
  local tf = xf(p.x, p.y, p.rot)
  local tfH = pivot(tf, 4, -1, p.headA, p.hdx, p.hdy)
  local b = p.b

  -- far legs, behind everything
  for _, leg in ipairs(LEGS) do if leg.far then drawLeg(c, tf, leg, p) end end

  -- body barrel + shoulder hump
  local body = L.canvas()
  body:poly(ellPoly(tf, -1.5, 0.6 - 0.4 * b, 6.8, 5.0 + 0.4 * b), MARK)
  body:poly(ellPoly(tf, 2.5, -1.6 - 0.9 * b, 5.2, 5.4), MARK)
  shade(c, body, P.body)

  -- tail: short curl that flicks
  local tipY = ({ -2.2, -3.4, -4.0, -3.0 })[(p.tail % 4) + 1]
  local tx0, ty0 = tf(-7.8, -1.8)
  local tx1, ty1 = tf(-9.2, -2.6)
  local tx2, ty2 = tf(-9.8, tipY)
  c:line(tx0, ty0, tx1, ty1, P.body[2])
  c:line(tx1, ty1, tx2, ty2, P.body[2])

  -- near legs
  for _, leg in ipairs(LEGS) do if not leg.far then drawLeg(c, tf, leg, p) end end

  -- head
  local head = L.canvas()
  head:poly(mapPts(tfH, HEAD), MARK)
  shade(c, head, P.body, 0.04, body:copy():over(head))
  c:poly(ellPoly(tfH, 14.0, 2.1, 1.1, 1.8), P.snout[2])
  local nx, ny = tfH(14.2, 2.6)
  c:set(nx, ny, P.snout[1])
  local mx0, my0 = tfH(9.4, 3.7)
  local mx1, my1 = tfH(11.4, 3.6)
  c:line(mx0, my0, mx1, my1, P.body[1])
  local ex, ey = tfH(7.6, -1.4)
  eye(c, ex, ey, p.eye)

  -- bristle band along the top of back + forehead
  local union = body:copy():over(head)
  local xa = round(select(1, tf(-6.5, -3)))
  local xb = round(select(1, tfH(9.0, -4)))
  local sx = round(select(1, tf(2.5, -7)))
  local tops = {}
  for x = math.min(xa, xb), math.max(xa, xb) do
    for y = 0, 31 do
      if union:get(x, y) then tops[x] = y; break end
    end
  end
  for x, y in pairs(tops) do
    c:set(x, y, P.mane)
    local d = math.abs(x - sx)
    if d <= 6 then c:set(x, y + 1, (d > 4 or (x + y) % 3 == 0) and P.body[1] or P.mane) end
    if d <= 2 then c:set(x, y + 2, P.body[1]) end
  end

  -- ear (flicks back)
  local ear = { { 3.4, -5.0 }, { 7.8, -4.4 }, { 4.8 - 1.8 * p.ear, -9.4 + 1.0 * p.ear } }
  c:poly(mapPts(tfH, ear), P.body[2])
  local ix, iy = tfH(5.0, -6.2)
  c:set(ix, iy, P.snout[1])

  -- tusk
  local t0x, t0y = tfH(10.0, 3.9)
  local t1x, t1y = tfH(12.6, 5.0)
  local t2x, t2y = tfH(12.2, 1.9)
  c:curve(t0x, t0y, t1x, t1y, t2x, t2y, P.tusk[2], nil, 8)
  c:set(t0x, t0y, P.tusk[1])

  c:outline(P.out)

  -- bristle spikes poke out of the outline, leaning back (trail the motion via lean/lift)
  local phase = round(p.x)
  for x, y in pairs(tops) do
    if (x - phase) % 2 == 0 and c:get(x, y - 1) == P.out then
      local dist = math.abs(x - sx)
      local h = (dist <= 2 and 2 or (dist <= 6 and 1 or 0))
      if h > 0 then h = math.max(0, h + p.lift) end
      for k = 1, h do
        local px_ = x - ((k == 2) and p.lean or (k == 3 and p.lean + 1 or 0))
        local py_ = y - 1 - k
        if not c:get(px_, py_) then c:set(px_, py_, P.out) end
      end
    end
  end
  return c
end

-------------------------------------------------- knocked-out boar, on its back with legs up
local function drawLying(k, twitch)
  local c = L.canvas()
  local LEGS_UP = {
    { 10.5, 25, 11.5, 20, true }, { 17.5, 25, 18.5, 20, true },
    { 7.5, 25.5, 6.5, 19, false }, { 14.5, 25.5, 15.5, 19, false },
  }
  local function legUp(l, dx)
    local dark = l[5] and P.body[1] or P.body[2]
    local light = l[5] and P.body[2] or P.body[3]
    local fx, fy = l[3] + (dx or 0), l[4]
    c:seg(l[1], l[2], fx, fy, 0.75, function(x, _, t)
      return (x < l[1] + (fx - l[1]) * t) and dark or light
    end)
    c:seg(fx, fy, fx, fy, 0.75, P.mane)
  end
  legUp(LEGS_UP[1]); legUp(LEGS_UP[2], twitch and 1 or 0)
  local body = L.canvas()
  body:ell(12.5, 27.5, 8, 3.8, MARK)
  shade(c, body, P.body, -0.05)
  legUp(LEGS_UP[3], twitch and -1 or 0); legUp(LEGS_UP[4])
  c:line(4, 27, 3, 26, P.body[2])                      -- limp tail
  local head = L.canvas()
  head:poly({ { 18, 25 }, { 22, 24.4 }, { 25.6, 25.8 }, { 27.4, 27.8 }, { 27.2, 30.8 }, { 22, 31 }, { 18, 30.6 } }, MARK)
  shade(c, head, P.body, 0.04)
  c:ell(27.2, 28.6, 0.8, 1.5, P.snout[2])
  c:set(27.5, 29, P.snout[1])
  c:poly({ { 19.5, 25 }, { 16.4, 24.2 }, { 18.6, 26.6 } }, P.body[2])   -- flopped ear
  c:curve(25.6, 30.4, 28, 31, 28.6, 28.2, P.tusk[2], nil, 8)
  c:set(25.6, 30.4, P.tusk[1])
  eye(c, 23, 27, "x")
  c:outline(P.out)
  return c
end

-------------------------------------------------- fx
local function swoosh(c, x0, y0, cx, cy, x1, y1, col, w)
  c:curve(x0, y0, cx, cy, x1, y1, col, function(t) return 0.2 + w * math.sin(t * math.pi) end, 10)
end
local function dust(c, x, y, r, seed) L.puff(c, x, y, r, DUST, seed) end

-------------------------------------------------- animations
local RUN = {
  { bob = 0,  FN = { 2, 0 },   FF = { 3, -1 },  BN = { -2, 0 },  BF = { -3, -1 } },
  { bob = -1, FN = { 0, 0 },   FF = { 1, -1 },  BN = { -1, -2 }, BF = { 0, -1 } },
  { bob = -1, FN = { -2, -1 }, FF = { -1, -2 }, BN = { 2, -1 },  BF = { 1, -2 } },
  { bob = 0,  FN = { 1, -1 },  FF = { 2, -2 },  BN = { 1, 0 },   BF = { 0, 0 } },
}
local function runFeet(i) local r = RUN[i + 1]; return { FN = r.FN, FF = r.FF, BN = r.BN, BF = r.BF } end

local function draw(tag, i, n)
  if tag == "idle" then
    local f = ({
      { b = 0, lean = 1, lift = 0, tail = 0, ear = 0 },
      { b = 1, lean = 2, lift = -1, tail = 1, ear = 0 },
      { b = 1, lean = 1, lift = 0, tail = 2, ear = 0 },
      { b = 0, lean = 0, lift = 0, tail = 1, ear = 1 },
    })[i + 1]
    return drawBoar(pose(f))

  elseif tag == "run" then
    local r = RUN[i + 1]
    local prev = RUN[((i - 1) % 4) + 1]
    local c = drawBoar(pose {
      y = OY + r.bob, feet = runFeet(i), tail = i, lean = 1,
      lift = r.bob - prev.bob, headA = ({ 0.05, -0.03, -0.06, 0.02 })[i + 1],
    })
    if i == 0 then dust(c, 3.5, 29.5, 1.9, 3) end
    if i == 1 then dust(c, 1.5, 28.8, 1.4, 5) end
    if i == 3 then dust(c, 8.5, 30.2, 1.3, 7) end
    return c

  elseif tag == "attack" then
    local A = {
      { x = OX - 1, headA = 0.32, eye = "angry", feet = { FN = { 1, 0 }, BN = { -1, 0 } }, lean = 2 },
      { x = OX + 1, headA = 0.38, eye = "angry", feet = { FN = { 2, 0 }, FF = { 2, -1 }, BN = { -2, 0 }, BF = { -3, 0 } }, lean = 2 },
      { x = OX + 2, headA = -0.38, hdy = -1, eye = "angry", feet = { FN = { 2, -1 }, FF = { 3, 0 }, BN = { -2, 0 }, BF = { -2, 0 } }, lean = 1, lift = 1 },
      { x = OX + 2, headA = -0.42, hdy = -1, eye = "angry", feet = { FN = { 2, 0 }, FF = { 3, 0 }, BN = { -2, 0 }, BF = { -2, 0 } }, lean = 0 },
      { x = OX + 1, headA = -0.12, feet = { FN = { 1, 0 }, BN = { -1, 0 } }, lean = 1 },
      { x = OX, headA = 0, lean = 1 },
    }
    local c = drawBoar(pose(A[i + 1]))
    if i == 2 then
      swoosh(c, 26, 29, 32, 27, 30, 17, L.FLASH, 1.0)
    elseif i == 3 then
      swoosh(c, 29, 24, 32, 21, 29, 15, P.tusk[1], 0.5)
    end
    if i == 1 then dust(c, 6, 30, 1.0, 11) end
    return c

  elseif tag == "special" then
    local S = {
      { headA = 0.25, eye = "angry", feet = { FN = { 1, -2 } }, lean = 1 },
      { headA = 0.3, eye = "angry", feet = { FN = { -2, 0 } }, lean = 1 },
      { x = OX - 1, y = OY + 1, headA = 0.36, eye = "angry", feet = { FN = { 1, 0 }, FF = { 1, 0 }, BN = { -1, 0 }, BF = { -1, 0 } }, lean = 2, lift = -1 },
      { x = OX + 1, eye = "angry", headA = 0.2, feet = runFeet(0), lean = 2 },
      { x = OX + 2, y = OY - 1, eye = "angry", headA = 0.2, feet = runFeet(2), lean = 2, lift = -1 },
      { x = OX + 3, eye = "angry", headA = 0.2, feet = runFeet(0), lean = 2 },
      { x = OX + 3, rot = -0.08, eye = "angry", headA = -0.05, feet = { FN = { 3, 0 }, FF = { 4, 0 }, BN = { -1, 0 }, BF = { 0, 0 } }, lean = 0, lift = 1 },
      { x = OX + 1, headA = 0, lean = 1 },
    }
    local c = L.canvas()
    -- trailing fx go behind the boar
    if i == 1 then dust(c, 12, 29.5, 1.8, 21) end
    if i == 2 then dust(c, 9.5, 29, 1.4, 22) end
    if i >= 3 and i <= 5 then
      local x0 = OX - 8 + (i - 3)
      L.streaks(c, x0, 18, 3, 5 + (i - 3) * 2, L.MARK2, i)
      if i >= 4 then dust(c, 1.5, 28, 1.8, 40 + i) end
    end
    if i == 6 then dust(c, 6, 29, 1.6, 50) end
    c:over(drawBoar(pose(S[i + 1])))
    -- dust kicked up by the back hooves, in front of the legs
    if i >= 3 and i <= 5 then dust(c, OX - 7 + (i - 3), 29.6, 2.0 + 0.25 * (i - 3), 30 + i) end
    if i == 6 then dust(c, 23.5, 29.8, 1.7, 51); dust(c, 27.5, 30.2, 1.2, 52) end
    if i == 7 then dust(c, 26, 30.2, 1.1, 53) end
    return c

  elseif tag == "hit" then
    local R = {
      { x = OX - 2, rot = -0.1, headA = -0.2, eye = "shut", feet = { FN = { 1, 0 }, BN = { -1, 0 } }, lean = 0, lift = 1 },
      { x = OX - 2, rot = -0.1, headA = -0.2, eye = "shut", feet = { FN = { 1, 0 }, BN = { -1, 0 } }, lean = 0, lift = 1 },
      { x = OX - 1, rot = -0.05, headA = -0.1, eye = "shut", feet = { FN = { 1, 0 } }, lean = 1 },
      { x = OX, headA = 0.04, lean = 1 },
    }
    local c = drawBoar(pose(R[i + 1]))
    if i == 0 then c:flash() end
    if i == 1 then L.impact(c, 23, 15) end
    if i == 2 then L.impact(c, 24, 16) end
    return c

  elseif tag == "death" then
    if i == 0 then
      return drawBoar(pose { x = OX - 1, headA = 0.28, eye = "shut", feet = { FN = { 1, 0 }, FF = { 1, 0 }, BN = { -1, 0 }, BF = { -1, 0 } }, lean = 2, lift = -1 })
    elseif i == 1 then
      return drawBoar(pose { x = OX - 1, y = OY + 1, rot = 0.06, headA = 0.38, eye = "shut", feet = { FN = { 2, 0 }, FF = { 2, 0 }, BN = { -2, 0 }, BF = { -2, 0 } }, lean = 2, lift = -1 })
    elseif i == 2 then
      local c = drawBoar(pose { x = OX - 1, y = OY + 2, rot = -0.5, groundLocal = 8, headA = -0.2, eye = "x", lean = 2, lift = -1 })
      return c
    end
    local c = L.canvas()
    local k = i - 3
    if k == 0 then dust(c, 3.5, 29, 2.2, 61); dust(c, 26, 29.5, 1.8, 62) end
    if k == 1 then dust(c, 2, 28.8, 1.5, 63); dust(c, 28, 29.5, 1.2, 64) end
    c:over(drawLying(k, k == 1))
    if i >= 4 and i <= 6 then L.dizzy(c, 22, 15 - (i - 4) // 2, i) end
    return c
  end
end

return L.build("wild_boar", HERE .. "/..", draw, REVIEW)
