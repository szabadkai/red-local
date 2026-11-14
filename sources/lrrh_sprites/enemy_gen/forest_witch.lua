-- Witch (forest sorceress): purple pointed hood, long cloak, gnarled staff.
-- Magic / area control: orb bolt (attack), rune circle of violet flames (special).
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local TAU, round, hash = L.TAU, L.round, L.hash

local P = L.pal {
  ol = "#1a1024",                                      -- outline / face void
  pu = { "#2a1e4a", "#45296e", "#683f9a", "#9466c2" }, -- cloak: cool shadow -> warm light
  sk = "#d6b4a4", skd = "#a07f86",                     -- skin sliver
  wd = { "#3a2618", "#6e4a2e" },                       -- staff wood
  mg = { "#6a2496", "#b14ee0", "#e59cff" },            -- magic: deep, mid, light (+ L.FLASH core)
}
local PU, MG, WD, WHITE = P.pu, P.mg, P.wd, L.FLASH

------------------------------------------------------------------ helpers
-- fill a polygon, calling shader(x, y, u, v, x0, x1, bottom) with per-row u (0 back .. 1 front)
local function fillShaded(c, pts, shader)
  local tmp = L.canvas()
  tmp:poly(pts, 1)
  local rows, miny, maxy = {}, 99, -1
  for k in pairs(tmp.p) do
    local x, y = k % 32, k // 32
    local r = rows[y]
    if not r then rows[y] = { x, x } else r[1] = math.min(r[1], x); r[2] = math.max(r[2], x) end
    miny, maxy = math.min(miny, y), math.max(maxy, y)
  end
  for k in pairs(tmp.p) do
    local x, y = k % 32, k // 32
    local r = rows[y]
    local u = r[2] > r[1] and (x - r[1]) / (r[2] - r[1]) or 0.5
    local v = maxy > miny and (y - miny) / (maxy - miny) or 0.5
    local col = shader(x, y, u, v, r[1], r[2], not tmp:get(x, y + 1))
    if col then c:set(x, y, col) end
  end
end

local function cloakShader(folds)
  return function(x, y, u, v, x0, x1, bottom)
    if bottom and v > 0.5 then return PU[1] end            -- dark lining along the hem
    local s = (u < 0.25 and 1) or (u < 0.62 and 2) or (u < 0.87 and 3) or 4
    if v > 0.3 then
      for _, f in ipairs(folds) do
        if x == round(x0 + f * (x1 - x0)) then s = math.max(1, s - 1) end
      end
    end
    return PU[s]
  end
end

-- gnarled staff from top (x0, y0) to foot (x1, y1); crook hooks forward
local function staff(c, x0, y0, x1, y1, flip)
  local dx, dy = x0 - x1, y0 - y1
  local len = math.sqrt(dx * dx + dy * dy)
  dx, dy = dx / len, dy / len
  local fx, fy = -dy, dx                       -- forward perpendicular
  if flip then fx, fy = -fx, -fy end
  c:line(x1, y1, x0, y0, WD[2])
  for _, t in ipairs({ 0.28, 0.6 }) do         -- knots on the back side
    c:set(x1 + (x0 - x1) * t - fx, y1 + (y0 - y1) * t - fy, WD[1])
  end
  local hook = { { 0, 0 }, { 1, 1 }, { 2, 1 }, { 3, 0 }, { 3, -1 } }   -- {forward, along}
  for k = 1, #hook - 1 do
    local a, b = hook[k], hook[k + 1]
    c:line(x0 + fx * a[1] + dx * a[2], y0 + fy * a[1] + dy * a[2],
           x0 + fx * b[1] + dx * b[2], y0 + fy * b[1] + dy * b[2], WD[2])
  end
  return x0 + fx * 1.5 + dx * 1.5, y0 + fy * 1.5 + dy * 1.5   -- crook centre (glow spot)
end

local function arm(c, x0, y0, x1, y1)
  c:seg(x0, y0, x1 - 1, y1, 1.2, PU[3])
  c:line(x0, y0 + 1, x1 - 1, y1 + 1, PU[2])
  c:rect(x1, y1, x1 + 1, y1 + 1, P.sk)
  c:set(x1, y1 + 1, P.skd)
