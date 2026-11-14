-- Living Tree: cursed guardian (slow, melee, area). 32x32, faces right, roots on y=31.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local round = L.round

local P = L.pal {
  out = "#1a1214",
  bark = { "#2e1f26", "#4a3226", "#6b4a30", "#8f6a40" },
  leaf = { "#25402e", "#4a7434", "#8fb04a" },
  eye = "#ffd34a",
  dust = "#b8a49a",
}
local FLASH, MARK2 = L.FLASH, L.MARK2
local DUST = { MARK2, P.dust }
local BX, YB = 13, 27

------------------------------------------------------------------ body parts
local function trunkCX(o, y)
  local t = L.clamp((YB - y) / (YB - o.top), 0, 1)
  return o.bx + o.lean * t
end
local function trunkHW(o, y)
  local t = L.clamp((y - o.top) / (YB - o.top), 0, 1)
  return 4.7 - 0.9 * math.sin(math.pi * t * 0.9) + 1.5 * t * t
end

local function drawTrunk(c, o)
  for y = o.top, YB + 1 do
    local cx, hw = trunkCX(o, y), trunkHW(o, y)
    local g1 = cx - 0.42 * hw + 0.6 * math.sin(y * 0.9)
    local g2 = cx + 0.3 * hw + 0.5 * math.sin(y * 0.7 + 2)
    for x = math.ceil(cx - hw - 0.3), math.floor(cx + hw + 0.3) do
      local u = L.clamp((x - cx) / hw, -1, 1)
      local k = L.clamp(math.floor(L.lit(u * 0.95, -0.1) * 4) + 1, 1, 4)
      if x == round(g1) or x == round(g2) then k = math.max(1, k - 1) end
      c:set(x, y, P.bark[k])
    end
  end
end

local function drawFace(c, o)
  local ey = o.top + 2
  local fx = trunkCX(o, ey) + 0.6
  local e1 = round(fx) - 2
  local e2 = e1 + 3
  c:rect(e1, ey, e1 + 1, ey + 1, P.out)
  c:rect(e2, ey, e2 + 1, ey + 1, P.out)
  -- angry brow ridge
  c:dots({ { e1 - 1, ey - 1 }, { e1, ey - 1 }, { e2 + 1, ey - 1 }, { e2 + 2, ey - 1 } }, P.bark[4])
  local eyes = o.eyes or 2
  if eyes >= 1 then c:set(e2 + 1, ey, P.eye) end
  if eyes >= 2 then c:set(e1 + 1, ey, P.eye) end
  -- knot-hole mouth
  local my = ey + 3
  if o.mouth == "open" then
    c:rect(e1 + 2, my, e1 + 3, my + 2, P.out)
  else
    c:rect(e1 + 2, my, e1 + 3, my + 1, P.out)
  end
end

local CLUMPS = {
  { -5.5, 1.6, 4.0, 3.0, -0.14 },
  { 5.6, 1.2, 3.8, 3.0, -0.02 },
  { 0, 0.3, 6.8, 4.0, 0.0 },
  { -2.6, -3.3, 4.2, 3.0, 0.04 },
  { 2.9, -3.6, 3.8, 2.8, 0.1 },
}
local function drawCanopy(o)
  local cv = L.canvas()
  local ccx, ccy = trunkCX(o, o.top) + (o.cdx or 0), o.top - 4 + (o.cdy or 0)
  for _, k in ipairs(CLUMPS) do cv:ball(ccx + k[1], ccy + k[2], k[3], k[4], P.leaf, k[5]) end
  -- a few lit leaf flecks on the mid-tone so the mass doesn't read as a smooth ball
  for _, q in ipairs({ { -5, 0 }, { -1, -4 }, { 2, -1 }, { 6, 2 }, { -3, 2 }, { 4, -5 } }) do
    local x, y = round(ccx + q[1]), round(ccy + q[2])
    if cv:get(x, y) == P.leaf[2] then cv:set(x, y, P.leaf[3]) end
  end
  -- twig poking out at the upper left
  cv:line(ccx - 6, ccy - 3, ccx - 8, ccy - 6, P.bark[2])
  cv:set(ccx - 9, ccy - 6, P.bark[2])
  return cv
end

-- canopy casts a dark band onto the trunk right under it
local function shadowUnder(main, cano)
  for k in pairs(cano.p) do
    local x, y = k % L.W, k // L.W
    if not cano:get(x, y + 1) then
      local b = main:get(x, y + 1)
      if b and b ~= P.out and b ~= P.eye then main:set(x, y + 1, P.bark[1]) end
    end
  end
end

