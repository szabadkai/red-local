-- "Red at the forest's edge": 160x90, 64-frame seamless loop, layered
local pc = app.pixelColor
local W, H, N = 160, 90, 64
local TAU = math.pi * 2
local function rgb(hex, a)
  return pc.rgba(tonumber(hex:sub(2,3),16), tonumber(hex:sub(4,5),16), tonumber(hex:sub(6,7),16), a or 255)
end
local function round(v) return math.floor(v + 0.5) end
local function put(img, x, y, c)
  x, y = round(x), round(y)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then img:drawPixel(x, y, c) end
end
local function blend(img, x, y, c, a)  -- alpha blend c over existing pixel
  if x < 0 or y < 0 or x >= W or y >= H then return end
  local d = img:getPixel(x, y)
  local da = pc.rgbaA(d)
  if da == 0 then img:drawPixel(x, y, pc.rgba(pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c), a)); return end
  local k = a / 255
  img:drawPixel(x, y, pc.rgba(
    round(pc.rgbaR(d) * (1-k) + pc.rgbaR(c) * k), round(pc.rgbaG(d) * (1-k) + pc.rgbaG(c) * k),
    round(pc.rgbaB(d) * (1-k) + pc.rgbaB(c) * k), math.max(da, a)))
end
local BAYER = {{0, 8, 2, 10}, {12, 4, 14, 6}, {3, 11, 1, 9}, {15, 7, 13, 5}}
local function dith(x, y) return (BAYER[y % 4 + 1][x % 4 + 1] + 0.5) / 16 end

-- deterministic noise
local function hash(n) local s = math.sin(n * 127.1 + 311.7) * 43758.5453; return s - math.floor(s) end

local C = {
  sky = {rgb("#0b0814"), rgb("#140e20"), rgb("#1d142b"), rgb("#281a35"), rgb("#33203c")},
  halo1 = rgb("#2e2244"), halo2 = rgb("#3b2b52"),
  moon = rgb("#efe3c8"), moonS = rgb("#cbbd9f"), moonD = rgb("#a89a84"),
  cloud = rgb("#1a1226"), cloudM = rgb("#261a34"), cloudL = rgb("#4a3a5e"), cloudLL = rgb("#6c5a7c"),
  far = rgb("#1c1528"), farRim = rgb("#2a2038"),
  mid = rgb("#110c18"), midRim = rgb("#2a1f36"),
  near = rgb("#07050b"), nearRim = rgb("#2c2038"),
  void = rgb("#030205"),
  ground = rgb("#120d18"), groundL = rgb("#1a1322"),
  path = rgb("#342838"), pathL = rgb("#46374a"), pathD = rgb("#221a26"),
  grass = rgb("#1d1a26"), grassL = rgb("#2f2a3a"), grassFG = rgb("#060409"),
  leafA = rgb("#7a2e30"), leafB = rgb("#8c6248"), leafC = rgb("#4a3a2a"),
  streak = rgb("#9a8cb4"),
  eye = rgb("#ffcf40"), eyeD = rgb("#b07a20"),
  bolt = rgb("#f4eeff"), boltG = rgb("#8f7cc0"),
  flashSky = {rgb("#3c3060"), rgb("#4c3c74"), rgb("#5c4a84"), rgb("#6c5890"), rgb("#7a6498")},
}

local MOON = {x = 80, y = 17, r = 8}
local GROUND_Y = 66
local FLASH = {[40] = 1.0, [41] = 0.0, [42] = 0.7, [43] = 0.3}
local EYES_ON = function(t) return t >= 44 and t <= 60 and t ~= 52 and t ~= 53 end

-- gust strength 0..1, period 16 frames, two gusts per period shape
local function gust(t, x) return 0.5 + 0.5 * math.sin(TAU * (t / 16) + (x or 0) * 0.04) end

