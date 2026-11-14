-- Builds dock_branch.aseprite / dock_branch.png: the briar ornament beside the card
-- dock (left side; the game mirrors it for the right). Matches the dock concept: a pale
-- thorny branch, serrated red leaves, glossy berries. Also writes the dock frame's corner.
-- 124x60, transparent, drawn at 2x in the game. Re-run with dofile() after tweaks.
-- The first, chunkier version is kept in _v1/.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local W, H = 124, 60

local PAL = {
  fr = "7a6555", fl = "a08670",                          -- frame
  bd = "4e3427", bm = "86654c", bl = "b08b6a", bh = "d0ad86", -- branch
  ld = "6e0f18", lm = "b11d26", ll = "dc3a32",          -- leaves
  st = "5a1a1c",                                         -- stems
  rd = "7c0d16", rm = "c8242c", rl = "e8545a", rh = "ffd6cc", -- berries
}
local g = {}
for y = 0, H - 1 do g[y] = {} end
local function get(x, y) return g[y] and g[y][x] end
local function set(x, y, c) x, y = math.floor(x), math.floor(y); if x >= 0 and x < W and y >= 0 and y < H then g[y][x] = c end end
local function line(x0, y0, x1, y1, c)
  x0, y0, x1, y1 = math.floor(x0 + .5), math.floor(y0 + .5), math.floor(x1 + .5), math.floor(y1 + .5)
  local dx, sx = math.abs(x1 - x0), x0 < x1 and 1 or -1
  local dy, sy = -math.abs(y1 - y0), y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    set(x0, y0, c)
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end

-- The frame runs around the whole dock (drawn by the game); only its corner piece is
-- exported here, as dock_corner.png (top-left; the game flips it for the other corners).
local CORNER = {
  "ffffffffffffffff",
  "f...............",
  "f.lllllllllll...",
  "f.l.............",
  "f.l.lll..l......",
  "f.l.l.l.l.......",
  "f.l.ll.l........",
  "f.l...l.........",
  "f.l..l..........",
  "f.l.l...........",
  "f.l.............",
  "f.l.............",
  "f...............",
}
local CT = { f = "fr", l = "fl" }

-- Branch: Catmull-Rom spline through control points, stamped as tapering discs.
local wood = {}
local function mark(x, y) x, y = math.floor(x), math.floor(y); if x >= 1 and x < W - 1 and y >= 1 and y < H - 1 then wood[y * W + x] = true end end
local function disc(cx, cy, r)
  for y = math.floor(cy - r), math.ceil(cy + r) do
    for x = math.floor(cx - r), math.ceil(cx + r) do
      if (x + .5 - cx) ^ 2 + (y + .5 - cy) ^ 2 <= r * r then mark(x, y) end
    end
  end
