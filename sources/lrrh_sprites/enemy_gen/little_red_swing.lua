-- little_red_swing.lua: Little Red's overhead basket-swing whack, at any scale.
-- Builds the 5 swing frames of her `attack` tag (9-13) from two of her own bodies:
-- the idle body (basket at her belly, cut out and filled with skirt) and the lunge body
-- (outstretched arm and basket cut away). The arm and basket are redrawn in her colours.
--   local swing = dofile(".../little_red_swing.lua")
--   local frames = swing.build(idleImg, lungeImg, swing.LARGE)   -- or swing.SMALL
-- Used by little_red_attack.lua (the 23 px original) and shrink/little_red_riding_hood_small.lua
-- (the 18 px game size; row cuts would slice the moving basket, so the small swing is drawn
-- from the small bodies instead of being shrunk).
local M = {}
local pc = app.pixelColor
local function hex(h)
  return pc.rgba(tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16), 255)
end
local CLEAR = pc.rgba(0, 0, 0, 0)
local C = {
  e = hex("#4b2228"), D = hex("#f7e7df"), G = hex("#e0c7c6"), Cc = hex("#ca9476"),
  o = hex("#9d806c"), p = hex("#87735d"), sleeve = hex("#b62e41"), skin = hex("#efc099"),
  skirt = hex("#3d3439"), skirtD = hex("#2d262c"), E = hex("#f9d8a6"),
}
M.COLORS = C
-- basket, handle on top (row 1), hanging straight down
local BASKET = {
  "..eee..",
  ".e...e.",
  "eDDGDDe",
  "eCoCoCe",
  "eopopoe",
  ".eeeee.",
}
local BK = { e = C.e, D = C.D, G = C.G, C = C.Cc, o = C.o, p = C.p }

-- per-scale geometry: where the held basket sits on the idle body, where the arm leaves the
-- lunge body, the shoulder, and each frame's arm angle / reach / smear (angles: 0 = forward, 90 = up)
M.LARGE = {
  idleCut = { x0 = 14, x1 = 21, y0 = 24, y1 = 29, skirtTo = 26, trim = { 20, 22 }, edge = 19 },
  lungeCut = function(x, y) return x >= 19 and (y >= 19 or x >= 26) end,
  shoulder = { 18, 22 },
  poses = {
    { body = "idle", behind = true, deg = 198, len = 11, ms = 140 },               -- 9 wind-up
    { body = "idle", behind = true, deg = 100, len = 14, ms = 90 },                -- 10 overhead
    { body = "lunge", deg = 50, len = 7, smear = { 140, 55, 10, 13 }, ms = 60 },   -- 11 over the top
    { body = "lunge", deg = 20, len = 7, smear = { 95, 25, 10, 13 }, ms = 140 },   -- 12 WHACK
    { body = "lunge", deg = -35, len = 7, ms = 100 },                              -- 13 follow-through
  },
}
M.SMALL = {
  idleCut = { x0 = 13, x1 = 21, y0 = 25, y1 = 29, skirtTo = 26, trim = { 19, 22 }, edge = 18 },
  lungeCut = function(x, y) return x >= 19 and y >= 19 end,
  shoulder = { 18, 24 },
  poses = {
    { body = "idle", behind = true, deg = 198, len = 11, ms = 140 },
    { body = "idle", behind = true, deg = 100, len = 12, ms = 90 },
    { body = "lunge", deg = 50, len = 6, smear = { 140, 55, 9, 12 }, ms = 60 },
    { body = "lunge", deg = 20, len = 6, smear = { 95, 25, 9, 12 }, ms = 140 },
    { body = "lunge", deg = -35, len = 6, ms = 100 },
  },
}

local function set(img, x, y, c)
  x, y = math.floor(x + 0.5), math.floor(y + 0.5)
  if x >= 0 and y >= 0 and x < 32 and y < 32 then img:drawPixel(x, y, c) end