------------------------------------------------------------------ SKY
local function drawSky(img, t)
  local f = FLASH[t] or 0
  for y = 0, H - 1 do
    local v = math.min(1, y / 62) * 4  -- 0..4 band index
    local b = math.floor(v)
    local frac = v - b
    for x = 0, W - 1 do
      local bi = math.min(5, b + 1 + ((frac > dith(x, y)) and 1 or 0))
      local col = C.sky[bi]
      -- moon halo
      local dx, dy = x - MOON.x, y - MOON.y
      local d = math.sqrt(dx*dx + dy*dy)
      if d < 22 and d > MOON.r then
        local k = (22 - d) / 14
        if k > dith(x, y) + 0.35 then col = C.halo2 elseif k > dith(x, y) * 0.9 then col = C.halo1 end
      end
      if f > 0 then
        local fc = C.flashSky[bi]
        if f >= 1 or f > dith(x, y) then col = fc end
      end
      img:drawPixel(x, y, col)
    end
  end
  -- moon
  for y = MOON.y - MOON.r, MOON.y + MOON.r do for x = MOON.x - MOON.r, MOON.x + MOON.r do
    local dx, dy = x - MOON.x, y - MOON.y
    if dx*dx + dy*dy <= MOON.r * MOON.r + 2 then
      local col = C.moon
      if dx + dy * 0.4 < -3 then col = C.moonS end
      if (dx == -3 and dy == 2) or (dx == -2 and dy == 2) or (dx == 2 and dy == -3) or (dx == 3 and dy == 3) or (dx == 4 and dy == 3) then col = C.moonD end
      put(img, x, y, col)
    end
  end end
  -- lightning bolt
  if t == 40 or t == 42 then
    local x, y = 26, 4
    local s = 7
    while y < 58 do
      local nx = x + ((hash(s) > 0.5) and 1 or -1) * (1 + math.floor(hash(s + 1) * 2))
      for i = 0, 2 do put(img, x + (nx - x) * i / 3, y + i, C.bolt); put(img, x + (nx - x) * i / 3 + 1, y + i, C.boltG) end
      if hash(s + 2) > 0.8 then for i = 1, 6 do put(img, x - i, y + i, C.boltG) end end
      x, y, s = nx, y + 3, s + 3
    end
  end
end

------------------------------------------------------------------ CLOUDS (periodic, wrap)
local function cloudLayer(img, t, period, speed, seed, y0, y1, count, lit)
  local off = (t * speed) % period
  for i = 1, count do
    local cx = hash(seed + i) * period
    local cy = y0 + hash(seed + i * 3) * (y1 - y0)
    local len = 14 + hash(seed + i * 7) * 26
    local th = 2 + math.floor(hash(seed + i * 11) * 3)
    for rep = -1, math.ceil(W / period) + 1 do
      local bx = cx - off + rep * period
      for x = math.floor(bx - len / 2), math.ceil(bx + len / 2) do
        if x >= 0 and x < W then
          local u = (x - bx) / (len / 2)
          local hh = th * math.sqrt(math.max(0, 1 - u * u)) + 0.4 * math.sin(x * 0.9 + i)
          for yy = -math.floor(hh), math.floor(hh * 0.6) do
            local y = round(cy + yy)
            if y >= 0 and y < H then
              local col = (yy <= -math.floor(hh) + 0) and lit or C.cloudM
              if yy > 0 then col = C.cloud end
              -- edges near the moon glow brighter
              local dx, dy = x - MOON.x, y - MOON.y
              if col == lit and dx*dx + dy*dy < 260 then col = C.cloudLL end
              if FLASH[t] and FLASH[t] >= 0.7 then col = (col == C.cloud) and C.cloudL or C.cloudLL end
              img:drawPixel(x, y, col)
            end
          end
        end
      end
    end
  end
end

------------------------------------------------------------------ TREES
local function pine(img, cx, baseY, h, w, col, sway)
  for i = 0, h - 1 do
    local y = baseY - h + i
    local frac = (i + 1) / h
    local tier = (i % 5) / 4
    local hw = math.max(0, round((w / 2) * frac * (0.7 + 0.3 * tier)))
    local dx = round((sway or 0) * (1 - frac) ^ 1.5)
    for x = cx - hw, cx + hw do put(img, x + dx, y, col) end
  end
  for y = baseY, baseY + 2 do put(img, cx, y, col) end
end