local function taper(r0, r1) return function(t) return r0 + (r1 - r0) * t end end

-- branch arm: shoulder -> ctrl -> hand with three twig fingers
local function drawArm(cv, sx, sy, cx, cy, hx, hy, ramp)
  cv:curve(sx, sy, cx, cy, hx, hy, ramp[1], taper(1.45, 0.6), 12)
  cv:curve(sx + 0.3, sy - 0.6, cx + 0.3, cy - 0.6, hx + 0.2, hy - 0.4, ramp[2], taper(0.65, 0.25), 12)
  local dx, dy = hx - cx, hy - cy
  local len = math.max(0.01, math.sqrt(dx * dx + dy * dy))
  dx, dy = dx / len, dy / len
  for _, a in ipairs({ -0.75, 0, 0.75 }) do
    local ca, sa = math.cos(a), math.sin(a)
    local tx, ty = dx * ca - dy * sa, dx * sa + dy * ca
    cv:line(hx, hy, hx + tx * 2.6, hy + ty * 2.6, ramp[1])
  end
end

-- root leg: hip -> foot pad with root toes
local function drawLeg(cv, hx, hy, fx, lift, ramp)
  local fy = 29.5 - lift
  cv:curve(hx, hy, (hx + fx) / 2, fy - 1.5, fx, fy, ramp[1], taper(2.0, 1.2), 10)
  cv:curve(hx + 0.7, hy, (hx + fx) / 2 + 0.7, fy - 1.5, fx + 0.6, fy - 0.3, ramp[2], taper(0.7, 0.35), 10)
  cv:seg(fx - 2, fy, fx + 2, fy, 1.0, ramp[1])
  cv:line(fx + 2, fy + 0.5, fx + 4, fy + 0.5, ramp[1])
  cv:set(fx - 3, fy + 0.5, ramp[1])
end

local function rel(sx, sy, a)
  if a.abs then return a[1], a[2], a[3], a[4] end
  return sx + a[1], sy + a[2], sx + a[3], sy + a[4]
end

-- o: lean, top, cdx, cdy, armF, armB ({ctrl dx, dy, hand dx, dy} or abs), nearX/nearLift, farX/farLift, eyes, mouth, crack
local function tree(o)
  o.bx = o.bx or BX
  o.top = o.top or 14
  o.lean = o.lean or 0
  local back, main, front = L.canvas(), L.canvas(), L.canvas()
  local sy = o.top + 6
  local scx, shw = trunkCX(o, sy), trunkHW(o, sy) - 0.6
  drawLeg(back, o.bx - 2, 25, o.farX or (o.bx - 5), o.farLift or 0, { P.bark[1], P.bark[2] })
  local bsx = scx - shw
  local bcx, bcy, bhx, bhy = rel(bsx, sy, o.armB or { -4, -1, -5, 5 })
  drawArm(back, bsx, sy, bcx, bcy, bhx, bhy, { P.bark[1], P.bark[2] })
  back:outline(P.out)

  drawTrunk(main, o)
  drawLeg(main, o.bx + 2, 25, o.nearX or (o.bx + 5), o.nearLift or 0, { P.bark[2], P.bark[3] })
  drawFace(main, o)
  if o.crack then
    local cx = trunkCX(o, o.top + 8)
    main:line(cx - 1, o.top + 6, cx + 1, o.top + 8, P.out)
    main:line(cx + 1, o.top + 8, cx - 1, o.top + 11, P.out)
    main:line(cx - 1, o.top + 11, cx, o.top + 13, P.out)
  end
  local cano = drawCanopy(o)
  shadowUnder(main, cano)
  main:over(cano)
  main:outline(P.out)

  local fsx = scx + shw
  local fcx, fcy, fhx, fhy = rel(fsx, sy, o.armF or { 4, -1, 6, 5 })
  drawArm(front, fsx, sy, fcx, fcy, fhx, fhy, { P.bark[2], P.bark[3] })
  front:outline(P.out)

  local c = L.canvas()
  c:over(back); c:over(main); c:over(front)
  return c
end

------------------------------------------------------------------ fx
local function leafBit(c, x, y, k)
  if k % 2 == 0 then
    c:set(x, y, P.leaf[3]); c:set(x + 1, y, P.leaf[2])
  else
    c:set(x, y, P.leaf[2]); c:set(x + 1, y + 1, P.leaf[3]); c:set(x, y + 1, P.leaf[2])
  end
end

