-- Diorama vignette: Red at the forest gate, wind blowing. 104x104, 48-frame loop.
local pc = app.pixelColor
local W, H, N = 104, 104, 48
local TAU = math.pi * 2
local function rgb(hex, a)
  return pc.rgba(tonumber(hex:sub(2,3),16), tonumber(hex:sub(4,5),16), tonumber(hex:sub(6,7),16), a or 255)
end
local function round(v) return math.floor(v + 0.5) end
local function put(img, x, y, c)
  x, y = round(x), round(y)
  if x >= 0 and y >= 0 and x < W and y < H then img:drawPixel(x, y, c) end
end
local function opaque(img, x, y)
  return x >= 0 and y >= 0 and x < W and y < H and pc.rgbaA(img:getPixel(x, y)) > 0
end
local function hash(n) local s = math.sin(n * 127.1 + 311.7) * 43758.5453; return s - math.floor(s) end
local function gust(t, x) return 0.5 + 0.5 * math.sin(TAU * t / 24 + (x or 0) * 0.05) end  -- 2 gusts per loop

local C = {
  bg = rgb("#33373f"), shadow = rgb("#25282f"), shadowD = rgb("#1e2026"),
  -- pine foliage (front / gate trees), lit from upper right
  f = {rgb("#0f1a19"), rgb("#152823"), rgb("#1d3a30"), rgb("#2a5040"), rgb("#4a7a48"), rgb("#9cc850")},
  -- back trees, cooler and darker
  b = {rgb("#12181d"), rgb("#182227"), rgb("#1f2e31"), rgb("#2a3e3c"), rgb("#44604a")},
  bark = {rgb("#1c1820"), rgb("#2e2830"), rgb("#4a4048"), rgb("#6d6068")},
  void = rgb("#0f0d14"), voidE = rgb("#17141d"),
  path = {rgb("#2e2a30"), rgb("#3c353c"), rgb("#4d444a")},
  grass = {rgb("#1f3a2e"), rgb("#3a6a3e"), rgb("#7cb648")},
  leaf = {rgb("#c4513a"), rgb("#e09a3e"), rgb("#8e3a32"), rgb("#d8c060")},
  streak = rgb("#5c6474"), streakL = rgb("#7a8494"),
  eye = rgb("#ffd34a"), eyeD = rgb("#a2701e"),
  stone = {rgb("#2e333c"), rgb("#4a5260"), rgb("#7f8ea0")},
}

local GX, GY, GRX, GRY = 52, 80, 42, 13   -- ground ellipse

------------------------------------------------------------------ helpers
local function shadeIdx(u, pal, light)
  -- u in [-1, 1] across the shape, light comes from the right
  local n = #pal
  local v = (u + 1) / 2 + (light or 0)
  local i = 1 + math.floor(v * (n - 1) + 0.15)
  return pal[math.max(1, math.min(n - 1, i))]
end