local function rimLight(img, col, maxd, onlyColor)
  local copy = img:clone()
  for y = 1, H - 1 do for x = 0, W - 2 do
    local c = copy:getPixel(x, y)
    if pc.rgbaA(c) > 0 and (not onlyColor or c == onlyColor) then
      local up = pc.rgbaA(copy:getPixel(x, y - 1)) == 0
      local dir = (x < MOON.x) and 1 or -1
      local side = pc.rgbaA(copy:getPixel(math.max(0, math.min(W-1, x + dir)), y)) == 0
      local dx, dy = x - MOON.x, y - MOON.y
      if (up or side) and dx*dx + dy*dy < maxd * maxd then img:drawPixel(x, y, col) end
    end
  end end
end

local FAR, MID = {}, {}
do
  local x = -2
  local i = 0
  while x < W + 4 do
    i = i + 1
    FAR[#FAR+1] = {x = x, h = 10 + round(hash(i * 5) * 14), w = 6 + round(hash(i * 9) * 4), b = 63 + round(hash(i) * 2)}
    x = x + 4 + round(hash(i * 13) * 5)
  end
  x, i = -4, 0
  while x < W + 6 do
    i = i + 1
    local inGap = x > 100 and x < 128
    local h = 22 + round(hash(i * 17 + 3) * 22)
    if x < 40 then h = h - 8 end
    if not inGap then
      MID[#MID+1] = {x = x, h = h, w = 10 + round(hash(i * 19) * 6), b = 69 + round(hash(i * 23) * 2), ph = hash(i * 29) * TAU}
    end
    x = x + 7 + round(hash(i * 31) * 7)
  end
end

local function drawFar(img, t)
  for _, p in ipairs(FAR) do pine(img, p.x, p.b, p.h, p.w, C.far, 0) end
  rimLight(img, C.farRim, 40)
end

local function drawMid(img, t)
  for _, p in ipairs(MID) do
    local s = -round(gust(t, p.x) * 1.4 + 0.2 * math.sin(p.ph))
    pine(img, p.x, p.b, p.h, p.w, C.mid, s)
  end
  rimLight(img, C.midRim, 55)
end

-- thick polyline helper
local function stroke(img, pts, r0, r1, col)
  local total = #pts - 1
  for k = 1, total do
    local a, b = pts[k], pts[k + 1]
    local steps = math.max(math.abs(b[1] - a[1]), math.abs(b[2] - a[2])) * 2 + 1
    for s = 0, steps do
      local u = s / steps
      local x, y = a[1] + (b[1] - a[1]) * u, a[2] + (b[2] - a[2]) * u
      local r = r0 + (r1 - r0) * ((k - 1 + u) / total)
      for yy = -math.ceil(r), math.ceil(r) do for xx = -math.ceil(r), math.ceil(r) do
        if xx*xx + yy*yy <= r*r + 0.3 then put(img, x + xx, y + yy, col) end
      end end
    end
  end
end

local function drawNear(img, t)
  local g = gust(t, 110)
  local sw = -round(g * 1.5)
  -- the forest mouth: a void between two gnarled trunks
  for y = 44, GROUND_Y + 2 do
    local u = (y - 44) / (GROUND_Y + 2 - 44)
    local hw = round(4 + 8 * math.sqrt(u) + math.sin(y * 1.7) * 0.8)
    for x = 115 - hw, 115 + hw do put(img, x, y, C.void) end
  end
  -- left trunk with roots
  stroke(img, {{101, GROUND_Y + 3}, {102, 56}, {100, 44}, {102, 34}}, 3.2, 1.6, C.near)
  stroke(img, {{101, GROUND_Y + 2}, {95, GROUND_Y + 4}}, 1.5, 0.6, C.near)
  stroke(img, {{102, GROUND_Y + 2}, {108, GROUND_Y + 4}}, 1.4, 0.6, C.near)
  -- right trunk
  stroke(img, {{130, GROUND_Y + 3}, {129, 54}, {131, 42}, {129, 32}}, 3.6, 1.8, C.near)
  stroke(img, {{130, GROUND_Y + 2}, {137, GROUND_Y + 4}}, 1.5, 0.6, C.near)
  stroke(img, {{129, GROUND_Y + 2}, {123, GROUND_Y + 4}}, 1.2, 0.5, C.near)
  -- arching branches that knot over the entrance (tips sway)
  stroke(img, {{102, 40}, {108, 33}, {116, 30 + sw * 0.5}, {123 + sw, 31}}, 1.6, 0.5, C.near)
  stroke(img, {{129, 38}, {123, 32}, {114 + sw, 28}, {107 + sw, 29}}, 1.6, 0.5, C.near)
  stroke(img, {{100, 45}, {94, 40}, {89 + sw, 38}}, 1.2, 0.4, C.near)
  stroke(img, {{131, 44}, {138, 39}, {144 + sw, 38}}, 1.2, 0.4, C.near)
  -- dark canopy clumps above, tattered by the wind
  for i = 1, 26 do
    local cx = 96 + hash(i * 41) * 42 + sw
    local cy = 24 + hash(i * 43) * 12
    local r = 2.5 + hash(i * 47) * 3
    for yy = -4, 4 do for xx = -6, 6 do
      local n = hash(i * 53 + xx * 7 + yy * 13)
      if (xx * xx) / 1.6 + yy * yy <= r * r + n * 2 then put(img, cx + xx, cy + yy, C.near) end
    end end
  end
  -- framing tree on the far left with a long branch
  stroke(img, {{3, H}, {4, 60}, {2, 30}, {4, 0}}, 5, 4, C.near)
  stroke(img, {{6, 14}, {16, 9}, {28, 7 + sw * 0.4}, {40 + sw, 8 + sw * 0.3}}, 2, 0.5, C.near)
  stroke(img, {{20, 9}, {24, 14 + sw * 0.3}, {25 + sw, 19}}, 0.9, 0.4, C.near)
  stroke(img, {{32 + sw * 0.5, 7}, {35 + sw, 3}}, 0.8, 0.3, C.near)
  -- a few dead leaves clinging to the branch, fluttering
  for i = 1, 6 do
    local lx = 16 + i * 4 + sw
    local ly = 10 + (i % 2) * 2 + ((t + i * 3) % 8 < 4 and 1 or 0)
    put(img, lx, ly, (i % 2 == 0) and C.leafA or C.leafC)
  end
  rimLight(img, C.nearRim, 70)
  -- the eyes
  if EYES_ON(t) then
    local ey = 57
    local half = (t == 44 or t == 60) -- opening / closing
    put(img, 111, ey, half and C.eyeD or C.eye); put(img, 112, ey, C.eyeD)
    put(img, 118, ey, half and C.eyeD or C.eye); put(img, 119, ey, C.eyeD)
  end
end

------------------------------------------------------------------ MIST (period = width)
local function drawMist(img, t, y0, y1, speed, a0, seed)
  local off = (t * speed) % W
  for y = y0, y1 do
    local fy = 1 - math.abs((y - (y0 + y1) / 2) / ((y1 - y0) / 2 + 0.5))
    for x = 0, W - 1 do
      local u = ((x + off) % W) / W * TAU
      local n = 0.5 + 0.3 * math.sin(u * 2 + seed) + 0.2 * math.sin(u * 5 + y * 0.6 + seed * 2)
      local a = n * fy
      if a > 0.35 + dith(x, y) * 0.4 then blend(img, x, y, rgb("#6a5a88"), a0) end
    end
  end
end

------------------------------------------------------------------ GROUND
local function pathEdges(y)
  local u = (H - y) / (H - GROUND_Y)
  local l = 24 + u * (110 - 24) + math.sin(y * 0.5) * 0.6
  local r = 90 + u * (121 - 90) + math.sin(y * 0.7 + 1) * 0.6
  return l, r
end

local TUFTS, FGRASS = {}, {}
for i = 1, 90 do
  local y = GROUND_Y + 1 + math.floor(hash(i * 61) ^ 1.6 * (H - GROUND_Y - 4))
  local x = math.floor(hash(i * 67) * W)
  local l, r = pathEdges(y)
  if x < l - 1 or x > r + 1 then TUFTS[#TUFTS+1] = {x = x, y = y, h = 2 + math.floor(hash(i * 71) * 3 + (y - GROUND_Y) / 10)} end
end
for x = 0, W - 1, 2 do
  if not (x > 44 and x < 72) then
    FGRASS[#FGRASS+1] = {x = x + (hash(x) > 0.5 and 1 or 0), h = 4 + math.floor(hash(x * 3 + 1) * 8)}
  end
end

local function drawGround(img, t)
  for y = GROUND_Y, H - 1 do
    local l, r = pathEdges(y)
    for x = 0, W - 1 do
      local col = ((x + y) % 7 == 0 and dith(x, y) > 0.6) and C.groundL or C.ground
      if x >= l and x <= r then
        col = C.path
        if x < l + 1.5 or x > r - 1.5 then col = C.pathD
        elseif (y > 72) and dith(x, y) > 0.82 then col = C.pathL end
      end
      img:drawPixel(x, y, col)
    end
  end
  -- moonlight wash on the path near the entrance
  for y = GROUND_Y, GROUND_Y + 8 do
    local l, r = pathEdges(y)
    for x = math.floor(l) + 2, math.floor(r) - 2 do
      if dith(x, y) > 0.5 + (y - GROUND_Y) / 16 then img:drawPixel(x, y, C.pathL) end
    end
  end
  -- grass tufts leaning away from the wind (wind blows right -> left)
  for _, g in ipairs(TUFTS) do
    local lean = 1 + round(gust(t, g.x) * 1.2)
    for b = -1, 1 do
      local bh = g.h - math.abs(b)
      for k = 0, bh - 1 do
        local u = k / math.max(1, bh - 1)
        put(img, g.x + b - lean * u * u, g.y - k, (k == bh - 1) and C.grassL or C.grass)
      end
    end
  end
end

local function drawFG(img, t)
  for _, g in ipairs(FGRASS) do
    local lean = 1 + round(gust(t, g.x) * 2.2)
    for k = 0, g.h - 1 do
      local u = k / math.max(1, g.h - 1)
      put(img, g.x - lean * u * u, H - 1 - k, C.grassFG)
      if k < g.h / 2 then put(img, g.x + 1 - lean * u * u, H - 1 - k, C.grassFG) end
    end
  end
end

------------------------------------------------------------------ WIND FX (seamless: travel 192px per 64 frames multiples)
local LEAVES = {}
for i = 1, 16 do
  LEAVES[i] = {x0 = hash(i * 83) * 192, y0 = 30 + hash(i * 89) * 56, sp = (i % 3 == 0) and 6 or 3,
               ph = hash(i * 97) * TAU, amp = 2 + hash(i * 101) * 4,
               col = ({C.leafA, C.leafB, C.leafC})[1 + i % 3]}
end
local STREAKS = {}
for i = 1, 9 do
  STREAKS[i] = {x0 = hash(i * 107) * 192, y = 22 + hash(i * 109) * 62, len = 10 + round(hash(i * 113) * 16),
                ph = hash(i * 127) * TAU, a = 120 + round(hash(i * 131) * 90)}
end

local function drawWind(img, t)
  for _, s in ipairs(STREAKS) do
    local x = (s.x0 - 6 * t) % 192 - 16
    for k = 0, s.len - 1 do
      local fade = 1 - math.abs(k / (s.len - 1) - 0.4) * 1.4
      if fade > 0 then
        local yy = s.y + math.sin((x + k) * 0.18 + s.ph) * 1.5
        blend(img, round(x + k), round(yy), C.streak, round(s.a * fade))
      end
    end
  end
  for _, l in ipairs(LEAVES) do
    local x = (l.x0 - l.sp * t) % 192 - 16
    local y = l.y0 + l.amp * math.sin(TAU * t / 32 + l.ph)
    local spin = (t + round(l.ph * 3)) % 4
    put(img, x, y, l.col)
    if spin == 0 then put(img, x + 1, y, l.col)
    elseif spin == 1 then put(img, x + 1, y - 1, l.col)
    elseif spin == 2 then put(img, x, y - 1, l.col) end
  end
end

------------------------------------------------------------------ RED
local RED_X, RED_Y = 42, 52
local redFrames = {}
do
  local s = app.open((os.getenv("LRRH_SPRITES") or ".") .. "/little_red_riding_hood.aseprite")
  for f = 1, 4 do
    local im = Image(32, 32, ColorMode.RGB); im:drawSprite(s, f); redFrames[f] = im
  end
  s:close()
end
local function isCape(c)
  local r, g = pc.rgbaR(c), pc.rgbaG(c)
  return pc.rgbaA(c) > 0 and r > 105 and r > g + 40
end

local function drawRed(img, t)
  local base = redFrames[1 + (t // 4) % 4]
  local spr = base:clone()
  -- cape billows to the left in the wind
  for y = 9, 30 do
    local lx
    for x = 0, 31 do if pc.rgbaA(base:getPixel(x, y)) > 0 then lx = x; break end end
    if lx and isCape(base:getPixel(lx, y)) or (lx and isCape(base:getPixel(lx + 1, y))) then
      local v = (y - 9) / 21
      local wave = 0.5 + 0.5 * math.sin(TAU * t / 8 - y * 0.55)
      local ext = round((0.8 + 4.6 * v ^ 1.3) * (0.35 + 0.65 * wave) * (0.65 + 0.35 * gust(t, 50)))
      local ec = base:getPixel(lx + 1, y)
      if not isCape(ec) then ec = base:getPixel(lx, y) end
      for k = 1, ext do
        local col = (k == ext) and rgb("#88293a") or ec
        if spr.width > lx - k and lx - k >= 0 then spr:drawPixel(lx - k, y, col) end
      end
    end
  end
  -- soft shadow at her feet
  for x = RED_X + 8, RED_X + 22 do
    local u = (x - (RED_X + 15)) / 7.5
    if math.abs(u) <= 1 then blend(img, x, RED_Y + 31, rgb("#08050c"), 150) end
    if math.abs(u) <= 0.7 then blend(img, x, RED_Y + 32, rgb("#08050c"), 90) end
  end
  for y = 0, 31 do for x = 0, 31 do
    local c = spr:getPixel(x, y)
    if pc.rgbaA(c) > 0 then
      -- lightning lights her from the left
      if (FLASH[t] or 0) >= 0.7 then
        local k = 0.25
        c = pc.rgba(round(pc.rgbaR(c) + (255 - pc.rgbaR(c)) * k), round(pc.rgbaG(c) + (220 - pc.rgbaG(c)) * k * 0.6),
                    round(pc.rgbaB(c) + (255 - pc.rgbaB(c)) * k), 255)
      end
      put(img, RED_X + x, RED_Y + y, c)
    end
  end end
  -- moonlit rim on her hood/cape (moon is up and to the right)
  for y = 0, 31 do for x = 0, 31 do
    local c = spr:getPixel(x, y)
    if isCape(c) and (pc.rgbaA(spr:getPixel(x, math.max(0, y - 1))) == 0) then
      put(img, RED_X + x, RED_Y + y, rgb("#d8586a"))
    end
  end end
end

------------------------------------------------------------------ BUILD
local layerDefs = {
  {"sky",        function(img, t) drawSky(img, t) end},
  {"clouds far", function(img, t) cloudLayer(img, t, 64, 1, 11, 4, 30, 3, C.cloudL) end},
  {"far trees",  drawFar},
  {"mist far",   function(img, t) drawMist(img, t, 50, 64, 2.5, 90, 1.3) end},
  {"mid trees",  drawMid},
  {"clouds near",function(img, t) cloudLayer(img, t, 128, 2, 29, 2, 24, 4, C.cloudL) end},
  {"forest mouth", drawNear},
  {"ground",     drawGround},
  {"mist near",  function(img, t) drawMist(img, t, 60, 74, 5, 70, 4.1) end},
  {"red",        drawRed},
  {"wind",       drawWind},
  {"foreground", drawFG},
}

local s = Sprite(W, H, ColorMode.RGB)
for i = 2, N do s:newEmptyFrame() end
for i = 1, N do s.frames[i].duration = 0.07 end
s.frames[41].duration = 0.05; s.frames[42].duration = 0.05
local layers = {}
layers[1] = s.layers[1]; layers[1].name = layerDefs[1][1]
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