end

local function layer(fn)
  local c = L.canvas()
  fn(c)
  return c:outline(P.ol)
end

------------------------------------------------------------------ the witch
-- o: x (hem centre), bob, lean, sink, flare (hem trailing back), hem (wave phase),
--    tip {dx, dy} hood-tip trail, feet {{x,y},..}, staff {x0,y0,x1,y1}, hand {x,y},
--    cast {x,y} far hand (nil = hidden), eye (false = no glow)
local function witch(o)
  local x, b, l, s = o.x or 14, o.bob or 0, o.lean or 0, o.sink or 0
  local sh = 18 + b + s
  local hx, hy = x + l, 13 + b + s
  local flare, ph = o.flare or 0, o.hem or 0
  local tip = o.tip or { 0, 0 }
  local out = L.canvas()

  if o.cast then
    out:over(layer(function(c) arm(c, hx + 1, sh + 1, o.cast[1], o.cast[2]) end))
  end

  out:over(layer(function(c)
    for _, f in ipairs(o.feet or { { 11, 31 }, { 16, 31 } }) do
      c:rect(f[1], f[2], f[1] + 2, f[2], PU[1])
    end
    local wv = function(k) return math.sin(ph + k * 1.9) end
    local hemY = 30.5
    local pts = {
      { hx - 2.5, sh - 1.5 },
      { hx - 6 - flare * 0.25, sh + 3 },
      { x - 8 - flare + wv(0) * 0.8, 29 + wv(0) * 0.6 },
      { x - 6 - flare * 0.6, hemY + math.max(0, wv(1)) * 0.4 },
      { x - 2, hemY - math.max(0, wv(2)) * 0.9 },
      { x + 2, hemY - math.max(0, wv(3)) * 0.9 },
      { x + 6 + flare * 0.1, hemY },
      { x + 5.5 + l * 0.3, 24 + b * 0.5 + s * 0.6 },
      { hx + 4, sh },
    }
    fillShaded(c, pts, cloakShader({ 0.42 + 0.06 * math.sin(ph), 0.7 + 0.05 * math.sin(ph + 1.5) }))
    -- hood tip, bent back
    local bx, by = hx - 2, hy - 3.5
    local cx, cy = hx - 4.5 + tip[1] * 0.5, hy - 8 + tip[2] * 0.4
    local tx, ty = hx - 8 + tip[1], hy - 4.5 + tip[2]
    c:curve(bx, by, cx, cy, tx, ty, PU[2], function(t) return 2.1 * (1 - t) + 0.45 * t end, 12)
    c:curve(bx + 0.6, by - 0.6, cx + 0.4, cy - 0.3, tx + 0.8, ty - 0.6, PU[3], function(t) return 1.1 * (1 - t) end, 12)
    -- hood
    local rx, ry = 5.5, 5
    c:ball(hx, hy, rx, ry, PU, 0.06)
    -- face opening on the right, in shadow
    local function inHood(px_, py_) return ((px_ - hx) / (rx + 0.25)) ^ 2 + ((py_ - hy) / (ry + 0.25)) ^ 2 <= 1 end
    local open = {}
    c:ell(hx + 3, hy + 1.5, 2.5, 2.7, function(px_, py_)
      if inHood(px_, py_) and px_ >= hx + 1 then open[py_ * 32 + px_] = true; return P.ol end
    end)
    for k in pairs(open) do                      -- lit rim above/behind the opening
      local px_, py_ = k % 32, k // 32
      for _, d in ipairs({ { -1, 0 }, { 0, -1 }, { -1, -1 } }) do
        local qx, qy = px_ + d[1], py_ + d[2]
        if not open[qy * 32 + qx] and c:get(qx, qy) and inHood(qx, qy) and qy <= hy + 1 then c:set(qx, qy, PU[4]) end
      end
    end
    c:set(hx + 5, hy + 1, P.sk); c:set(hx + 6, hy + 2, P.sk)   -- crooked nose
    c:set(hx + 4, hy + 3, P.skd); c:set(hx + 5, hy + 3, P.sk)  -- chin
    if o.eye ~= false then c:set(hx + 3, hy, MG[3]) end
  end))

  local glow
  if o.staff then
    local st = o.staff
    out:over(layer(function(c) glow = { staff(c, st[1], st[2], st[3], st[4]) } end))
  end
  if o.hand then
    out:over(layer(function(c) arm(c, hx + 2, sh + 1, o.hand[1], o.hand[2]) end))
  end
  return out, { hx = hx, hy = hy, sh = sh, glow = glow }