end
local function isRed(p)
  local r, g, b = pc.rgbaR(p), pc.rgbaG(p), pc.rgbaB(p)
  return r > 100 and r > g * 1.6 and r > b * 1.4
end
local function copy(src) local img = Image(32, 32, ColorMode.RGB); img:drawImage(src, Point(0, 0)); return img end

-- idle body: the held basket becomes skirt, trimmed back to body width
function M.idleBody(src, cut)
  local img = copy(src)
  for y = cut.y0, cut.y1 do
    for x = cut.x0, cut.x1 do
      local p = img:getPixel(x, y)
      if pc.rgbaA(p) > 0 and not isRed(p) then img:drawPixel(x, y, (y <= cut.skirtTo) and C.skirt or C.skirtD) end
    end
    for x = cut.trim[1], cut.trim[2] do img:drawPixel(x, y, CLEAR) end
    img:drawPixel(cut.edge, y, C.skirtD)
  end
  return img
end
-- lunge body: the outstretched arm, basket and old smear removed
function M.lungeBody(src, cutFn)
  local img = copy(src)
  for y = 0, 31 do for x = 0, 31 do if cutFn(x, y) then img:drawPixel(x, y, CLEAR) end end end
  return img
end

-- arm from the shoulder to the hand, then the basket hanging off the hand along the swing
-- radius (snapped to the nearest quarter turn)
local function armAndBasket(img, sx, sy, deg, len)
  local a = math.rad(deg)
  local dx, dy = math.cos(a), -math.sin(a)
  local hx, hy = sx + dx * len, sy + dy * len
  for i = 0, len do set(img, sx + dx * i, sy + dy * i, (i < len - 1) and C.sleeve or C.skin) end
  set(img, hx + 0.5 * dy, hy - 0.5 * dx, C.skin)
  local q = math.floor(((deg % 360) + 45) / 90) % 4  -- 0 right, 1 up, 2 left, 3 down
  local bx, by = math.floor(hx + dx * 1.2 + 0.5), math.floor(hy + dy * 1.2 + 0.5)
  for gy, row in ipairs(BASKET) do
    for gx = 1, #row do
      local ch = row:sub(gx, gx)
      if ch ~= "." then
        local u, v = gx - 4, gy - 1
        local ox, oy
        if q == 3 then ox, oy = u, v
        elseif q == 0 then ox, oy = v, u
        elseif q == 1 then ox, oy = u, -v
        else ox, oy = -v, u end
        set(img, bx + ox, by + oy, BK[ch])
      end
    end
  end
end
-- pale swing arc (the old attack's smear colours), thicker towards the leading edge
local function smear(img, sx, sy, a0, a1, r0, r1)
  local step = (a1 > a0) and 3 or -3
  for a = a0, a1, step do
    local ra = math.rad(a)
    local f = (a - a0) / (a1 - a0)
    for r = r0, r1 do
      if r <= r0 + 1 + f * (r1 - r0) then
        set(img, sx + math.cos(ra) * r, sy - math.sin(ra) * r, (r >= r1 - 1) and C.D or C.E)
      end
    end
  end
end

-- returns { img, ... } for frames 9-13 and their durations in ms
function M.build(idleSrc, lungeSrc, cfg)
  local bodies = { idle = M.idleBody(idleSrc, cfg.idleCut), lunge = M.lungeBody(lungeSrc, cfg.lungeCut) }
  local sx, sy = cfg.shoulder[1], cfg.shoulder[2]
  local frames, ms = {}, {}
  for _, p in ipairs(cfg.poses) do
    local img = Image(32, 32, ColorMode.RGB)
    if p.smear then smear(img, sx, sy, p.smear[1], p.smear[2], p.smear[3], p.smear[4]) end
    if p.behind then armAndBasket(img, sx, sy, p.deg, p.len) end
    img:drawImage(bodies[p.body], Point(0, 0))
    if not p.behind then armAndBasket(img, sx, sy, p.deg, p.len) end
    frames[#frames + 1] = img
    ms[#ms + 1] = p.ms
  end
  return frames, ms
end

return M
