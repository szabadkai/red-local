-- Wolf fight diorama: Little Red and the woodcutter fight the big bad wolf in a
-- forest clearing; grandma cheers from her cottage doorstep.
-- The characters are the roster's own game frames (not redrawn).
-- Run from run_lua:  spr = dofile("<this file>")
local W, H = 192, 152
local ROSTER = (os.getenv("LRRH_SPRITES") or ".") .. "/"
local pc = app.pixelColor
local function hex(h)
  return pc.rgba(tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16), 255)
end

-- palette ---------------------------------------------------------------
local K = {
  O = hex("#141526"),
  G1 = hex("#2e6b4a"), G2 = hex("#4f9a52"), G3 = hex("#7cc35a"), G4 = hex("#b8e070"),
  P0 = hex("#1d3b3a"),
  D1 = hex("#c9a777"), D2 = hex("#9e7d58"), DL = hex("#ece2c6"),
  S3 = hex("#8f5c45"), S2 = hex("#6e4538"), S1 = hex("#4b2f30"),
  R2 = hex("#8c8aa3"), R1 = hex("#5d5b78"),
  WD3 = hex("#a8714a"), WD2 = hex("#7a4c35"), WD1 = hex("#4e2f2a"),  -- plinth wood
  BR = hex("#e0b04a"), BRd = hex("#a8742e"),                          -- brass trim
  Y = hex("#fff1b8"), FL = hex("#e35d5b"), WH = hex("#f6ecee"),
}

-- helpers ---------------------------------------------------------------
local function set(img, x, y, c)
  x, y = math.floor(x + 0.5), math.floor(y + 0.5)
  if x >= 0 and y >= 0 and x < W and y < H then img:drawPixel(x, y, c) end
end
local function get(img, x, y)
  if x < 0 or y < 0 or x >= W or y >= H then return 0 end
  return img:getPixel(x, y)
end
local function noise(x, y, s)
  local n = math.sin(x * 12.9898 + y * 78.233 + (s or 0) * 37.719) * 43758.5453
  return n - math.floor(n)
end
local function vnoise(x, y, sc, s)
  local gx, gy = x / sc, y / sc
  local x0, y0 = math.floor(gx), math.floor(gy)
  local fx, fy = gx - x0, gy - y0
  local a, b = noise(x0, y0, s), noise(x0 + 1, y0, s)
  local c, d = noise(x0, y0 + 1, s), noise(x0 + 1, y0 + 1, s)
  local u, v = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
  return (a * (1 - u) + b * u) * (1 - v) + (c * (1 - u) + d * u) * v
