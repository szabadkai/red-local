-- Shared helpers for the LRRH enemy generators. Runs inside Aseprite (Lua 5.4).
-- Every enemy is 32x32, one "sprite" layer, 34 frames tagged
-- idle(4) run(4) attack(6) special(8) hit(4) death(8), facing right, feet on y=31,
-- matching the existing roster (big_bad_wolf, forest_crow, thorn_brambles, ...).
local L = {}
local pc = app.pixelColor
-- Bosses build on 48x48 cells: set _G.LIB_SIZE = 48 before dofile and clear it right after.
local W = rawget(_G, "LIB_SIZE") or 32
local H = W
L.W, L.H, L.TAU = W, H, math.pi * 2

local function round(v) return math.floor(v + 0.5) end
L.round = round
function L.clamp(v, a, b) return v < a and a or (v > b and b or v) end
function L.lerp(a, b, t) return a + (b - a) * t end
function L.hash(n) local s = math.sin(n * 127.1 + 311.7) * 43758.5453; return s - math.floor(s) end
function L.ease(t) return t * t * (3 - 2 * t) end

------------------------------------------------------------------ colour
function L.rgb(hex, a)
  if type(hex) ~= "string" then return hex end
  local r, g, b = tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
  local alpha = a or (#hex >= 9 and tonumber(hex:sub(8, 9), 16)) or 255
  return pc.rgba(r, g, b, alpha)
end
-- convert a (nested) table of hex strings into colour ints
function L.pal(t)
  local o = {}
  for k, v in pairs(t) do o[k] = type(v) == "table" and L.pal(v) or L.rgb(v) end
  return o
end
function L.alpha(c, a) return pc.rgba(pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c), round(a)) end
function L.mix(c1, c2, t)
  local function ch(f) return round(f(c1) + (f(c2) - f(c1)) * t) end
  return pc.rgba(ch(pc.rgbaR), ch(pc.rgbaG), ch(pc.rgbaB), ch(pc.rgbaA))
end
function L.blend(dst, src)
  local sa = pc.rgbaA(src) / 255
  if sa >= 1 or not dst then return src end
  if sa <= 0 then return dst end
  local da = pc.rgbaA(dst) / 255
  local oa = sa + da * (1 - sa)
  local function ch(f) return round((f(src) * sa + f(dst) * da * (1 - sa)) / oa) end
  return pc.rgba(ch(pc.rgbaR), ch(pc.rgbaG), ch(pc.rgbaB), round(oa * 255))
end

L.FLASH = L.rgb("#f6ecee")      -- hit-flash white used by the existing roster
L.MARK = L.FLASH                -- impact marks / dizzy swirl (same white keeps the colour count down)
L.MARK2 = L.rgb("#907b7f")

------------------------------------------------------------------ lighting
-- one light from the upper right (same as the forest scenes)
local LX, LY, LZ = 0.52, -0.62, 0.59
-- intensity 0..1 for a point (u, v) in [-1, 1] on an ellipsoid
function L.lit(u, v)
  local z = math.sqrt(math.max(0, 1 - u * u - v * v))
  return math.max(0, u * LX + v * LY + z * LZ)
end
-- pick from a dark->light ramp with intensity i (0..1)
function L.pick(ramp, i)
  local n = #ramp
  return ramp[L.clamp(math.floor(i * n) + 1, 1, n)]
end

------------------------------------------------------------------ canvas
-- Pixel (x, y) has its centre at integer (x, y). Colours are Aseprite ints; nil = clear.
local C = {}
C.__index = C
function L.canvas() return setmetatable({ p = {} }, C) end
local function inb(x, y) return x >= 0 and y >= 0 and x < W and y < H end

function C:get(x, y)
  x, y = round(x), round(y)
  if not inb(x, y) then return nil end
  return self.p[y * W + x]
end
function C:set(x, y, c)
  x, y = round(x), round(y)
  if inb(x, y) then self.p[y * W + x] = c end
end
-- alpha-composite one pixel
function C:add(x, y, c)
  x, y = round(x), round(y)
  if inb(x, y) and c then self.p[y * W + x] = L.blend(self.p[y * W + x], c) end