-- chunky stylised pine: stacked tiers, each a rounded skirt
local function pine(img, cx, baseY, h, w, pal, sway, tiers, opts)
  opts = opts or {}
  local n = #pal
  local tierH = h / tiers
  -- trunk
  local tw = opts.trunk or 2
  for y = baseY - round(tierH * 0.6), baseY do
    for x = cx - tw, cx + tw do
      local u = (x - cx) / (tw + 0.5)
      local col = (u < -0.4) and C.bark[1] or (u < 0.3 and C.bark[2] or C.bark[3])
      put(img, x, y, col)
    end
  end
  for k = tiers, 1, -1 do   -- draw bottom tier first so upper tiers overlap
    local top = baseY - h + (k - 1) * tierH * 0.82
    local bot = top + tierH * 1.25
    local maxHW = (w / 2) * (0.35 + 0.65 * (k / tiers))
    for y = math.floor(top), math.floor(bot) do
      local v = (y - top) / (bot - top)       -- 0 at tier top, 1 at tier bottom
      local frac = (y - (baseY - h)) / h      -- 0 at tree top, 1 at base
      local hw = maxHW * math.min(1, (v * 1.15) ^ 0.75)
      if v > 0.8 then hw = hw * (1 - (v - 0.8) * 2.2) end
      -- whole-tree lean (top bends most) + each tier swaying on its own phase, like branches
      local t = opts.t or 0
      local flut = (opts.flut or 0) * math.sin(TAU * t / 8 + k * 1.15 + (opts.ph or 0)) * (1 - frac * 0.55)
      local dx = round((sway or 0) * (1 - frac) ^ 1.1 + flut)
      local L, R = round(cx - hw), round(cx + hw)
      -- needle tips trail downwind (to the left) and flick
      if v > 0.5 and v <= 0.86 then
        L = L - round(0.6 + (opts.flut or 0) * (0.6 + 0.6 * math.sin(TAU * t / 8 + k * 1.15 + 1.4 + (opts.ph or 0))))
      end
      if v > 0.86 then L, R = L + 2, R - 1 end
      for x = L, R do
        local u = (x - cx) / math.max(1, hw)
        local col
        if v > 0.86 then col = pal[1]                              -- dark underside of the tier
        elseif x == L then col = pal[1]
        else
          col = shadeIdx(u * 0.9 + 0.1, pal, (0.35 - v) * 0.45)
          -- lit rim on the upper right of each tier
          if u > 0.45 and v < 0.55 and (x == R or x == R - 1) then col = pal[n] end
          -- needle texture
          if (x * 3 + y * 5 + k) % 7 == 0 and col ~= pal[n] then col = pal[math.max(1, (function()
            for i = 1, n do if pal[i] == col then return i - 1 end end return 1 end)())] end
        end
        put(img, x + dx, y, col)
      end
    end
  end
  -- top tip highlight
  local tipdx = round((sway or 0) + (opts.flut or 0) * math.sin(TAU * (opts.t or 0) / 8 + (opts.ph or 0)))
  put(img, cx + tipdx, baseY - h - 1, pal[n - 1])
end

local function ellipse(img, cx, cy, rx, ry, col, cond)
  for y = math.floor(cy - ry), math.ceil(cy + ry) do for x = math.floor(cx - rx), math.ceil(cx + rx) do
    local d = ((x - cx) / rx) ^ 2 + ((y - cy) / ry) ^ 2
    if d <= 1 and (not cond or cond(x, y, d)) then put(img, x, y, col) end
  end end
end

------------------------------------------------------------------ LAYERS
local function drawBG(img, t) img:clear(C.bg) end

local function drawGround(img, t)
  ellipse(img, GX, GY, GRX, GRY, C.shadow)
  ellipse(img, GX + 2, GY + 1, GRX - 6, GRY - 3, C.shadowD)
  -- mossy ground patch
  ellipse(img, GX + 4, GY - 1, GRX - 12, GRY - 5, rgb("#1d2a27"))
  -- dirt path from the front-left to the gate
  for y = 70, 91 do
    local u = (y - 70) / 21
    local cx = 54 - u * 20
    local hw = 2.5 + u * 5.5
    for x = math.floor(cx - hw), math.ceil(cx + hw) do
      local e = math.abs(x - cx) / hw
      local col = (e > 0.8) and C.path[1] or ((x + y) % 5 == 0 and C.path[3] or C.path[2])
      if ((x - GX) / GRX) ^ 2 + ((y - GY) / GRY) ^ 2 < 0.92 then put(img, x, y, col) end
    end
  end
  -- a few stones
  for _, s in ipairs({{71, 86}, {75, 85}, {24, 77}, {80, 77}}) do
    put(img, s[1], s[2], C.stone[2]); put(img, s[1] + 1, s[2], C.stone[3]); put(img, s[1], s[2] + 1, C.stone[1]); put(img, s[1] + 1, s[2] + 1, C.stone[1])
  end
  -- fallen leaves on the ground
  for i = 1, 14 do
    local a = hash(i * 7) * TAU
    local r = 0.3 + hash(i * 11) * 0.6
    put(img, GX + math.cos(a) * GRX * r, GY + 1 + math.sin(a) * GRY * r * 0.8, C.leaf[1 + i % 4])
  end
