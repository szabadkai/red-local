-- Lost Wisp: small floating spirit. Ranged + explosive. 32x32, 34 frames, faces right.
-- Shading is "glow" style: every pixel's shade comes from its distance to the silhouette
-- edge (deep teal rim -> near-white core), nudged brighter toward the upper right.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local W, H, TAU = L.W, L.H, L.TAU
local round, clamp, lerp = L.round, L.clamp, L.lerp

local P = L.pal {
  eye = "#10232b",
  ramp = { "#1c5a66", "#2b8a92", "#4cc4c0", "#9af0dc", "#eafff6" },
}
local RAMP = P.ramp
local O, D, M, LI, WH = RAMP[1], RAMP[2], RAMP[3], RAMP[4], RAMP[5]
local EYE = P.eye

------------------------------------------------------------------ glow shading
-- mask: canvas whose opaque pixels form the shape. Returns a shaded canvas.
-- boost raises every level (charge-ups), lcx/lcy is where the light hits hardest.
local function shade(mask, lcx, lcy, boost)
  local depth, queue = {}, {}
  for k in pairs(mask.p) do
    local x, y = k % W, k // W
    if not (mask:get(x - 1, y) and mask:get(x + 1, y) and mask:get(x, y - 1) and mask:get(x, y + 1))
       or x == 0 or y == 0 or x == W - 1 or y == H - 1 then
      depth[k] = 1
      queue[#queue + 1] = k
    end
  end
  local head = 1
  while head <= #queue do
    local k = queue[head]; head = head + 1
    local x, y = k % W, k // W
    for _, n in ipairs({ { x - 1, y }, { x + 1, y }, { x, y - 1 }, { x, y + 1 } }) do
      local nk = n[2] * W + n[1]
      if n[1] >= 0 and n[2] >= 0 and n[1] < W and n[2] < H and mask.p[nk] and not depth[nk] then
        depth[nk] = depth[k] + 1
        queue[#queue + 1] = nk
      end
    end
  end
  local out = L.canvas()
  for k, d in pairs(depth) do
    local x, y = k % W, k // W
    local lvl
    local s = (x - lcx) * 0.6 - (y - lcy) * 0.8        -- >0 toward the upper right
    if d == 1 then
      -- selective rim: deep teal only on the shadow side, lit edges glow
      lvl = ((s > -1.5) and 2 or 1) + ((boost or 0) >= 2 and 1 or 0)
    else
      lvl = d + (boost or 0) + (s > 0.5 and 0.6 or (s < -2.5 and -0.6 or 0))
    end
    out.p[k] = RAMP[clamp(math.floor(lvl), 1, #RAMP)]
  end
  return out
end

------------------------------------------------------------------ the spirit
-- o = { cx, cy, rx, ry, tails = {{bx,by, kx,ky, tx,ty, width}, ...}, boost, eyes, dim }
local function wisp(c, o)
  local m = L.canvas()
  m:ell(o.cx, o.cy, o.rx, o.ry, 1)
  for _, t in ipairs(o.tails or {}) do
    m:curve(t[1], t[2], t[3], t[4], t[5], t[6], 1, function(s) return lerp(t[7], 0.5, s) end, 14)
  end
  local body = shade(m, o.cx + 1.5, o.cy - 1.5, (o.boost or 0) + 0.6)
  if o.dim then body:recolor(function(col)
    for j = 2, #RAMP do if col == RAMP[j] then return RAMP[j - o.dim > 0 and j - o.dim or 1] end end
    return col
  end) end
  c:over(body)
  local ex, ey = round(o.cx + (o.ex or 0)), round(o.cy + (o.ey or -1))
  local e = o.eyes or "open"
  if e == "open" then          -- two 1x2 eyes on the front half
    c:dots({ { ex, ey }, { ex, ey + 1 }, { ex + 3, ey }, { ex + 3, ey + 1 } }, EYE)
  elseif e == "blink" then
    c:dots({ { ex, ey + 1 }, { ex + 3, ey + 1 } }, EYE)
  elseif e == "narrow" then    -- determined: slanted 1px
    c:dots({ { ex, ey + 1 }, { ex + 3, ey }, { ex + 3, ey + 1 } }, EYE)
  elseif e == "squeeze" then   -- > <
    c:dots({ { ex, ey }, { ex + 1, ey + 1 }, { ex, ey + 2 } }, EYE)
    c:dots({ { ex + 4, ey }, { ex + 3, ey + 1 }, { ex + 4, ey + 2 } }, EYE)
  elseif e == "x" then
    c:dots({ { ex, ey }, { ex + 1, ey + 1 }, { ex, ey + 1 } }, EYE)
    c:dots({ { ex + 3, ey }, { ex + 3, ey + 1 } }, EYE)
  end
end

-- standard flame crown: tongues licking up-and-back from the top, a low one behind and a
-- ghostly wisp under the back. sx/sy flick the top tips, bx/by the back tips,
-- lick = nil or x offset of an extra small front lick
local function flame(cx, cy, rx, ry, sx, sy, bx, by, lick)
  local t = {
    { cx - 1.5, cy - ry + 2.5, cx - 2.5, cy - ry - 1, cx - 4 + sx, cy - ry - 4.5 + sy, 3.0 },
    { cx + 0.5, cy - ry + 2, cx + 0.5, cy - ry - 0.5, cx - 0.5 + sx * 0.5, cy - ry - 2.5 + sy, 2.0 },
    { cx - rx + 2.5, cy - 0.5, cx - rx, cy - 1, cx - rx - 2.5 + bx, cy - 2.5 + by, 2.0 },
    { cx - 2.5, cy + ry - 1.5, cx - 4, cy + ry - 0.5, cx - 5 + bx, cy + ry - 1 - by, 1.1 },
  }
  if lick then t[#t + 1] = { cx + 2.5, cy - ry + 2, cx + 3, cy - ry, cx + 2.5 + lick, cy - ry - 1.5, 1.0 } end
  return t
end

-- streaming flame for fast motion: tongues swept straight back
local function streamer(cx, cy, rx, w1, w2)
  return {
    { cx - 1, cy - 2.5, cx - 6, cy - 4 + w1, cx - 11, cy - 4 + w1 * 2, 2.6 },
    { cx - rx + 1, cy + 0.5, cx - rx - 3, cy + 1 + w2, cx - rx - 6, cy + w2 * 2, 1.7 },
  }
end

-- bright projectile: diamond orb + tapering tail to the left
local function bolt(c, x, y, len, r)
  local m = L.canvas()
  r = r or 2.3
  m:ell(x, y, r, r, 1)
  local b = shade(m, x + 1, y - 1, 1.2)
  b:set(x, y, WH)
  c:over(b)
  -- glowing streak behind it, bright near the orb and fading out
  local x0 = x - math.floor(r + 0.5)
  for j = 1, len do
    c:set(x0 - j, y, (j == 1) and LI or ((j <= len // 2 + 1) and M or D))
  end
end

-- 2-row ground shadow (L.shadow's ellipse grows a 1px nub at small sizes)
local SH = L.rgb("#24202a")
local function shadow(c, cx, rx)
  rx = round(rx)
  if rx < 1 then return end
  if rx >= 2 then c:rect(cx - rx + 1, 30, cx + rx - 1, 30, SH) end
  c:rect(cx - rx, 31, cx + rx, 31, SH)
end

------------------------------------------------------------------ frames
local CX, CY, RX, RY = 13, 20, 4.7, 4.5

local IDLE_BOB = { 0, -1, -2, -1 }
local function idle(i)
  local c = L.canvas()
  local bob = IDLE_BOB[i + 1]
  local lag = IDLE_BOB[(i - 1) % 4 + 1] - bob       -- tail tip trails the body
  local cy = CY + bob
  shadow(c, CX, 3.5 + bob * 0.5)
  local sx = ({ 0, -1, -1, 0 })[i + 1]
  local bx = ({ 0, 0, -1, -1 })[i + 1]
  wisp(c, { cx = CX, cy = cy, rx = RX, ry = RY,
    tails = flame(CX, cy, RX, RY, sx, lag, bx, lag, (i % 2 == 0) and 1 or nil),
    eyes = (i == 2) and "blink" or "open" })
  return c
end

local RUN_BOB = { 0, -1, -1, 0 }
local function run(i)
  local c = L.canvas()
  local cx, cy = 15, 20 + RUN_BOB[i + 1]
  shadow(c, cx - 1, 4)
  local w1 = ({ 0, -1, 0, 1 })[i + 1]
  local w2 = ({ 1, 0, -1, 0 })[i + 1]
  wisp(c, { cx = cx, cy = cy, rx = 4.8, ry = 3.8, tails = streamer(cx, cy, 4.8, w1, w2),
    eyes = "narrow", ex = 1, ey = -1 })
  -- trailing motes drift back 3px a frame and wrap with the loop
  for k = 0, 1 do
    local ph = (i + k * 2) % 4
    local mx, my = cx - 11 - ph * 3, cy + 3 - k * 6 + (ph % 2)
    if mx >= 0 then
      if ph < 2 then L.sparkle(c, mx, my, D, 1, LI) else c:set(mx, my, ph == 2 and M or D) end
    end
  end
  return c
end

local function attack(i)
  local c = L.canvas()
  local cx, cy, rx, ry, boost, eyes = CX, CY, RX, RY, 0, "open"
  local sx, sy = 0, 0
  if i == 0 then cx, rx, ry, boost, eyes, sx, sy = CX - 1, 5.2, 3.6, 0.8, "narrow", -1, 1      -- squash, gather
  elseif i == 1 then cx, rx, ry, boost, sx, sy = CX + 1, 4.0, 4.6, 1, 1, -1                    -- stretch, fire
  elseif i == 2 then cx, rx, ry, sx, sy = CX - 1, 4.8, 4.0, -1, 0                              -- kickback
  elseif i == 3 then cx, rx, ry, sx = CX, 4.6, 4.1, 0
  elseif i == 4 then sx = 1 end
  shadow(c, cx, 3.5)
  wisp(c, { cx = cx, cy = cy, rx = rx, ry = ry, boost = boost, eyes = eyes,
    tails = flame(cx, cy, rx, ry, sx, sy, sx, sy, (i == 1 or i == 4) and 1 or nil) })
  if i == 0 then
    L.sparkle(c, cx + 7, cy - 1, M, 0)
    L.sparkle(c, cx + 6, cy + 3, D, 0)
  elseif i == 1 then bolt(c, cx + 7, cy, 1, 1.9)
  elseif i == 2 then bolt(c, 21, cy, 3)
  elseif i == 3 then bolt(c, 26, cy, 4)
  elseif i == 4 then           -- bolt bursts at the far edge
    L.sparkle(c, 30, cy, M, 2, WH)
    c:set(28, cy - 2, LI); c:set(28, cy + 2, LI)
  elseif i == 5 then
    c:set(30, cy - 1, D); c:set(31, cy + 1, D)
  end
  return c
end

-- three orbs fly out on a fan to the right
local FAN = { -0.62, 0, 0.62 }
local function special(i)
  local c = L.canvas()
  if i <= 2 then
    -- charge up: swell, brighten, tremble, motes rushing in
    local r = ({ 5.0, 5.6, 6.2 })[i + 1]
    local jit = ({ 0, 1, -1 })[i + 1]
    shadow(c, CX, 4 + i * 0.5)
    wisp(c, { cx = CX + jit, cy = CY - 1, rx = r, ry = r - 0.4, boost = i + 1 - (i == 2 and 0 or 0.5),
      eyes = (i == 2) and "squeeze" or "narrow",
      tails = flame(CX + jit, CY - 1, r, r - 0.4, jit, -1 - i, -1, -1, 1) })
    local rr = 10 - i * 2
    for k = 0, 3 do
      local a = k / 4 * TAU + 0.6 + i * 0.4
      local x, y = CX + math.cos(a) * rr, CY - 1 + math.sin(a) * rr * 0.9
      if i < 2 then L.sparkle(c, x, y, M, 1, LI) else c:set(x, y, LI) end
    end
    if i == 2 then             -- burst ring
      for k = 0, 7 do
        local a = k / 8 * TAU
        c:set(CX + math.cos(a) * 9, CY - 1 + math.sin(a) * 8, WH)
      end
    end
    return c
  end
  -- release: body shrinks and slowly reforms, orbs travel out
  local reform = ({ 3.0, 3.4, 3.8, 4.2, 4.5 })[i - 2]
  local dist = ({ 8, 11.5, 15, 18, 0 })[i - 2]
  shadow(c, CX, reform * 0.8)
  wisp(c, { cx = CX, cy = CY, rx = reform, ry = reform - 0.3, boost = (i == 3) and 1 or 0,
    eyes = (i == 3) and "blink" or "open",
    ex = (reform < 3.6) and -1 or 0,
    tails = flame(CX, CY, reform, reform - 0.3, (i % 2 == 0) and -1 or 0, 1, 0, 1, (i >= 6) and 1 or nil) })
  if i <= 5 then
    for _, a in ipairs(FAN) do
      local x, y = CX + math.cos(a) * dist, CY + math.sin(a) * dist
      bolt(c, x, y, 0, 1.9)
      -- short trail back along the flight line
      c:set(x - math.cos(a) * 3, y - math.sin(a) * 3, D)
    end
  elseif i == 6 then           -- orbs pop at the edge
    for _, a in ipairs(FAN) do
      local x, y = CX + math.cos(a) * 17, CY + math.sin(a) * 17
      L.sparkle(c, x, y, M, 1, WH)
    end
  else
    c:set(29, 13, D); c:set(30, 21, D); c:set(28, 28, D)
  end
  return c
end

local function hit(i)
  local c = L.canvas()
  local back = ({ 2, 2, 1, 0 })[i + 1]
  local cx = CX - back
  local rx, ry = RX + (back > 0 and 0.5 or 0), RY - (back > 0 and 0.5 or 0)
  wisp(c, { cx = cx, cy = CY, rx = rx, ry = ry,
    eyes = (i == 3) and "blink" or "squeeze", ex = 0,
    tails = flame(cx, CY, rx, ry, 1 + back, back - 1, back, 0, (i == 3) and 1 or nil) })
  if i == 0 then c:flash() end
  local sc = L.canvas()          -- shadow goes under, and never flashes
  shadow(sc, cx, 3.5)
  c = sc:over(c)
  if i == 1 or i == 2 then L.impact(c, cx + 5, CY - 6) end
  return c
end

local function death(i)
  local c = L.canvas()
  if i <= 2 then
    -- sputter, then swell unstable
    local r = ({ 4.0, 5.0, 5.8 })[i + 1]
    shadow(c, CX, 3.5 - i * 0.5)
    wisp(c, { cx = CX, cy = CY - i, rx = r, ry = r - 0.5,
      dim = (i == 0) and 1 or nil, boost = (i == 2) and 1 or 0,
      eyes = (i == 0) and "x" or "squeeze", ex = 0,
      tails = flame(CX, CY - i, r, r - 0.5, -1 + i, 2 - i, -1, 1, (i == 1) and 1 or nil) })
    if i == 2 then
      L.sparkle(c, CX - 8, CY - 6, M, 0); L.sparkle(c, CX + 8, CY - 5, M, 0)
    end
    return c
  end
  -- break apart into sparkles that spread, rise and fade
  local cy0 = CY - 2
  if i == 3 then
    shadow(c, CX, 1.5)
    wisp(c, { cx = CX, cy = cy0, rx = 2.6, ry = 2.4, eyes = "none", dim = 1 })
  end
  local rad = ({ 7, 9.5, 11, 12, 12 })[i - 2]
  local rise = ({ 0, 1, 3, 5, 6 })[i - 2]
  for k = 0, 7 do
    local a = k / 8 * TAU + 0.35 + (k % 2) * 0.2
    local rr = rad * (0.8 + 0.25 * L.hash(k + 3))
    local x = CX + math.cos(a) * rr
    local y = cy0 + math.sin(a) * rr * 0.8 - rise * (0.6 + 0.4 * L.hash(k))
    if i == 3 then L.sparkle(c, x, y, M, 1, WH)
    elseif i == 4 then L.sparkle(c, x, y, (k % 2 == 0) and M or D, (k % 2 == 0) and 1 or 0, LI)
    elseif i == 5 then if k % 2 == 0 then L.sparkle(c, x, y, D, 0, M) else c:set(x, y, D) end
    elseif i == 6 then if k % 3 ~= 2 then c:set(x, y, (k % 2 == 0) and D or O) end
    end
  end
  if i == 7 then               -- a few faint motes settle near the ground
    c:set(CX - 4, 27, O); c:set(CX + 1, 29, D); c:set(CX + 5, 26, O)
  end
  return c
end

local function draw(tag, i, n)
  if tag == "idle" then return idle(i)
  elseif tag == "run" then return run(i)
  elseif tag == "attack" then return attack(i)
  elseif tag == "special" then return special(i)
  elseif tag == "hit" then return hit(i)
  else return death(i) end
end

return L.build("lost_wisp", HERE .. "/..", draw, REVIEW)