end
function C:dots(pts, c) for _, q in ipairs(pts) do self:set(q[1], q[2], c) end end
-- c may be a colour or fn(x, y) -> colour|nil
local function colAt(c, ...) if type(c) == "function" then return c(...) end return c end

function C:rect(x0, y0, x1, y1, c)
  for y = round(y0), round(y1) do
    for x = round(x0), round(x1) do
      local col = colAt(c, x, y)
      if col then self:set(x, y, col) end
    end
  end
end
-- filled ellipse; c may be fn(x, y, u, v) with u, v in [-1, 1]
function C:ell(cx, cy, rx, ry, c, cond)
  -- +0.25 avoids lone "nub" pixels at the four extremes of integer-radius ellipses
  rx, ry = math.max(rx, 0.01) + 0.25, math.max(ry, 0.01) + 0.25
  for y = math.floor(cy - ry) - 1, math.ceil(cy + ry) + 1 do
    for x = math.floor(cx - rx) - 1, math.ceil(cx + rx) + 1 do
      local u, v = (x - cx) / rx, (y - cy) / ry
      if u * u + v * v <= 1.0 and (not cond or cond(x, y, u, v)) then
        local col = colAt(c, x, y, u, v)
        if col then self:set(x, y, col) end
      end
    end
  end
end
-- lit ellipse from a dark->light ramp; bias brightens/darkens the whole shape
function C:ball(cx, cy, rx, ry, ramp, bias, cond)
  self:ell(cx, cy, rx, ry, function(_, _, u, v) return L.pick(ramp, L.lit(u, v) + (bias or 0)) end, cond)
end
-- filled polygon {{x,y},...}; c may be fn(x, y)
function C:poly(pts, c)
  local minx, maxx, miny, maxy = 1e9, -1e9, 1e9, -1e9
  for _, q in ipairs(pts) do
    minx, maxx = math.min(minx, q[1]), math.max(maxx, q[1])
    miny, maxy = math.min(miny, q[2]), math.max(maxy, q[2])
  end
  local n = #pts
  for y = math.floor(miny), math.ceil(maxy) do
    for x = math.floor(minx), math.ceil(maxx) do
      local inside, j = false, n
      for i = 1, n do
        local xi, yi, xj, yj = pts[i][1], pts[i][2], pts[j][1], pts[j][2]
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then inside = not inside end
        j = i
      end
      if inside then
        local col = colAt(c, x, y)
        if col then self:set(x, y, col) end
      end
    end
  end
end
-- 1px line
function C:line(x0, y0, x1, y1, c)
  local n = math.max(math.abs(round(x1) - round(x0)), math.abs(round(y1) - round(y0)))
  if n == 0 then self:set(x0, y0, colAt(c, round(x0), round(y0), 0)) return end
  for i = 0, n do
    local t = i / n
    local x, y = round(x0 + (x1 - x0) * t), round(y0 + (y1 - y0) * t)
    local col = colAt(c, x, y, t)
    if col then self:set(x, y, col) end
  end
end
-- thick segment (capsule) of radius r; c may be fn(x, y, t, d)
function C:seg(x0, y0, x1, y1, r, c)
  local dx, dy = x1 - x0, y1 - y0
  local len2 = dx * dx + dy * dy
  for y = math.floor(math.min(y0, y1) - r) - 1, math.ceil(math.max(y0, y1) + r) + 1 do
    for x = math.floor(math.min(x0, x1) - r) - 1, math.ceil(math.max(x0, x1) + r) + 1 do
      local t = len2 > 0 and L.clamp(((x - x0) * dx + (y - y0) * dy) / len2, 0, 1) or 0
      local qx, qy = x0 + dx * t, y0 + dy * t
      local d = math.sqrt((x - qx) ^ 2 + (y - qy) ^ 2)
      if d <= r then
        local col = colAt(c, x, y, t, d)
        if col then self:set(x, y, col) end
      end
    end
  end