end
local thorns = {}
local function path(pts, r0, r1, thornEvery)
  local n = #pts
  local total = (n - 1) * 24
  local k = 0
  for i = 1, n - 1 do
    local p0, p1, p2, p3 = pts[math.max(1, i - 1)], pts[i], pts[i + 1], pts[math.min(n, i + 2)]
    for s = 0, 23 do
      local t = s / 24
      local t2, t3 = t * t, t * t * t
      local function cr(a, b, c, d) return .5 * (2*b + (-a + c)*t + (2*a - 5*b + 4*c - d)*t2 + (-a + 3*b - 3*c + d)*t3) end
      local x, y = cr(p0[1], p1[1], p2[1], p3[1]), cr(p0[2], p1[2], p2[2], p3[2])
      disc(x, y, r0 + (r1 - r0) * (k / total))
      if thornEvery and k % thornEvery == thornEvery // 2 then
        local dx, dy = p2[1] - p1[1], p2[2] - p1[2]
        local len = math.sqrt(dx * dx + dy * dy)
        local side = (k // thornEvery) % 2 == 0 and 1 or -1
        thorns[#thorns + 1] = { x, y, side * -dy / len, side * dx / len, dx / len, dy / len, r0 + (r1 - r0) * (k / total) }
      end
      k = k + 1
    end
  end
  local last = pts[n]; disc(last[1], last[2], r1)
end
-- Main limb from the lower outer corner, up and over in an S toward the cards.
path({ {2, 58}, {8, 52}, {16, 43}, {27, 34}, {41, 29}, {54, 31}, {65, 39}, {76, 45}, {88, 42}, {98, 33}, {106, 22}, {111, 14} }, 3.0, 0.9, 17)
-- Twigs.
path({ {41, 29}, {48, 22}, {56, 16}, {63, 13} }, 1.3, 0.7, 30)
path({ {22, 38}, {25, 30}, {27, 22}, {28, 15} }, 1.1, 0.7, nil)
path({ {16, 43}, {11, 41}, {8, 36} }, 1.2, 0.7, nil)
path({ {66, 40}, {65, 46}, {63, 51} }, 0.9, 0.6, nil)
path({ {88, 42}, {95, 46}, {101, 50} }, 0.9, 0.6, nil)
path({ {98, 33}, {103, 33}, {108, 30} }, 0.8, 0.6, nil)

-- Shade the wood: lit top edge, dark underside, mottled bark down the middle.
for y = 0, H - 1 do
  for x = 0, W - 1 do
    if wood[y * W + x] then
      local up, down = wood[(y - 1) * W + x], wood[(y + 1) * W + x]
      if not up then set(x, y, "bl")
      elseif not down then set(x, y, "bd")
      else set(x, y, "bm") end
    end
  end
end
local seed = 7
local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
for y = 0, H - 1 do
  for x = 0, W - 1 do
    local c = get(x, y)
    if c == "bm" and rnd() < .16 then set(x, y, "bd")
    elseif c == "bl" and rnd() < .12 then set(x, y, "bh") end
  end
end
-- Forked bare tips, as on the concept's twigs.
for _, f in ipairs({ { 63, 13, 67, 9 }, { 63, 13, 68, 13 }, { 111, 14, 114, 9 }, { 111, 14, 117, 14 },
                     { 108, 30, 111, 27 }, { 8, 36, 6, 32 } }) do
  line(f[1], f[2], f[3], f[4], "bm")
end
-- Thorns: a base pixel and a dark point, leaning along the limb.
for _, t in ipairs(thorns) do
  local x, y, nx, ny, tx, ty, r = table.unpack(t)
  local bx, by = x + nx * (r + .4), y + ny * (r + .4)
  set(bx, by, "bm")
  set(bx + nx * 1.2 + tx * .9, by + ny * 1.2 + ty * .9, "bd")
end

-- Leaves at any angle: pointed ovate blade, serrated edge, dark vein, lit on the up-left side.
local function leaf(bx, by, deg, L, Wd)
  local a = math.rad(deg)
  local dx, dy = math.sin(a), -math.cos(a)  -- 0 deg points up
  local px, py = -dy, dx
  local lightSide = (px * -1 + py * -1) > 0 and 1 or -1
  line(bx - dx * 2, by - dy * 2, bx, by, "st")
  for y = math.floor(by - L - 2), math.ceil(by + L + 2) do
    for x = math.floor(bx - L - 2), math.ceil(bx + L + 2) do
      local ox, oy = x + .5 - bx, y + .5 - by
      local u, v = ox * dx + oy * dy, ox * px + oy * py
      if u >= 0 and u <= L then
        local t = u / L
        local prof = t < .38 and (t / .38) ^ .6 or ((1 - t) / .62) ^ .85
        local half = Wd * prof
        local notch = (math.floor(u) % 3 == 2) and half > 1.4
        if math.abs(v) <= half and not (notch and math.abs(v) > half - .9) then
          local c
          if math.abs(v) < .55 and t < .85 then c = "ld"
          elseif v * lightSide > half * .45 then c = "ll"
          elseif v * lightSide < -half * .5 then c = "ld"
          else c = "lm" end
          set(x, y, c)
        end
      end
    end
  end
end
line(78, 44, 80, 34, "st")
leaf(80, 31, 0, 12, 4.4)  -- trifoliate group above the limb
leaf(78, 36, -68, 9, 3.4)
leaf(82, 36, 68, 9, 3.4)
leaf(63, 51, 230, 9, 3.6)
leaf(101, 50, 110, 12, 4.2)
leaf(93, 46, 150, 10, 3.6)
leaf(28, 15, -35, 10, 3.8)
leaf(23, 24, -80, 9, 3.4)
leaf(8, 36, -15, 8, 3.2)

-- Berries: round, glossy, on thin dark stems.
local function berry(cx, cy, sx, sy)
  line(sx, sy, cx, cy, "st")
  local r = 3.0
  for y = math.floor(cy - 3), math.ceil(cy + 3) do
    for x = math.floor(cx - 3), math.ceil(cx + 3) do
      local ox, oy = x + .5 - cx, y + .5 - cy
      if ox * ox + oy * oy <= r * r then
        local s = ox + oy
        set(x, y, s < -1.6 and "rl" or s > 1.4 and "rd" or "rm")
      end
    end
  end
  set(cx - 1, cy - 1, "rh")
end
for _, b in ipairs({ { 31, 17, 27, 22 }, { 22, 27, 25, 28 }, { 33, 27, 26, 26 }, { 38, 21, 28, 21 } }) do berry(b[1], b[2], b[3], b[4]) end
for _, b in ipairs({ { 46, 39, 46, 31 }, { 42, 44, 46, 33 }, { 50, 44, 47, 33 } }) do berry(b[1], b[2], b[3], b[4]) end

-- Write the sprite and the PNG.
local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "panel"
local img = Image(W, H, ColorMode.RGB)
for y = 0, H - 1 do
  for x = 0, W - 1 do
    local c = g[y][x]
    if c then
      local hex = PAL[c]
      img:drawPixel(x, y, app.pixelColor.rgba(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), 255))
    end
  end
end
spr.cels[1].image = img
spr:saveAs(HERE .. "/dock_branch.aseprite")
spr:saveCopyAs(HERE .. "/dock_branch.png")
local cw, ch = #CORNER[1], #CORNER
local corner = Image(cw, ch, ColorMode.RGB)
for r = 1, ch do
  for c = 1, cw do
    local k = CORNER[r]:sub(c, c)
    if k ~= "." then
      local hex = PAL[CT[k]]
      corner:drawPixel(c - 1, r - 1, app.pixelColor.rgba(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), 255))
    end
  end
end
corner:saveAs(HERE .. "/dock_corner.png")
return spr