end
local function outline(img, col)
  local add = {}
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if pc.rgbaA(img:getPixel(x, y)) == 0 then
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
          local p = get(img, x + d[1], y + d[2])
          if pc.rgbaA(p) > 0 and p ~= col then add[#add + 1] = { x, y }; break end
        end
      end
    end
  end
  for _, p in ipairs(add) do img:drawPixel(p[1], p[2], col) end
end
local function rect(img, x0, y0, x1, y1, c)
  for y = y0, y1 do for x = x0, x1 do set(img, x, y, c) end end
end

-- diorama geometry ------------------------------------------------------
local CX, CY, RX, RY = 96, 90, 88, 28
local DEPTH, BASE = 16, 9
local GY = 101  -- fighters' feet row
local function inEllipse(x, y, cx, cy, rx, ry)
  local a, b = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
  return a * a + b * b <= 1
end
local function yFront(x, cx, cy, rx, ry)
  local t = (x + 0.5 - cx) / rx
  if math.abs(t) > 1 then return nil end
  return cy + ry * math.sqrt(1 - t * t)
end

local function drawDiorama(img)
  -- wooden plinth with a brass band, a slightly wider cylinder under the soil
  local bcy = CY + DEPTH
  for x = 0, W - 1 do
    local yf = yFront(x, CX, bcy, RX + 2, RY + 1)
    if yf then
      local t = (x + 0.5 - CX) / (RX + 2)
      for y = math.floor(yf) - 2 * RY, math.floor(yf) do
        if inEllipse(x, y, CX, bcy, RX + 2, RY + 1) then set(img, x, y, K.WD3) end
      end
      for d = 1, BASE do
        local y = math.floor(yf) + d
        local c = (t > 0.55) and K.WD1 or K.WD2
        if d == 1 then c = (t > 0.55) and K.WD2 or K.WD3
        elseif d == 4 then c = (t > 0.55) and K.BRd or K.BR
        elseif d == 5 then c = K.BRd
        elseif d >= BASE - 1 then c = K.WD1 end
        -- plank seams
        if d > 5 and d < BASE - 1 and (x % 11 == 0) then c = K.WD1 end
        set(img, x, y, c)
      end
    end
  end
  -- little nameplate on the front of the plinth
  local py = math.floor(yFront(CX, CX, bcy, RX + 2, RY + 1)) + 3
  rect(img, CX - 11, py, CX + 10, py + 4, K.BRd)
  rect(img, CX - 10, py + 1, CX + 9, py + 3, K.BR)
  for x = CX - 8, CX + 7, 3 do set(img, x, py + 2, K.BRd); set(img, x + 1, py + 2, K.BRd) end

  -- soil cylinder side
  for x = 0, W - 1 do
    local yf = yFront(x, CX, CY, RX, RY)
    if yf then
      local t = (x + 0.5 - CX) / RX
      local lip = 1 + ((noise(x, 3) > 0.55) and 1 or 0) + ((noise(x, 9) > 0.85) and 1 or 0)
      for d = 0, DEPTH do
        local y = math.floor(yf) + d
        local c
        if d <= lip then c = K.G1
        elseif d <= 7 then c = (t < -0.45) and K.S3 or ((t > 0.5) and K.S1 or K.S2)
        elseif d <= 10 then
          local r = vnoise(x, y, 3, 5)
          c = (r > 0.45) and ((t > 0.5) and K.R1 or K.R2) or ((t > 0.5) and K.S1 or K.S2)
          if d == 10 and r > 0.45 then c = K.R1 end
        else c = (t < -0.45) and K.S2 or K.S1 end
        set(img, x, y, c)
      end
      if noise(x, 21) > 0.93 then
        local len = 2 + math.floor(noise(x, 22) * 4)
        for d = 1, len do set(img, x, math.floor(yf) + lip + d, (d == len) and K.G2 or K.G1) end
      end
    end
  end
  -- grass top
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if inEllipse(x, y, CX, CY, RX, RY) then
        local c = K.G2
        if vnoise(x, y, 7, 1) > 0.62 then c = K.G3 end
        if vnoise(x, y, 6, 2) < 0.28 then c = K.G1 end
        set(img, x, y, c)
      end
    end
  end
  for x = 0, W - 1 do
    local yf = yFront(x, CX, CY, RX, RY)
    if yf then set(img, x, math.ceil(2 * CY - yf), K.G3) end
  end
  -- dirt: the fight clearing plus a path to grandma's door
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local a, b = (x + 0.5 - 104) / 50, (y + 0.5 - 99) / 11
      local e = a * a + b * b + (vnoise(x, y, 3, 4) - 0.5) * 0.5
      -- path: a wobbly band from the clearing up to the door (x~58, y~76)
      local pt = (y - 76) / 20
      if pt >= 0 and pt <= 1 then
        local pxc = 58 + pt * 22 + math.sin(pt * 3) * 3
        local pe = math.abs(x + 0.5 - pxc) / (3 + pt * 4) + (vnoise(x, y, 2, 7) - 0.5) * 0.6
        e = math.min(e, pe)
      end
      if e < 1 then
        local c = K.D1
        if e > 0.82 or noise(x, y, 6) < 0.07 then c = K.D2 end
        set(img, x, y, c)
      end
    end
  end
  -- tufts and flowers
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local p = get(img, x, y)
      if (p == K.G2 or p == K.G3 or p == K.G1) and noise(x, y, 7) < 0.03
         and inEllipse(x, y - 2, CX, CY, RX - 2, RY - 1) then
        set(img, x - 1, y, K.G1); set(img, x + 1, y, K.G1)
        set(img, x, y - 1, K.G4); set(img, x, y, K.G3)
      elseif (p == K.G2 or p == K.G3) and noise(x, y, 8) < 0.008 then
        set(img, x, y, (noise(x, y, 9) < 0.5) and K.WH or K.Y)
      end
    end
  end
  outline(img, K.O)
end

-- grandma's cottage -----------------------------------------------------
local HX0, HX1, HBY = 44, 71, 75  -- front wall x range, ground row
local function drawCottage(img)
  local top = HBY - 15
  -- side wall (depth, in shade) going back to the right
  for i = 0, 9 do
    for y = top - i // 2, HBY - i // 2 do set(img, HX1 + 1 + i, y, K.D2) end
  end
  -- front wall: plaster with a timber frame
  rect(img, HX0, top, HX1, HBY, K.DL)
  rect(img, HX0, top, HX0, HBY, K.S2); rect(img, HX1, top, HX1, HBY, K.S2)
  rect(img, HX0, top + 6, HX1, top + 6, K.S2)
  rect(img, HX0, HBY, HX1, HBY, K.S1)
  -- door (grandma stands in front of it) and a warm window
  rect(img, 54, HBY - 10, 61, HBY - 1, K.S1)
  rect(img, 55, HBY - 9, 60, HBY - 1, K.S2)
  set(img, 59, HBY - 5, K.BR)
  rect(img, 64, top + 2, 69, top + 5, K.Y)
  rect(img, 64, top + 8, 69, top + 12, K.Y)
  set(img, 66, top + 8, K.S2); set(img, 66, top + 9, K.S2); set(img, 66, top + 10, K.S2); set(img, 66, top + 11, K.S2); set(img, 66, top + 12, K.S2)
  rect(img, 64, top + 10, 69, top + 10, K.S2)
  rect(img, 46, top + 8, 51, top + 12, K.Y)
  rect(img, 46, top + 10, 51, top + 10, K.S2)
  set(img, 48, top + 8, K.S2); set(img, 48, top + 9, K.S2); set(img, 48, top + 11, K.S2); set(img, 48, top + 12, K.S2)
  -- flower box under the left window
  rect(img, 45, top + 13, 52, top + 13, K.S2)
  for x = 45, 52, 2 do set(img, x, top + 12, (x % 4 == 1) and K.FL or K.G3) end
  -- gable roof: slate tiles, front gable plus the slope going back
  local apx, apy = (HX0 + HX1) / 2, top - 13
  for y = apy, top do
    local f = (y - apy) / (top - apy)
    local hw = f * ((HX1 - HX0) / 2 + 3)
    for x = math.floor(apx - hw), math.ceil(apx + hw) do
      -- back slope: everything right of the front gable edge, shifted up-right
      set(img, x, y, K.DL)
    end
  end
  -- roof slope surface (visible from the front-right)
  for y = apy, top + 1 do
    local f = (y - apy) / (top + 1 - apy)
    local xe = apx + f * ((HX1 - HX0) / 2 + 3)
    for i = 0, 11 do
      local x, yy = math.floor(xe + i), y - i // 2
      local c = ((y + i // 2) % 3 == 0) and K.R1 or K.R2
      if i == 11 then c = K.R1 end
      set(img, x, yy, c)
    end
  end
  -- bargeboards (timber on the gable edges)
  for y = apy, top + 1 do
    local f = (y - apy) / (top + 1 - apy)
    local hw = f * ((HX1 - HX0) / 2 + 3)
    set(img, apx - hw, y, K.S2); set(img, apx - hw - 1, y, K.S2)
    set(img, apx + hw, y, K.S1); set(img, apx + hw + 1, y, K.S1)
  end
  -- round attic window
  rect(img, 57, top - 6, 58, top - 3, K.Y)
  -- chimney on the roof slope
  rect(img, 70, top - 18, 73, top - 7, K.R1)
  rect(img, 70, top - 18, 71, top - 7, K.R2)
  rect(img, 69, top - 19, 74, top - 19, K.R1)
end

-- trees -----------------------------------------------------------------
local function shadowBlob(img, x, y, rx, ry)
  for yy = y - ry, y + ry do
    for xx = x - rx, x + rx do
      if inEllipse(xx, yy, x, y, rx, ry) then
        local p = get(img, xx, yy)
        if p == K.G2 or p == K.G3 or p == K.G4 then set(img, xx, yy, K.G1)
        elseif p == K.G1 then set(img, xx, yy, K.P0) end
      end
    end
  end
end
local function pine(img, x, by, h)
  for y = by - 3, by do set(img, x, y, K.S2); set(img, x + 1, y, K.S1) end
  local top = by - h
  local tiers = 3
  local th = math.floor((h - 3) / tiers)
  for y = top, by - 3 do
    local rel = y - top
    local tier = math.min(tiers - 1, rel // th)
    local within = rel - tier * th
    local hw = math.floor(0.5 + tier * 1.5 + within * 0.9)
    for dx = -hw, hw + 1 do
      local c = K.G1
      local u = (dx - 0.5) / (hw + 1)
      if u < -0.25 then c = K.G2 end
      if u < -0.6 and within < th - 1 then c = K.G3 end
      if u > 0.45 then c = K.P0 end
      if within == th - 1 and u > -0.6 then c = K.P0 end
      set(img, x + dx, y, c)
    end
  end
end
local function roundTree(img, x, by, r)
  for y = by - 4, by do set(img, x, y, K.S2); set(img, x + 1, y, K.S1) end
  local cyc = by - 4 - r
  local blobs = { { 0, 0, r }, { -r * 0.6, r * 0.3, r * 0.7 }, { r * 0.65, r * 0.25, r * 0.7 }, { -0.2 * r, -r * 0.55, r * 0.7 } }
  for y = cyc - 2 * r, by do
    for xx = x - 2 * r, x + 2 * r do
      local inside = false
      for _, b in ipairs(blobs) do
        if inEllipse(xx, y, x + 0.5 + b[1], cyc + b[2], b[3], b[3]) then inside = true end
      end
      if inside then
        local dx, dy = (xx - x) / r, (y - cyc) / r
        local l = dx + dy * 1.1
        local c = K.G2
        if l < -0.55 then c = K.G3 end
        if l < -1.15 then c = K.G4 end
        if l > 0.35 then c = K.G1 end
        if l > 1.0 then c = K.P0 end
        if noise(xx, y, 11) < 0.06 and c ~= K.P0 then c = K.G1 end
        set(img, xx, y, c)
      end
    end
  end
end
local TREES = {
  { "pine", 16, 86, 28 }, { "round", 29, 74, 8 }, { "pine", 88, 68, 34 },
  { "round", 104, 66, 8 }, { "pine", 121, 66, 30 }, { "round", 140, 67, 9 },
  { "pine", 158, 72, 32 }, { "round", 174, 82, 8 },
}
local function drawTrees(img, ground)
  for _, t in ipairs(TREES) do
    local w = (t[1] == "pine") and math.floor(t[4] / 4) or t[4]
    shadowBlob(ground, t[2] + 3, t[3] + 1, w + 1, 2)
  end
  shadowBlob(ground, (HX0 + HX1) / 2 + 6, HBY + 2, 17, 2)
  for _, t in ipairs(TREES) do
    if t[1] == "pine" then pine(img, t[2], t[3], t[4]) else roundTree(img, t[2], t[3], t[4]) end
  end
  drawCottage(img)
  outline(img, K.O)
end

-- front props -----------------------------------------------------------
local function bush(img, x, y, r)
  for yy = y - r, y + 1 do
    for xx = x - r - 2, x + r + 2 do
      if inEllipse(xx, yy, x + 0.5, y + 1, r + 2, r + 1) then
        local l = (xx - x) / r + (yy - y) / r
        local c = K.G2
        if l < -0.6 then c = K.G3 end
        if l > 0.5 then c = K.G1 end
        set(img, xx, yy, c)
      end
    end
  end
  set(img, x - 1, y - r, K.G4)
end
local function drawFront(img)
  for _, b in ipairs({ { 14, 2 }, { 40, 3 }, { 150, 2 }, { 178, 3 } }) do
    local yf = math.floor(yFront(b[1], CX, CY, RX, RY))
    bush(img, b[1], yf, b[2])
  end
  -- the woodcutter's stump, front right
  local sx, sy = 162, 108
  rect(img, sx, sy - 4, sx + 7, sy, K.S2)
  rect(img, sx, sy - 4, sx + 2, sy, K.S3)
  rect(img, sx + 6, sy - 4, sx + 7, sy, K.S1)
  rect(img, sx, sy - 5, sx + 7, sy - 5, K.D1)
  rect(img, sx + 2, sy - 5, sx + 5, sy - 5, K.DL)
  set(img, sx + 3, sy - 5, K.D2)
  -- a few mushrooms by the front-left bush
  for _, m in ipairs({ { 47, 113 }, { 51, 114 } }) do
    set(img, m[1], m[2], K.DL); set(img, m[1], m[2] - 1, K.FL); set(img, m[1] - 1, m[2] - 1, K.FL); set(img, m[1] + 1, m[2] - 1, K.FL)
    set(img, m[1], m[2] - 2, K.FL); set(img, m[1] - 1, m[2] - 1, K.WH)
  end
  outline(img, K.O)
end

-- roster characters -----------------------------------------------------
local function loadFrames(name)
  local src = Sprite { fromFile = ROSTER .. name .. ".aseprite" }
  local frames = {}
  for i = 1, #src.frames do
    local img = Image(src.width, src.height, ColorMode.RGB)
    img:drawSprite(src, i)
    frames[i] = img
  end
  src:close()
  return frames
end
local CH = {
  R = loadFrames("little_red_riding_hood_small"),
  Wf = loadFrames("big_bad_wolf"),
  C = loadFrames("woodcutter_small"),
  G = loadFrames("grandmother_small"),
}
-- cell (32x32, feet on row 31) placed with its centre column at cx, feet at gy
local function blit(img, frames, f, cx, gy, flip)
  local src = frames[f]
  local x0, y0 = cx - 16, gy - 31
  for y = 0, 31 do
    for x = 0, 31 do
      local p = src:getPixel(flip and (31 - x) or x, y)
      if pc.rgbaA(p) > 0 then set(img, x0 + x, y0 + y, p) end
    end
  end
end

-- effects ---------------------------------------------------------------
local function star(img, x, y, s)
  for i = 1, s do
    local c = (i < s) and K.WH or K.Y
    set(img, x + i, y, c); set(img, x - i, y, c); set(img, x, y + i, c); set(img, x, y - i, c)
  end
  for i = 1, s - 2 do
    set(img, x + i, y - i, K.Y); set(img, x - i, y + i, K.Y)
    set(img, x - i, y - i, K.Y); set(img, x + i, y + i, K.Y)
  end
  set(img, x, y, K.WH)
end
local function burst(img, x, y, r)
  for a = 0, 359, 30 do
    local ra = math.rad(a + 15)
    set(img, x + math.cos(ra) * r, y + math.sin(ra) * r * 0.8, K.Y)
    set(img, x + math.cos(ra) * (r + 1), y + math.sin(ra) * (r + 1) * 0.8, K.WH)
  end
end
local function dust(img, x, y, dir, phase)
  local puffs = (phase == 1) and { { 0, 0, 1 }, { 3, -1, 1 } } or { { 2, -1, 1 }, { 6, -2, 0 } }
  for _, p in ipairs(puffs) do
    local px_, py_ = x + p[1] * dir, y + p[2]
    set(img, px_, py_, K.DL); set(img, px_ + dir, py_, K.DL)
    if p[3] == 1 then
      set(img, px_, py_ - 1, K.DL); set(img, px_ + dir, py_ + 1, K.D1); set(img, px_ - dir, py_, K.D1)
    end
  end
end

-- the fight, frame by frame -------------------------------------------------
-- R/Wf/C: { roster frame, centre x, lift }. Wolf and woodcutter face left.
-- Roster frames: idle 1-4, run 5-8, attack 9-14, special 15-22, hit 23-26.
local FR = {
  -- standoff
  { d = 160, R = { 1, 70 }, Wf = { 1, 104 }, C = { 1, 140 } },
  { d = 160, R = { 2, 70 }, Wf = { 2, 104 }, C = { 2, 140 } },
  -- Red swings her basket back, up over her head and whacks the wolf's snout
  -- (her roster attack 9-13: wind-up, overhead, over the top, whack, follow-through)
  { d = 140, R = { 9, 70 }, Wf = { 3, 104 }, C = { 3, 140 } },
  { d = 90, R = { 10, 70 }, Wf = { 4, 104 }, C = { 4, 140 } },
  { d = 60, R = { 11, 75 }, Wf = { 4, 104 }, C = { 1, 140 } },
  { d = 180, R = { 12, 79 }, Wf = { 23, 103 }, C = { 2, 140 }, star = { 95, 90, 4 } },
  -- the woodcutter winds up as the wolf stumbles towards him, and chops
  { d = 100, R = { 13, 78 }, Wf = { 24, 108 }, C = { 9, 140 }, burst = { 95, 90, 6 }, dust = { 116, 1, 1 } },
  { d = 100, R = { 14, 75 }, Wf = { 25, 112 }, C = { 10, 140 }, dust = { 121, 1, 2 } },
  { d = 60, R = { 1, 72 }, Wf = { 26, 114 }, C = { 11, 139 } },
  { d = 160, R = { 2, 71 }, Wf = { 23, 111 }, C = { 12, 139 }, star = { 122, 82, 4 } },
  { d = 100, R = { 3, 70 }, Wf = { 24, 108 }, C = { 13, 140 }, burst = { 122, 82, 6 }, dust = { 95, -1, 1 } },
  { d = 100, R = { 4, 70 }, Wf = { 25, 106 }, C = { 14, 140 }, dust = { 93, -1, 2 } },
  { d = 120, R = { 1, 70 }, Wf = { 26, 105 }, C = { 1, 140 } },
  -- the wolf, furious, pounces at Red and bowls her over
  { d = 120, R = { 2, 70 }, Wf = { 15, 105 }, C = { 2, 140 } },
  { d = 80, R = { 3, 70 }, Wf = { 16, 100, 3 }, C = { 3, 140 } },
  { d = 70, R = { 4, 70 }, Wf = { 17, 94, 6 }, C = { 4, 140 } },
  { d = 160, R = { 23, 68 }, Wf = { 18, 89, 4 }, C = { 1, 140 }, star = { 76, 86, 4 } },
  { d = 100, R = { 24, 65 }, Wf = { 19, 90, 1 }, C = { 2, 140 }, burst = { 76, 86, 6 }, dust = { 72, -1, 1 } },
  -- Red bounces back up; the wolf hops back into the middle
  { d = 100, R = { 25, 64 }, Wf = { 20, 94, 3 }, C = { 3, 140 }, dust = { 70, -1, 2 } },
  { d = 100, R = { 26, 66 }, Wf = { 21, 99, 2 }, C = { 4, 140 } },
  { d = 120, R = { 1, 68 }, Wf = { 22, 103 }, C = { 1, 140 }, dust = { 110, 1, 1 } },
  { d = 140, R = { 2, 70 }, Wf = { 3, 104 }, C = { 2, 140 }, dust = { 112, 1, 2 } },
}
local N = #FR

-- grandma cheers on a cycle of 11 (N = 22 = 2 cycles, so the loop is seamless)
local GRAN = { 1, 2, 9, 10, 11, 12, 11, 12, 13, 14, 3 }

-- ambience: leaves, butterflies, chimney smoke; each cycle divides N
local LEAVES = { { 30, 54, 0.0 }, { 140, 50, 0.5 }, { 106, 50, 0.25 } }
local BUTTERFLIES = { { 30, 92, 0.0, K.WH }, { 168, 88, 0.45, K.Y } }

-- build -----------------------------------------------------------------
local spr = Sprite(W, H, ColorMode.RGB)
for _ = 2, N do spr:newEmptyFrame() end
local function newLayer(name, opacity)
  local l = spr:newLayer(); l.name = name; l.opacity = opacity or 255
  return l
end
local lDio = spr.layers[1]; lDio.name = "diorama"
local lShadow = newLayer("shadows", 110)
local lTrees = newLayer("cottage_trees")
local lGran = newLayer("grandma")
local lChars = newLayer("fighters")
local lFx = newLayer("fx")
local lFront = newLayer("front")

local dio = Image(W, H, ColorMode.RGB)
local trees = Image(W, H, ColorMode.RGB)
drawDiorama(dio)
drawTrees(trees, dio)
local front = Image(W, H, ColorMode.RGB)
drawFront(front)

local function shadowAt(img, x, rx)
  for y = GY - 1, GY + 2 do
    for xx = x - 14, x + 14 do
      if inEllipse(xx, y, x, GY + 0.5, rx, 1.6) then set(img, xx, y, K.O) end
    end
  end
end

for f = 1, N do
  local fr = FR[f]
  spr.frames[f].duration = fr.d / 1000
  spr:newCel(lDio, f, dio, Point(0, 0))
  spr:newCel(lTrees, f, trees, Point(0, 0))
  spr:newCel(lFront, f, front, Point(0, 0))

  local sh = Image(W, H, ColorMode.RGB)
  shadowAt(sh, fr.R[2], 7)
  shadowAt(sh, fr.C[2], 8)
  local wl = fr.Wf[3] or 0
  shadowAt(sh, fr.Wf[2], (wl > 3) and 8 or 11)
  spr:newCel(lShadow, f, sh, Point(0, 0))

  local g = Image(W, H, ColorMode.RGB)
  blit(g, CH.G, GRAN[(f - 1) % #GRAN + 1], 35, HBY + 6, false)
  spr:newCel(lGran, f, g, Point(0, 0))

  -- draw back to front: woodcutter, wolf, Red
  local ch = Image(W, H, ColorMode.RGB)
  blit(ch, CH.C, fr.C[1], fr.C[2], GY, true)
  blit(ch, CH.Wf, fr.Wf[1], fr.Wf[2], GY - wl, true)
  blit(ch, CH.R, fr.R[1], fr.R[2], GY, false)
  spr:newCel(lChars, f, ch, Point(0, 0))

  local fx = Image(W, H, ColorMode.RGB)
  if fr.star then star(fx, fr.star[1], fr.star[2], fr.star[3]) end
  if fr.burst then burst(fx, fr.burst[1], fr.burst[2], fr.burst[3]) end
  if fr.dust then dust(fx, fr.dust[1], GY, fr.dust[2], fr.dust[3]) end
  local ph = (f - 1) / N
  for _, lf in ipairs(LEAVES) do
    local t = (ph + lf[3]) % 1
    local x = lf[1] + math.floor(3 * math.sin(t * 2 * math.pi * 2) + 0.5)
    local y = lf[2] + math.floor(t * 30)
    set(fx, x, y, K.G4); set(fx, x + ((math.floor(t * 8) % 2 == 0) and 1 or -1), y, K.G3)
  end
  for _, b in ipairs(BUTTERFLIES) do
    local a = 2 * math.pi * (ph + b[3])
    local x = b[1] + math.floor(6 * math.cos(a) + 0.5)
    local y = b[2] + math.floor(3 * math.sin(2 * a) + 0.5)
    set(fx, x, y, b[4])
    if f % 2 == 0 then set(fx, x - 1, y - 1, b[4]); set(fx, x + 1, y - 1, b[4])
    else set(fx, x - 1, y, b[4]); set(fx, x + 1, y, b[4]) end
  end
  -- chimney smoke: three puffs rising on an 11-frame cycle
  for i = 0, 2 do
    local t = ((f - 1) / 11 + i / 3) % 1
    local x = 72 + math.floor(t * 6 + math.sin(t * 6.28) * 1.5 + 0.5)
    local y = HBY - 15 - 21 - math.floor(t * 14)
    local c = (t < 0.5) and K.WH or K.R2
    set(fx, x, y, c); set(fx, x + 1, y, c)
    if t > 0.25 then set(fx, x, y - 1, c); set(fx, x + 1, y - 1, c) end
  end
  spr:newCel(lFx, f, fx, Point(0, 0))
end

spr:newTag(1, N).name = "fight"
return spr
