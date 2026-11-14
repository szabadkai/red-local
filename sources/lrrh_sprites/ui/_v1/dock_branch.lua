-- Builds dock_branch.aseprite / dock_branch.png: the thorny briar ornament in the
-- corner of the card dock (left side; the game mirrors it for the right side).
-- 128x64, transparent, drawn at 2x in the game. Re-run with dofile() after tweaks.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local W, H = 128, 64

local PAL = {
  ink = "1c1216",
  bd = "3b2620", bm = "634232", bl = "8c6446", bh = "b08a5c",
  ld = "5a1424", lm = "9a2633", ll = "cf4a44",
  rd = "6e1020", rm = "c0303a", rh = "f2b8a4",
}
local g = {}
for y = 0, H - 1 do g[y] = {} end
local function get(x, y) return g[y] and g[y][x] end
local function set(x, y, c) if x >= 0 and x < W and y >= 0 and y < H then g[y][x] = c end end

-- Wood mask: stamp discs along bezier curves and spirals.
local wood = {}
local function mark(x, y) if x >= 0 and x < W and y >= 0 and y < H then wood[y * W + x] = true end end
local function disc(cx, cy, r)
  for y = math.floor(cy - r), math.ceil(cy + r) do
    for x = math.floor(cx - r), math.ceil(cx + r) do
      if (x + .5 - cx) ^ 2 + (y + .5 - cy) ^ 2 <= r * r then mark(x, y) end
    end
  end