end
-- quadratic bezier as a chain of 1px lines (r == nil) or capsules of radius r
-- r may be a function of t for tapering
function C:curve(x0, y0, cx, cy, x1, y1, c, r, steps)
  steps = steps or 16
  local px_, py_ = x0, y0
  for i = 1, steps do
    local t = i / steps
    local a, b = (1 - t) ^ 2, 2 * (1 - t) * t
    local x = a * x0 + b * cx + t * t * x1
    local y = a * y0 + b * cy + t * t * y1
    if r then
      local rr = type(r) == "function" and r(t) or r
      self:seg(px_, py_, x, y, rr, c)
    else
      self:line(px_, py_, x, y, c)
    end
    px_, py_ = x, y
  end
end

-- 1px outline around everything opaque (4-neighbour; diag=true for 8)
function C:outline(c, diag)
  local add = {}
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if not self.p[y * W + x] then
        local hit = self:get(x - 1, y) or self:get(x + 1, y) or self:get(x, y - 1) or self:get(x, y + 1)
        if not hit and diag then
          hit = self:get(x - 1, y - 1) or self:get(x + 1, y - 1) or self:get(x - 1, y + 1) or self:get(x + 1, y + 1)
        end
        if hit then add[#add + 1] = y * W + x end
      end
    end
  end
  for _, k in ipairs(add) do self.p[k] = c end
  return self
end
-- composite another canvas on top (alpha-aware), optionally offset
function C:over(o, dx, dy)
  dx, dy = dx or 0, dy or 0
  for k, c in pairs(o.p) do self:add(k % W + dx, k // W + dy, c) end
  return self
end
function C:copy()
  local o = L.canvas()
  for k, v in pairs(self.p) do o.p[k] = v end
  return o
end
function C:shifted(dx, dy)
  local o = L.canvas()
  for k, v in pairs(self.p) do o:set(k % W + dx, k // W + dy, v) end
  return o
end
function C:flipped()
  local o = L.canvas()
  for k, v in pairs(self.p) do o:set(W - 1 - k % W, k // W, v) end
  return o
end
-- recolour; fn(colour, x, y) -> colour|nil (nil erases)
function C:recolor(fn)
  local keys = {}
  for k in pairs(self.p) do keys[#keys + 1] = k end
  for _, k in ipairs(keys) do self.p[k] = fn(self.p[k], k % W, k // W) end
  return self
end
function C:flash(c) return self:recolor(function() return c or L.FLASH end) end
function C:count() local n = 0 for _ in pairs(self.p) do n = n + 1 end return n end
-- erase pixels with no opaque 8-neighbour (stray tips left by thin fx strokes)
function C:despeckle()
  local drop = {}
  for k in pairs(self.p) do
    local x, y, alone = k % W, k // W, true
    for dy = -1, 1 do
      for dx = -1, 1 do
        if (dx ~= 0 or dy ~= 0) and self:get(x + dx, y + dy) then alone = false end
      end
    end
    if alone then drop[#drop + 1] = k end
  end
  for _, k in ipairs(drop) do self.p[k] = nil end
  return self
end
function C:image()
  local img = Image(W, H, ColorMode.RGB)
  for k, v in pairs(self.p) do img:drawPixel(k % W, k // W, v) end
  return img
end

------------------------------------------------------------------ fx
-- "! !" impact strokes like the roster's hit frames, anchored at their lower-left
function L.impact(c, x, y, col)
  col = col or L.MARK
  c:line(x, y - 4, x, y - 2, col)
  c:set(x, y, col)
  c:line(x + 3, y - 4, x + 2, y - 1, col)
  c:line(x + 4, y + 1, x + 5, y + 1, L.MARK2)
end
-- dizzy swirl floating above a knocked-out enemy; k picks the wobble pose
local SWIRL = {
  { ".###.", "#...#", "#.#.#", "#..#.", ".##.." },
  { ".##..", "#..#.", "#.#.#", "#...#", ".###." },
}
function L.dizzy(c, x, y, k, col)
  col = col or L.MARK
  local g = SWIRL[(k % 2) + 1]
  for j, row in ipairs(g) do
    for i = 1, #row do
      if row:sub(i, i) == "#" then c:set(x + i - 1, y + j - 1, col) end
    end
  end
  c:set(x + 2, y + 5 + (k % 2), L.MARK2)
end
-- plus-shaped twinkle; size 0 = dot, 1 = plus, 2 = long plus
function L.sparkle(c, x, y, col, size, core)
  size = size or 1
  c:set(x, y, core or col)
  for s = 1, size do
    c:set(x - s, y, col); c:set(x + s, y, col); c:set(x, y - s, col); c:set(x, y + s, col)
  end
end
-- soft dust puff made of a few overlapping blobs
function L.puff(c, x, y, r, ramp, seed)
  seed = seed or 1
  for i = 0, 2 do
    local ox = (L.hash(seed * 7 + i) - 0.5) * r * 1.4
    local oy = (L.hash(seed * 13 + i) - 0.5) * r * 0.8
    c:ball(x + ox, y + oy, r * (0.6 + 0.4 * L.hash(seed + i * 3)), r * 0.7, ramp)
  end
end
-- horizontal speed streaks trailing to the left of x
function L.streaks(c, x, y, n, len, col, seed)
  for i = 0, n - 1 do
    local yy = y + i * 3 + round(L.hash((seed or 1) + i) * 2)
    local l = len - round(L.hash((seed or 1) * 3 + i) * len * 0.4)
    c:line(x - l, yy, x, yy, col)
  end
end
-- flat ground shadow (opaque: no partial alpha anywhere, so sheet and GIF agree)
function L.shadow(c, cx, y, rx, col)
  c:ell(cx, y, rx, math.max(0.6, rx * 0.22), col or L.rgb("#24202a"))
end

------------------------------------------------------------------ build + export
L.ORDER = { "idle", "run", "attack", "special", "hit", "death" }
L.DUR = {
  idle = { 200, 160, 200, 160 },
  run = { 100, 100, 100, 100 },
  attack = { 140, 60, 90, 120, 100, 120 },
  special = { 100, 90, 90, 90, 90, 90, 120, 100 },
  hit = { 60, 100, 120, 120 },
  death = { 100, 100, 80, 140, 160, 160, 160, 500 },
}

-- draw(tag, i, n) -> canvas, i is 0-based within the tag.
-- Writes <dir>/<name>.aseprite, <name>_sheet.png/.json (one row per tag) and
-- <name>_preview_x4.gif; also a big review PNG on the roster background if review is given.
function L.build(name, dir, draw, review)
  local spr = Sprite(W, H, ColorMode.RGB)
  spr.layers[1].name = "sprite"
  local f, ranges = 1, {}
  for _, tag in ipairs(L.ORDER) do
    local durs, from = L.DUR[tag], f
    for i = 1, #durs do
      if f > 1 then spr:newEmptyFrame(f) end
      spr.frames[f].duration = durs[i] / 1000
      local cv = draw(tag, i - 1, #durs)
      spr:newCel(spr.layers[1], f, cv:image(), Point(0, 0))
      f = f + 1
    end
    ranges[#ranges + 1] = { tag, from, f - 1 }
  end
  -- tags last: inserting frames right after a tag would stretch it
  for _, r in ipairs(ranges) do
    local t = spr:newTag(r[2], r[3])
    t.name = r[1]
  end
  local base = dir .. "/" .. name
  spr:saveAs(base .. ".aseprite")
  app.command.ExportSpriteSheet {
    ui = false, askOverwrite = false,
    type = SpriteSheetType.ROWS,
    textureFilename = base .. "_sheet.png",
    dataFilename = base .. "_sheet.json",
    dataFormat = SpriteSheetDataFormat.JSON_ARRAY,
    filenameFormat = "{title} #{tag} {tagframe}.{extension}",   -- {extension} has no dot
    splitTags = true, listLayers = true, listTags = true, listSlices = true,
    trim = false, trimSprite = false, mergeDuplicates = false, openGenerated = false,
  }
  app.command.SaveFileCopyAs { ui = false, filename = base .. "_preview_x4.gif", scale = 4 }
  if review then L.review(base .. "_sheet.png", review, 4) end
  return spr
end

-- nearest-neighbour blow-up of a sheet over the concept-art background, with a cell grid
function L.review(src, dst, s)
  local img = Image { fromFile = src }
  local out = Image(img.width * s, img.height * s, ColorMode.RGB)
  local bg, bg2, grid = L.rgb("#4a4450"), L.rgb("#45404b"), L.rgb("#5a5462")
  for y = 0, out.height - 1 do
    for x = 0, out.width - 1 do
      local sx, sy = x // s, y // s
      local c = img:getPixel(sx, sy)
      local base = ((sx // W + sy // H) % 2 == 0) and bg or bg2
      if (x % (W * s) == 0) or (y % (H * s) == 0) then base = grid end
      local a = pc.rgbaA(c)
      out:drawPixel(x, y, a == 0 and base or (a == 255 and c or L.blend(base, c)))
    end
  end
  out:saveAs(dst)
end

------------------------------------------------------------------ rigs (used by brown_bear, forest_stag)
-- local -> world transform: translate to (x, y), rotate by rot (negative = nose up)
function L.xf(x, y, rot)
  local c, s = math.cos(rot or 0), math.sin(rot or 0)
  return function(lx, ly) return x + lx * c - ly * s, y + lx * s + ly * c end
end
-- rotate a sub-part about local pivot (px, py) by a, then offset, then apply tf
function L.pivot(tf, px, py, a, dx, dy)
  local c, s = math.cos(a or 0), math.sin(a or 0)
  dx, dy = dx or 0, dy or 0
  return function(lx, ly)
    local rx, ry = lx - px, ly - py
    return tf(px + rx * c - ry * s + dx, py + rx * s + ry * c + dy)
  end
end
function L.mapPts(tf, pts)
  local o = {}
  for i, q in ipairs(pts) do
    local x, y = tf(q[1], q[2])
    o[i] = { x, y }
  end
  return o
end
function L.ellPoly(tf, cx, cy, rx, ry)
  local o = {}
  for i = 0, 31 do
    local a = i / 32 * L.TAU
    o[#o + 1] = { cx + math.cos(a) * rx, cy + math.sin(a) * ry }
  end
  return L.mapPts(tf, o)
end
function L.bounds(m)
  local x0, y0, x1, y1 = 99, 99, -1, -1
  for k in pairs(m.p) do
    local x, y = k % W, k // W
    x0, x1 = math.min(x0, x), math.max(x1, x)
    y0, y1 = math.min(y0, y), math.max(y1, y)
  end
  return x0, y0, x1, y1
end
-- shade mask m into dst: vertical gradient + rim light (upper right) + rim shadow (lower left).
-- rim (optional) is the mask used for edge tests, so a part overlapping another gets no seam
function L.shade(dst, m, ramp, bias, rim)
  rim = rim or m
  local x0, y0, x1, y1 = L.bounds(m)
  for k in pairs(m.p) do
    local x, y = k % W, k // W
    local v = (y - y0) / math.max(1, y1 - y0)
    local h = (x - x0) / math.max(1, x1 - x0)
    local i = 0.86 - 0.62 * v + 0.16 * (h - 0.5) + (bias or 0)
    if not rim:get(x, y - 1) or not rim:get(x + 1, y - 1) then i = i + 0.26
    elseif not rim:get(x + 1, y - 2) or not rim:get(x, y - 2) then i = i + 0.1 end
    if not m:get(x, y + 1) or not rim:get(x - 1, y + 1) then i = i - 0.3 end
    dst:set(x, y, L.pick(ramp, i))
  end
end

------------------------------------------------------------------ hand-drawn poses (bear, stag, mushroom, ghost hunter)
-- data file returns { pal = { key = "#hex" }, poses = { { "row", ... }, ... } }; '.' is transparent
function L.poses(path)
  local d = dofile(path)
  local pal = {}
  for k, v in pairs(d.pal) do pal[k] = L.rgb(v) end
  local list = {}
  for n, rows in ipairs(d.poses) do list[n] = L.grid(rows, pal) end
  return pal, list
end
function L.grid(rows, pal, ox, oy, c)
  c = c or L.canvas()
  for y, row in ipairs(rows) do
    for x = 1, #row do
      local ch = row:sub(x, x)
      if ch ~= "." and ch ~= " " then c:set((ox or 0) + x - 1, (oy or 0) + y - 1, pal[ch]) end
    end
  end
  return c
end
-- pixels matching cond(x, y, col) move by (dx, dy) and are drawn over the rest
function C:move(cond, dx, dy)
  local o, moved = L.canvas(), {}
  for k, v in pairs(self.p) do
    local x, y = k % W, k // W
    if cond(x, y, v) then moved[#moved + 1] = { x + dx, y + dy, v } else o.p[k] = v end
  end
  for _, m in ipairs(moved) do o:set(m[1], m[2], m[3]) end
  return o
end
function C:keep(cond)
  local o = L.canvas()
  for k, v in pairs(self.p) do if cond(k % W, k // W, v) then o.p[k] = v end end
  return o
end
-- largest 8-connected blob (the character) and everything else (effects)
function C:split()
  local seen, best = {}, nil
  for k in pairs(self.p) do
    if not seen[k] then
      local st, comp = { k }, {}
      seen[k] = true
      while #st > 0 do
        local q = table.remove(st)
        comp[#comp + 1] = q
        local x, y = q % W, q // W
        for dy = -1, 1 do
          for dx = -1, 1 do
            local nx, ny = x + dx, y + dy
            local nk = ny * W + nx
            if nx >= 0 and ny >= 0 and nx < W and ny < H and self.p[nk] and not seen[nk] then
              seen[nk] = true; st[#st + 1] = nk
            end
          end
        end
      end
      if not best or #comp > #best then best = comp end
    end
  end
  local body, fx = L.canvas(), self:copy()
  for _, k in ipairs(best or {}) do body.p[k] = self.p[k]; fx.p[k] = nil end
  return body, fx
end
function C:find(col)
  local o = {}
  for k, v in pairs(self.p) do if v == col then o[#o + 1] = { k % W, k // W } end end
  table.sort(o, function(a, b) return a[2] < b[2] or (a[2] == b[2] and a[1] < b[1]) end)
  return o
end

-- eye swaps for the concept characters (yellow eyes): "shut" = dark lid line, "x" = knocked-out X
-- "squint" keeps only the bottom row of each eye lit (for dark faces where a dark lid would vanish);
-- xcol colours the X (defaults to the outline colour)
function L.eyes(c, eye, mode, out, fur, xcol)
  local px_ = c:find(eye)
  if #px_ == 0 then return c end
  if mode == "squint" then
    local low = {}
    for _, q in ipairs(px_) do low[q[1]] = math.max(low[q[1]] or -1, q[2]) end
    for _, q in ipairs(px_) do if q[2] ~= low[q[1]] then c:set(q[1], q[2], fur) end end
  elseif mode == "shut" then
    local low = {}
    for _, q in ipairs(px_) do low[q[1]] = math.max(low[q[1]] or -1, q[2]) end
    for _, q in ipairs(px_) do c:set(q[1], q[2], (q[2] == low[q[1]]) and out or fur) end
  elseif mode == "x" then
    -- one X per eye blob (pixels further than 2 px apart start a new blob)
    local blobs = {}
    for _, q in ipairs(px_) do
      local hit
      for _, b in ipairs(blobs) do
        if math.abs(b.x - q[1]) <= 2 and math.abs(b.y - q[2]) <= 2 then hit = b end
      end
      if hit then hit.n = hit.n + 1; hit.sx = hit.sx + q[1]; hit.sy = hit.sy + q[2]
      else blobs[#blobs + 1] = { x = q[1], y = q[2], n = 1, sx = q[1], sy = q[2] } end
      c:set(q[1], q[2], fur)
    end
    for _, b in ipairs(blobs) do
      local x, y = L.round(b.sx / b.n), L.round(b.sy / b.n)
      c:dots({ { x - 1, y - 1 }, { x + 1, y - 1 }, { x, y }, { x - 1, y + 1 }, { x + 1, y + 1 } }, xcol or out)
    end
  end
  return c
end

-- light catching the top edge: base-colour pixels right under the outline (or air) become the light shade
function L.rim(c, base, light, out)
  local add = {}
  for k, v in pairs(c.p) do
    if v == base then
      local up = c:get(k % W, k // W - 1)
      if not up or up == out then add[#add + 1] = k end
    end
  end
  for _, k in ipairs(add) do c.p[k] = light end
  return c
end

return L