end

------------------------------------------------------------------ fx
local function orb(c, x, y, r, tail)
  if tail and tail > 0 then
    c:line(x - r - tail, y, x - r, y, MG[1])
    c:line(x - r - tail * 0.6, y - 1, x - r, y - 1, MG[2])
  end
  c:ell(x, y, r + 0.6, r + 0.6, MG[1])
  c:ell(x, y, r, r, MG[2])
  c:ell(x + 0.3, y - 0.3, r * 0.55, r * 0.55, MG[3])
  c:set(x, y, WHITE)
end

-- glowing rune ellipse on the ground: a 1-2 px band, brighter on the near (lower) half
local function ring(c, cx, cy, rx, ry, dim)
  c:ell(cx, cy, rx, ry, function(x, y, u, v)
    local d = math.sqrt(u * u + v * v)
    if d < 0.62 then return nil end
    if dim then return ((x + y) % 2 == 0) and MG[1] or nil end
    if v > 0.1 then return MG[3] end
    return MG[2]
  end)
  if rx >= 5 and not dim then                  -- rune marks inside the circle
    c:set(cx - 2, cy, MG[2]); c:set(cx + 2, cy, MG[2]); c:set(cx, cy - 1, MG[1])
  end
end

-- violet flame tongue rising from (x, base); ph drives the flicker
local function flame(c, x, base, h, ph)
  if h <= 0 then return end
  local wb = h >= 6 and 2.6 or 1.9
  for yy = 0, h do
    local t = yy / h
    local w = wb * (1 - t) ^ 0.85 + 0.2
    if t < 0.15 then w = w * (0.8 + t * 1.3) end   -- rounded foot
    local cx = x + math.sin(ph + t * 2.4) * t * 1.6
    for xx = math.floor(cx - w), math.ceil(cx + w) do
      local d = math.abs(xx - cx)
      if d <= w then
        local col = MG[1]
        if d <= w - 0.9 then col = MG[2] end
        if d <= w - 1.7 and t < 0.6 then col = MG[3] end
        c:set(xx, base - yy, col)
      end
    end
  end
  if h >= 6 then c:set(x, base - 1, WHITE); c:set(x, base - 2, WHITE) end
end

local function mote(c, x, y, size, col)
  if size >= 2 then c:rect(x, y, x + 1, y + 1, col) else c:set(x, y, col) end
end

------------------------------------------------------------------ frames
local IDLE_STAFF = function(hx, b) return { hx + 7, 8 + b, hx + 8, 31 } end

local function idle(i, extra)
  local bob = ({ 0, 0, 1, 1 })[i + 1]
  local lag = ({ 1, 0, 0, 1 })[i + 1]          -- tip/hem trail the body by a frame
  local hx = 14
  local o = {
    bob = bob, hem = TAU * (i - 1) / 4, tip = { 0, lag },
    staff = IDLE_STAFF(hx, bob), hand = { hx + 6, 21 + bob },
  }
  if extra then for k, v in pairs(extra) do o[k] = v end end
  return witch(o)
end