end

local function drawBack(img, t)
  -- the dark mouth of the forest
  for y = 46, 74 do
    local u = (y - 46) / 28
    local hw = 4 + 9 * math.sqrt(u)
    for x = math.floor(55 - hw), math.ceil(55 + hw) do
      put(img, x, y, (math.abs(x - 55) > hw - 1.2 or y < 48) and C.voidE or C.void)
    end
  end
  local g = gust(t, 50)
  pine(img, 56, 50, 34, 26, C.b, -(0.6 + 1.6 * g), 4, {t = t, flut = 0.8, ph = 0.4})
  pine(img, 84, 66, 40, 22, C.b, -(0.6 + 1.8 * gust(t, 84)), 4, {t = t, flut = 0.8, ph = 2.1})
  pine(img, 22, 66, 34, 20, C.b, -(0.6 + 1.6 * gust(t, 22)), 4, {t = t, flut = 0.8, ph = 3.3})
  -- re-cut the void in front of the back tree's trunk
  for y = 58, 74 do
    local u = (y - 58) / 16
    local hw = 3 + 6 * math.sqrt(u)
    for x = math.floor(55 - hw), math.ceil(55 + hw) do put(img, x, y, C.void) end
  end
end

local function eyes(img, t)
  local on = (t >= 18 and t <= 34) and not (t == 26 or t == 27)
  if on then
    local half = (t == 18 or t == 34)
    put(img, 52, 66, half and C.eyeD or C.eye); put(img, 57, 66, half and C.eyeD or C.eye)
    if not half then put(img, 52, 67, C.eyeD); put(img, 57, 67, C.eyeD) end
  end
end

local function drawGate(img, t)
  pine(img, 36, 76, 56, 30, C.f, -(1.0 + 2.6 * gust(t, 36)), 5, {trunk = 2, t = t, flut = 1.1, ph = 1.0})
  pine(img, 75, 78, 62, 32, C.f, -(1.0 + 3.0 * gust(t, 75)), 5, {trunk = 2, t = t, flut = 1.1, ph = 2.6})
  -- moss + roots at the bases
  for _, b in ipairs({{36, 77}, {75, 79}}) do
    for x = b[1] - 5, b[1] + 5 do
      if hash(x * 3 + b[2]) > 0.35 then put(img, x, b[2], (x > b[1]) and C.grass[2] or C.grass[1]) end
    end
    put(img, b[1] - 4, b[2] + 1, C.bark[1]); put(img, b[1] + 4, b[2] + 1, C.bark[2])
  end
end