local function tendril(c, gx, h, dir, wig)
  if h <= 0 then return end
  local cv = L.canvas()
  if h <= 2 then
    cv:ell(gx, 31, 2, 0.8 + h * 0.4, P.bark[2])
    cv:set(gx, 30 - h, P.bark[3])
  else
    local tipx, tipy = gx + dir * (1.5 + h * 0.15) + (wig or 0), 31 - h
    cv:curve(gx, 31.5, gx - dir * 1.5, 31 - h * 0.8, tipx, tipy, P.bark[2], taper(1.5, 0.75), 14)
    cv:curve(gx + 0.7, 31.5, gx - dir * 1.5 + 0.7, 31 - h * 0.8, tipx + 0.5, tipy + 0.4, P.bark[3], taper(0.55, 0.3), 14)
    if h >= 6 then
      cv:curve(tipx, tipy, tipx + dir * 3, tipy - 1.2, tipx + dir * 3.2, tipy + 2.6, P.leaf[2], taper(0.9, 0.5), 8)
      cv:set(tipx + dir * 2, tipy - 1, P.leaf[3])
      local ly = round(31 - h * 0.45)
      cv:set(gx - dir * 2, ly, P.leaf[2]); cv:set(gx - dir * 3, ly - 1, P.leaf[3])
    end
    cv:ell(gx, 31, 2.0, 1.0, P.bark[1])
  end
  cv:outline(P.out)
  c:over(cv)
end

local function log(c, x0, y0, x1, y1, r)
  local cv = L.canvas()
  cv:seg(x0, y0, x1, y1, r, function(x, y)
    local dy = y - (y0 + (y1 - y0) * L.clamp((x - x0) / math.max(0.01, x1 - x0), 0, 1))
    return dy < -r * 0.3 and P.bark[3] or (dy > r * 0.45 and P.bark[1] or P.bark[2])
  end)
  -- cut end ring facing right
  cv:ell(x1, y1, 0.9, r * 0.85, P.bark[4])
  cv:set(x1, y1, P.bark[2])
  cv:outline(P.out)
  c:over(cv)
end

local function heap(c, settle)
  local back = L.canvas()
  back:ball(6, 27.5, 3.6, 2.4, P.leaf, -0.1)
  back:ball(23, 25.5 + settle, 3.4, 2.4, P.leaf, 0.0)
  back:outline(P.out)
  c:over(back)
  log(c, 3, 28.5, 16, 28.5, 2.0)
  log(c, 10, 25 + settle, 20, 26 + settle, 1.7)
  log(c, 17, 29, 26, 29, 1.5)
  local fr = L.canvas()
  fr:ball(9, 24.5 + settle, 2.6, 1.8, P.leaf, 0.08)
  fr:ball(27.5, 28.5, 2.4, 1.6, P.leaf, 0.0)
  fr:outline(P.out)
  c:over(fr)
  -- dead face on the big log: empty sockets
  c:dots({ { 11, 28 }, { 14, 28 } }, P.out)
end

------------------------------------------------------------------ poses
local IDLE_LEAN = { 0, 1, 0, -1 }
local IDLE_TOP = { 14, 14, 13, 13 }
local function prevOf(t, i, n) return t[((i - 1) % n) + 1] end