local function run(i)
  local bob = ({ 0, -1, 0, -1 })[i + 1]
  local lagb = ({ -1, 0, -1, 0 })[i + 1]
  local near = ({ { 19, 31 }, { 16, 30 }, { 12, 31 }, { 15, 31 } })[i + 1]
  local far = ({ { 11, 30 }, { 14, 31 }, { 18, 31 }, { 15, 30 } })[i + 1]
  local l, x = 2, 14
  local hx = x + l
  return witch {
    x = x, lean = l, bob = bob, flare = 3 + (i % 2), hem = TAU * i / 4 * 2,
    tip = { -2 - (i % 2), 2 + lagb }, feet = { far, near },
    staff = { hx + 8, 9 + bob, hx + 4, 31 }, hand = { hx + 6, 20 + bob },
  }
end

local function draw(tag, i, n)
  local c = L.canvas()
  if tag == "idle" then
    return (idle(i))

  elseif tag == "run" then
    return (run(i))

  elseif tag == "attack" then
    local x = 14
    if i == 0 then
      local w, g = witch { lean = -1, sink = 1, hem = 0.5, tip = { 1, 0 },
        staff = { 20, 9, 22, 31 }, hand = { 19, 21 } }
      c:over(w)
      L.sparkle(c, g.hx + 7, g.sh + 1, MG[2], 1, MG[3])
      c:set(g.hx + 9, g.sh - 2, MG[3])
    elseif i == 1 then
      local w, g = witch { lean = 1, hem = 1.4, tip = { 0, 1 }, flare = 1,
        staff = { 19, 9, 21, 31 }, hand = { 18, 21 }, cast = { 22, 19 } }
      c:over(w)
      orb(c, 26, 19, 1.4)
    elseif i == 2 then
      local w = witch { lean = 2, hem = 2.2, tip = { -1, 1 }, flare = 2,
        staff = { 20, 9, 21, 31 }, hand = { 19, 21 }, cast = { 23, 19 } }
      c:over(w)
      orb(c, 27, 19, 2.2, 1)
      L.sparkle(c, 25, 15, MG[3], 0)
    elseif i == 3 then
      local w = witch { lean = 2, hem = 3.0, tip = { -1, 0 }, flare = 1,
        staff = { 20, 9, 21, 31 }, hand = { 19, 21 }, cast = { 23, 19 } }
      c:over(w)
      orb(c, 29, 19, 2, 3)
    elseif i == 4 then
      local w = witch { lean = 1, hem = 3.8, tip = { 0, 0 },
        staff = { 20, 9, 21, 31 }, hand = { 19, 21 }, cast = { 21, 20 } }
      c:over(w)
      orb(c, 32, 19, 2, 4)
    else
      local w = idle(0, { hem = 4.6 })
      c:over(w)
      mote(c, 29, 16, 1, MG[2]); mote(c, 26, 14, 1, MG[1])
    end
    return c

  elseif tag == "special" then
    local raise = ({ 0.5, 1, 1, 1, 1, 1, 1, 0.5 })[i + 1]
    local hx = 15
    local st, hand
    if raise < 1 then
      st, hand = { hx + 8, 6, hx + 8, 29 }, { hx + 7, 18 }
    else
      st, hand = { hx + 9, 3, hx + 9, 26 }, { hx + 8, 14 }
    end
    local ringR = ({ 0, 3, 5, 6.5, 6.5, 6.5, 6.5, 0 })[i + 1]
    local fx = L.canvas()
    if ringR > 0 then ring(fx, 25, 29, ringR, math.max(1, ringR * 0.3), i == 6) end
    c:over(fx)
    local w, g = witch { lean = 1, hem = TAU * i / 8, tip = { -1 + (i % 2), (i + 1) % 2 }, flare = (i % 2),
      staff = st, hand = hand }
    c:over(w)
    local gx, gy = g.glow[1], g.glow[2]
    if i == 0 or i == 7 then
      L.sparkle(c, gx, gy, MG[2], 1, MG[3])
    elseif i >= 1 and i <= 6 then
      L.sparkle(c, gx, gy, MG[3], (i % 2 == 1) and 2 or 1, WHITE)
    end
    local hs = ({ nil, nil, nil, { 4, 5, 3 }, { 9, 13, 8 }, { 11, 10, 11 }, { 4, 5, 4 }, nil })[i + 1]
    if hs then
      local xs = { 21, 25, 29 }
      for k = 1, 3 do flame(c, xs[k], 30, hs[k], i * 1.9 + k * 2.3) end
    end
    if i == 2 then
      L.sparkle(c, 21, 26, MG[3], 0); L.sparkle(c, 29, 27, MG[3], 0)
    elseif i == 7 then
      mote(c, 23, 25, 2, MG[2]); mote(c, 27, 22, 1, MG[3]); mote(c, 20, 21, 1, MG[1])
    end
    return c

  elseif tag == "hit" then
    local lean = ({ -2, -2, -1, 0 })[i + 1]
    local w, g = witch { lean = lean, hem = 1 + i, tip = { 2 - i * 0.7, -1 + i * 0.5 }, flare = -1,
      bob = (i == 3) and 1 or 0, staff = { 19 + lean, 9, 22, 31 }, hand = { 18 + lean, 21 } }
    c:over(w)
    if i == 0 then c:flash() end
    if i == 1 or i == 2 then L.impact(c, g.hx + 6, g.hy - 4) end
    return c
  end

  -- death -----------------------------------------------------------------
  if i <= 2 then
    local sink = ({ 0, 3, 6 })[i + 1]
    local lean = ({ -2, -1, 0 })[i + 1]
    local tilt = ({ 0.1, 0.45, 0.85 })[i + 1]      -- staff falls forward
    local fx0, fy0 = 22, 31
    local len = 22
    local w = witch { lean = lean, sink = sink, flare = sink * 0.5, hem = i, tip = { 1 + i, i },
      staff = { fx0 + math.sin(tilt) * len, fy0 - math.cos(tilt) * len, fx0, fy0 },
      hand = (i == 0) and { 17, 21 } or nil }
    c:over(w)
    if i == 0 then L.impact(c, 19, 9) end
    return c
  end
  -- 3..7: collapsed heap that empties as the body dissolves into motes
  local t = ({ 0, 0.25, 0.5, 0.75, 1 })[i - 2]
  c:over(layer(function(s) staff(s, 28, 30, 12, 31, true) end))
  c:over(layer(function(s)
    local ry = 4.5 - t * 2.6
    fillShaded(s, {
      { 4 - t, 31.5 }, { 6, 31 - ry * 0.7 }, { 10, 31 - ry }, { 16, 31 - ry * 0.95 }, { 21, 31 - ry * 0.6 }, { 24 + t, 31.5 },
    }, cloakShader({ 0.35, 0.68 }))
    -- hood flopped at the front, its tip lying back over the heap
    local hx, hy = 21 + t, 27.5 + t * 1.8
    s:curve(hx - 2, hy - 2, 15, hy - 3 - (1 - t) * 1.5, 9 + t * 2, 31 - ry - 0.5 + t * 1.5, PU[2],
      function(q) return 1.6 * (1 - q) + 0.5 end, 10)
    s:ball(hx, hy, 3.8 - t * 0.6, 3.2 - t * 1.4, PU, 0.06)
    s:ell(hx + 2, hy + 1, 1.6, 1.6 - t * 0.6, P.ol)
    if t < 0.25 then s:set(hx + 2, hy + 0, MG[3]) end
  end))
  -- motes: square purple specks drifting up from the heap
  local f = i - 3
  for k = 1, 9 do
    local born = (k - 1) % 4                         -- frame (0..3) this mote leaves the heap
    local age = f - born
    local life = (k <= 2) and 6 or 3                 -- two linger into the last frame
    if age >= 0 and age < life then
      local x0 = 7 + hash(k * 3.1) * 15
      local y = 27 - age * (2 + hash(k) * 1.5) - hash(k + 9) * 2
      local x = x0 + math.sin(age * 1.3 + k) * 1.2
      local col = (age == 0 and MG[3]) or (age < 2 and MG[2]) or MG[1]
      mote(c, x, y, age < 2 and 2 or 1, col)
    end
  end
  return c
end

return L.build("forest_witch", HERE .. "/..", draw, REVIEW)