local TUFTS = {}
for i = 1, 22 do
  local a = hash(i * 31) * TAU
  local r = 0.55 + hash(i * 37) * 0.42
  local x, y = GX + math.cos(a) * GRX * r, GY + math.sin(a) * GRY * r
  if not (x > 18 and x < 44 and y > 76) then TUFTS[#TUFTS+1] = {x = round(x), y = round(y), h = 2 + round(hash(i * 41) * 3)} end
end

local function drawGrass(img, t)
  for _, g in ipairs(TUFTS) do
    local lean = 0.6 + gust(t, g.x) * 1.8
    for b = -1, 1 do
      local bh = g.h - math.abs(b)
      for k = 0, bh - 1 do
        local u = k / math.max(1, bh - 1)
        local col = (k == bh - 1) and C.grass[3] or ((b < 0) and C.grass[1] or C.grass[2])
        put(img, g.x + b * 1 - lean * u * u, g.y - k, col)
      end
    end
  end
end

------------------------------------------------------------------ RED
local RED_X, RED_Y = 13, 53
local redFrames = {}
do
  local s = app.open((os.getenv("LRRH_SPRITES") or ".") .. "/red_anime.aseprite")
  for f = 1, #s.frames do local im = Image(32, 32, ColorMode.RGB); im:drawSprite(s, f); redFrames[f] = im end
  s:close()
end
local function isCape(c)
  local r, g = pc.rgbaR(c), pc.rgbaG(c)
  return pc.rgbaA(c) > 0 and r > 105 and r > g + 40
end

local function drawRed(img, t)
  local s = redFrames[1 + t % #redFrames]   -- 24-frame windy idle: flowing cape, flapping hood, blink
  -- contact shadow
  ellipse(img, RED_X + 15, RED_Y + 31, 7, 1.6, C.shadowD)
  for y = 0, 31 do for x = 0, 31 do
    local c = s:getPixel(x, y)
    if pc.rgbaA(c) > 0 then put(img, RED_X + x, RED_Y + y, c) end
  end end
  -- cool rim light on the right edge (light from upper right)
  for y = 0, 31 do for x = 0, 30 do
    local c = s:getPixel(x, y)
    if pc.rgbaA(c) > 0 and pc.rgbaA(s:getPixel(x + 1, y)) == 0 and isCape(c) then
      put(img, RED_X + x, RED_Y + y, rgb("#e0606e"))
    end
  end end
end

------------------------------------------------------------------ WIND
local LEAVES, STREAKS = {}, {}
for i = 1, 11 do
  LEAVES[i] = {x0 = hash(i * 83) * 144, y0 = 20 + hash(i * 89) * 64, sp = (i % 4 == 0) and 6 or 3,
               ph = hash(i * 97) * TAU, amp = 2 + hash(i * 101) * 4, col = C.leaf[1 + i % 4]}
end
for i = 1, 5 do
  STREAKS[i] = {x0 = hash(i * 107) * 144, y = 16 + hash(i * 109) * 64, len = 8 + round(hash(i * 113) * 10), ph = hash(i * 127) * TAU}
end
local function drawWind(img, t)
  for _, s in ipairs(STREAKS) do
    local x = (s.x0 - 6 * t) % 144 - 20
    for k = 0, s.len - 1 do
      local e = k / (s.len - 1)
      if e > 0.08 and e < 0.92 then
        local yy = s.y + math.sin((x + k) * 0.2 + s.ph) * 1.6
        put(img, x + k, yy, (e > 0.3 and e < 0.6) and C.streakL or C.streak)
      end
    end
  end
  for _, l in ipairs(LEAVES) do
    local x = (l.x0 - l.sp * t) % 144 - 20
    local y = l.y0 + l.amp * math.sin(TAU * t / 24 + l.ph)
    local spin = (t + round(l.ph * 3)) % 4
    put(img, x, y, l.col)
    if spin == 0 then put(img, x + 1, y, l.col) elseif spin == 1 then put(img, x + 1, y - 1, l.col)
    elseif spin == 2 then put(img, x, y - 1, l.col) end
  end
end

------------------------------------------------------------------ BUILD
local layerDefs = {
  {"background", drawBG},
  {"ground", drawGround},
  {"back trees", drawBack},
  {"eyes", eyes},
  {"gate trees", drawGate},
  {"grass", drawGrass},
  {"red", drawRed},
  {"wind", drawWind},
}
local s = Sprite(W, H, ColorMode.RGB)
for i = 2, N do s:newEmptyFrame() end
for i = 1, N do s.frames[i].duration = 0.08 end
local layers = {s.layers[1]}
layers[1].name = layerDefs[1][1]
for i = 2, #layerDefs do local l = s:newLayer(); l.name = layerDefs[i][1]; layers[i] = l end
for i, def in ipairs(layerDefs) do
  for t = 0, N - 1 do
    local img = Image(W, H, ColorMode.RGB)
    def[2](img, t)
    s:newCel(layers[i], s.frames[t + 1], img, Point(0, 0))
  end
end
local tg = s:newTag(1, N); tg.name = "loop"
return s