local function draw(tag, i, n)
  local c
  if tag == "idle" then
    local lean, top = IDLE_LEAN[i + 1], IDLE_TOP[i + 1]
    local pl, pt = prevOf(IDLE_LEAN, i, 4), prevOf(IDLE_TOP, i, 4)
    local creak = ({ 0, 0, 1, 1 })[i + 1]
    c = tree { lean = lean, top = top, cdx = pl - lean, cdy = pt - top,
      armF = { 4, -1, 6, 5 + creak }, armB = { -4, -1, -5, 5 + (1 - creak) } }

  elseif tag == "run" then
    local tops = { 14, 13, 14, 13 }
    local near = { { 19, 0 }, { 14, 0 }, { 8, 0 }, { 12, 2 } }
    local far = { { 7, 0 }, { 12, 2 }, { 19, 0 }, { 14, 0 } }
    local swing = { -3, 0, 3, 0 }
    local top, pt = tops[i + 1], prevOf(tops, i, 4)
    c = tree { lean = 2, top = top, cdx = -1, cdy = L.clamp(pt - top, -1, 1),
      nearX = near[i + 1][1], nearLift = near[i + 1][2], farX = far[i + 1][1], farLift = far[i + 1][2],
      armF = { 3, 0, 4 + swing[i + 1], 6 }, armB = { -3, 0, -4 - swing[i + 1], 6 } }

  elseif tag == "attack" then
    local P_ = {
      { lean = -1, cdx = 1, armF = { 2, -6, 3, -13 } },
      { lean = -2, cdx = 1, armF = { 3, -8, -1, -15 } },
      { lean = 1, cdx = -2, armF = { 6, -8, 11, -4 } },
      { lean = 3, cdx = -1, armF = { abs = true, 27, 13, 28, 28 }, mouth = "open" },
      { lean = 2, cdx = 1, armF = { abs = true, 26, 14, 27, 28 }, mouth = "open" },
      { lean = 1, cdx = 0, armF = { 5, -1, 8, 4 } },
    }
    local o = P_[i + 1]
    c = tree(o)
    if i == 2 then -- smear of the swing
      c:curve(17, 2, 26, 3, 27, 13, FLASH)
      c:curve(16, 4, 23, 5, 25, 13, MARK2)
    elseif i == 3 then
      L.puff(c, 25, 29, 2.2, DUST, 3)
      L.puff(c, 29, 28.5, 1.7, DUST, 5)
      c:line(23, 31, 30, 31, P.out)
    elseif i == 4 then
      L.puff(c, 23, 28, 2.6, DUST, 7)
      L.puff(c, 30, 28, 2.4, DUST, 9)
    end

  elseif tag == "special" then
    local hs = { { 1, 0, 0 }, { 4, 1, 0 }, { 8, 4, 1 }, { 11, 8, 5 }, { 13, 11, 8 }, { 13, 11, 8 }, { 7, 6, 4 }, { 2, 2, 1 } }
    local raise = ({ 0.5, 1, 1, 1, 1, 1, 0.8, 0.4 })[i + 1]
    local lean = (i >= 1 and i <= 5) and -1 or 0
    c = tree { lean = lean, top = 14 - (raise >= 1 and 1 or 0), cdx = (i == 1) and 1 or 0, mouth = (i >= 3 and i <= 5) and "open" or nil,
      armF = { 4, -2 - 4 * raise, 5, 5 - 13 * raise }, armB = { -4, -2 - 4 * raise, -5, 5 - 13 * raise } }
    local h = hs[i + 1]
    local wig = (i == 5) and 1 or 0
    tendril(c, 27.5, h[3], -1, -wig)
    tendril(c, 24, h[2], 1, -wig)
    tendril(c, 19.5, h[1], 1, wig)
    if i == 0 then c:dots({ { 20, 30 }, { 22, 29 }, { 21, 31 } }, P.bark[1]) end

  elseif tag == "hit" then
    local o
    if i <= 2 then
      o = { lean = -2, cdx = (i == 2) and -1 or 1, mouth = "open",
        armF = { 4, -4, 7, -3 }, armB = { -4, -4, -7, -2 } }
    else
      o = { lean = -1, cdx = 0, armF = { 4, -1, 6, 4 }, armB = { -4, -1, -5, 4 } }
    end
    c = tree(o)
    if i == 0 then
      c:flash()
    else
      L.impact(c, 23, 9)
      local ly = ({ 0, 13, 18, 24 })[i + 1]
      leafBit(c, 25, ly, i)
    end

  elseif tag == "death" then
    if i == 0 then
      c = tree { lean = -1, cdx = 1, eyes = 1, crack = true, mouth = "open",
        armF = { 4, -3, 7, -1 }, armB = { -4, -3, -7, 0 } }
      leafBit(c, 24, 12, 0)
    elseif i == 1 then
      c = tree { lean = -2, top = 17, cdx = 1, cdy = -1, eyes = 0, crack = true,
        armF = { 4, 2, 6, 9 }, armB = { -4, 2, -5, 9 } }
      leafBit(c, 25, 15, 1); leafBit(c, 3, 13, 0)
    elseif i == 2 then
      c = tree { lean = -3, top = 20, cdx = 1, cdy = 0, eyes = 0, crack = true,
        armF = { 4, 3, 7, 7 }, armB = { -4, 3, -6, 7 } }
      leafBit(c, 26, 19, 0); leafBit(c, 2, 17, 1); leafBit(c, 20, 8, 1)
    else
      c = L.canvas()
      heap(c, i == 3 and -1 or 0)
      if i == 3 then
        L.puff(c, 2, 28, 2.0, DUST, 11)
        L.puff(c, 29, 28, 2.0, DUST, 13)
        leafBit(c, 6, 15, 0); leafBit(c, 24, 12, 1); leafBit(c, 17, 9, 0)
      elseif i <= 6 then
        L.dizzy(c, 14, 14, i)
        local fall = (i - 4) * 4
        leafBit(c, 5, 18 + fall, i); leafBit(c, 25, 16 + fall, i + 1)
      end
    end
  end
  return c
end

return L.build("living_tree", HERE .. "/..", draw, REVIEW)