end
local thornAt = {}
local function bezier(p0, p1, p2, p3, r0, r1, thorns)
  local steps = 120
  for i = 0, steps do
    local t = i / steps
    local u = 1 - t
    local x = u^3*p0[1] + 3*u*u*t*p1[1] + 3*u*t*t*p2[1] + t^3*p3[1]
    local y = u^3*p0[2] + 3*u*u*t*p1[2] + 3*u*t*t*p2[2] + t^3*p3[2]
    local r = r0 + (r1 - r0) * t
    disc(x, y, r)
    if thorns and i > 0 and i < steps and i % thorns == 0 then
      local dx = -3*u*u*p0[1] + 3*(u*u - 2*u*t)*p1[1] + 3*(2*u*t - t*t)*p2[1] + 3*t*t*p3[1]
      local dy = -3*u*u*p0[2] + 3*(u*u - 2*u*t)*p1[2] + 3*(2*u*t - t*t)*p2[2] + 3*t*t*p3[2]
      local len = math.sqrt(dx*dx + dy*dy)
      local side = (i // thorns) % 2 == 0 and 1 or -1
      thornAt[#thornAt + 1] = { x, y, side * -dy / len, side * dx / len, dx / len, dy / len, r }
    end
  end
end
local function spiral(cx, cy, r0, r1, a0, a1, w0, w1)
  local steps = 90
  for i = 0, steps do
    local t = i / steps
    local a = a0 + (a1 - a0) * t
    local r = r0 + (r1 - r0) * t
    disc(cx + r * math.cos(a), cy + r * math.sin(a), w0 + (w1 - w0) * t)
  end
end

-- Main limb sweeps in low from the left edge, rises and ends in a curl.
bezier({-2, 58}, {28, 62}, {52, 30}, {98, 25}, 3.6, 2.2, 14)
spiral(103, 34, 9, 2.5, -math.pi / 2 - .35, math.pi * 1.25, 2.2, 1.1)
-- Upper twig toward a leaf, lower twig carrying berries.
bezier({38, 46}, {38, 34}, {46, 20}, {60, 15}, 1.8, 1.0, 12)
bezier({64, 35}, {72, 40}, {80, 48}, {92, 50}, 1.6, 1.0, 16)
bezier({16, 55}, {18, 50}, {14, 44}, {8, 40}, 1.5, 0.9, nil)

-- Bark shading from a light above: top edge light, underside dark, ink outline.
for y = 0, H - 1 do
  for x = 0, W - 1 do
    if wood[y * W + x] then
      local up, down = wood[(y - 1) * W + x], wood[(y + 1) * W + x]
      local up2 = wood[(y - 2) * W + x]
      if not up then set(x, y, "bl")
      elseif not down then set(x, y, "bd")
      elseif not up2 then set(x, y, "bm")
      else set(x, y, "bm") end
    end
  end
end
for y = 0, H - 1 do
  for x = 0, W - 1 do
    if not wood[y * W + x] then
      for _, d in ipairs({ {1,0}, {-1,0}, {0,1}, {0,-1} }) do
        if wood[(y + d[2]) * W + (x + d[1])] and x + d[1] >= 0 and x + d[1] < W then set(x, y, "ink") break end
      end
    end
  end
end
-- Sparse highlights on the top of the main limb.
for _, p in ipairs({ {30, 0}, {44, 0}, {62, 0}, {78, 0} }) do
  for y = 0, H - 1 do if get(p[1], y) == "bl" then set(p[1], y, "bh") set(p[1] + 1, y, "bh") break end end
end
-- Thorns: two-pixel hooks off the outer edge, leaning along the limb.
for _, t in ipairs(thornAt) do
  local x, y, nx, ny, tx, ty, r = table.unpack(t)
  local bx, by = x + nx * (r + .6), y + ny * (r + .6)
  set(math.floor(bx), math.floor(by), "bd")
  set(math.floor(bx + nx + tx * .8), math.floor(by + ny + ty * .8), "ink")
end

-- Leaves (pointing up). Chars: d/m/l leaf tones, v vein, s stem. Variants flip and rotate.
local LEAF = {
  ".....l.....",
  "..l..ml..l.",
  "..dl.mll.l.",
  "...dmmlll..",
  ".l.dmvmll.l",
  ".ddmmvmmll.",
  "..ddmvmml..",
  "...ddvml...",
  "....dvm....",
  ".....s.....",
  ".....s.....",
}
local TONE = { d = "ld", m = "lm", l = "ll", v = "ld", s = "bm" }
local function leaf(ox, oy, mode)
  local h, w = #LEAF, #LEAF[1]
  for r = 1, h do
    for c = 1, w do
      local ch = LEAF[r]:sub(c, c)
      if ch ~= "." then
        local x, y = c - 1, r - 1
        if mode == "flip" then x = w - c
        elseif mode == "right" then x, y = h - r, c - 1
        elseif mode == "left" then x, y = r - 1, w - c
        elseif mode == "down" then x, y = w - c, h - r end
        set(ox + x, oy + y, TONE[ch])
      end
    end
  end
end
leaf(55, 2, "up")
leaf(42, 12, "flip")
leaf(1, 30, "up")
leaf(18, 42, "left")
leaf(71, 13, "up")
leaf(91, 44, "right")
leaf(113, 29, "right")
leaf(45, 43, "down")

-- Berry clusters: 4x4 berries, highlight top-left, dark underside, ink rim.
local BERRY = { ".mm.", "mhmm", "mmmd", ".dd." }
local BT = { m = "rm", h = "rh", d = "rd" }
local function berry(ox, oy)
  for r = 1, 4 do
    for c = 1, 4 do
      local ch = BERRY[r]:sub(c, c)
      if ch == "." then
        if get(ox + c - 1, oy + r - 1) == nil then set(ox + c - 1, oy + r - 1, "ink") end
      else set(ox + c - 1, oy + r - 1, BT[ch]) end
    end
  end
end
-- Short stems tie the clusters to the wood.
for _, s in ipairs({ {87, 48}, {86, 47}, {36, 37}, {37, 38}, {106, 44}, {106, 45} }) do set(s[1], s[2], "bd") end
for _, b in ipairs({ {84, 49}, {88, 52}, {83, 54}, {93, 53},
                     {32, 37}, {28, 40}, {33, 41},
                     {104, 46}, {108, 48}, {103, 50} }) do berry(b[1], b[2]) end

-- Write the sprite and the PNG.
local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "branch"
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
return spr
