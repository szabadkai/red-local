-- little_red_run.lua: rebuilds Little Red's `run` tag (frames 5-8) as a real run cycle.
-- The hood, head, torso and basket are taken unchanged from the old run frame 5
-- (_backup_red_run_v1/little_red_riding_hood.aseprite) and bob 1 px. The cape, the legs and a dust
-- puff are redrawn as new shapes in every frame. The cape trails the body by one frame.
-- (A squash-and-stretch version with long striding legs was rejected: "on high legs ... just bumping".)
--   contact A (low) -> passing (high) -> contact B (low) -> passing (high)
-- Run it from the aseprite MCP: _G.RED_OUT = <path to write>; spr = dofile(<this file>)
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local D = HERE .. "/.."
local SRC = D .. "/_backup_red_run_v1/little_red_riding_hood.aseprite"
local OUT = rawget(_G, "RED_OUT") or (D .. "/little_red_riding_hood.aseprite")
local pc = app.pixelColor

local function hex(h) return pc.rgba(tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16), 255) end
-- the sprite's own colours
local K = {
  a = "#7d5362", b = "#b62e41", c = "#a5534e", d = "#88293a", f = "#714244", g = "#4b2228",
  j = "#5d2f33", k = "#8f4443",                                   -- cape reds
  n = "#3d3439", p = "#463a43", x = "#55484b", C = "#605157", G = "#4c3f45", m = "#3b2d35", -- legs
  i = "#1f191e", h = "#272025", w = "#170d10", o = "#2d262c",     -- boots
  D = "#cdb4b1", E = "#b1969d", A = "#907b7f",                    -- dust (the apron's greys)
}
local COL = {}
for ch, hx in pairs(K) do COL[ch] = hex(hx) end

-- old frame 5 = the upper body source
local src = app.open(SRC)
local base = Image(src.spec); base:drawSprite(src, 5)
local tmpl = Sprite(src)   -- copy of the whole sprite; frames 5-8 get replaced
src:close()

-- body block: frame 5 minus the cape (left of the torso) and the legs (rows >= 27)
local function isBody(x, y)
  if y >= 27 then return false end
  if y >= 19 and y <= 24 and x <= 12 then return false end
  if y >= 25 and x <= 7 then return false end
  return true
end

-- cape: per-column top and bottom rows (x = 0..13); shading is filled from the shape
local function cape(img, top, bot)
  for x = 0, 13 do
    local t, b = top[x + 1], bot[x + 1]
    if t and t >= 0 then
      local tipN = 0  -- distance from the tip
      for xx = x, 0, -1 do if top[xx + 1] and top[xx + 1] >= 0 then tipN = tipN + 1 end end
      local prevTop = top[x + 2] or t                         -- column nearer the shoulder
      for y = t, b do
        local ch
        local h = b - t
        if y == t then ch = (tipN <= 2) and "a" or "c"
        elseif y == b then ch = (tipN <= 1) and "f" or "j"
        elseif (y - t) >= h * 0.6 then ch = "d"
        else ch = "b" end
        -- a fold: where the top edge dips below its shoulder-side neighbour, shade the crease
        if y > t and y <= t + 1 and t > prevTop then ch = "d" end
        img:drawPixel(x, y, COL[ch])
      end
    end
  end
end

local function grid(img, rows, y0)
  for r, s in ipairs(rows) do
    for x = 1, #s do
      local ch = s:sub(x, x)
      if COL[ch] then img:drawPixel(x - 1, y0 + r - 1, COL[ch]) end
    end
  end
end

-- per-frame poses, matching the roster's other runs (mother, woodcutter, rogue_hunter): short legs,
-- a 1 px bob, and feet that visibly cycle  split -> passing -> split -> passing.
--   contact A: near leg forward, far leg behind      (body low)
--   passing A: near leg planted under the body, far foot tucked up behind as it swings through
--   contact B: far leg forward, near leg behind      (body low)
--   passing B: far leg planted, near foot tucked up behind
-- dy moves the body (old frame 5 had its feet on row 30; ground is row 31). hd/lean are kept at 0.
local N = nil
local PUFF = { ".DD..", "DDDE.", ".EEA." }   -- dust where the back foot pushed off
local DRIFT = { ".E", "EA" }                   -- the previous puff, drifting up and fading
local P = {
  { -- contact A
    dy = 1, hd = 0, lean = 0, ms = 100,
    top = { N, 17, 17, 18, 18, 19, 19, 19, 20, 20, 20, 20, 20, 20 },
    bot = { N, 19, 20, 21, 22, 22, 23, 23, 24, 24, 24, 25, 25, 25 },
    legsY = 28,
    legs = {
      "........GnnppppGnnmG",
      ".......hnn.......pxp",
      "......wiih........piih",
      "......wih.........hiiio",
    },
    puff = { DRIFT, 0, 27 } },
  { -- passing A
    dy = 0, hd = 0, lean = 0, ms = 100,
    top = { 21, 21, 20, 20, 20, 20, 20, 19, 19, 19, 19, 19, 19, 19 },
    bot = { 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24 },
    legsY = 27,
    legs = {
      "........CnnppppGnnmG",
      ".......hiin...pxp",
      "........wih...pxp",
      "..............hiii",
      "..............wiiio",
    },
    puff = { PUFF, 0, 29 } },
  { -- contact B
    dy = 1, hd = 0, lean = 0, ms = 100,
    top = { N, N, 18, 17, 18, 19, 19, 19, 19, 20, 20, 20, 20, 20 },
    bot = { N, N, 20, 21, 22, 22, 22, 23, 23, 24, 24, 24, 25, 25 },
    legsY = 28,
    legs = {
      "........CnnppppGnnmG",
      ".......pxp.......nnn",
      "......wiip........niih",
      "......wih.........hiiio",
    },
    puff = { DRIFT, 0, 27 } },
  { -- passing B
    dy = 0, hd = 0, lean = 0, ms = 100,
    top = { 20, 19, 19, 19, 20, 20, 20, 20, 19, 19, 19, 19, 19, 19 },
    bot = { 22, 22, 23, 23, 24, 24, 24, 24, 24, 23, 23, 24, 24, 24 },
    legsY = 27,
    legs = {
      "........CnnppppGnnmG",
      ".......iiip...nnn",
      "........wip...nnn",
      "..............hiii",
      "..............wiiio",
    },
    puff = { PUFF, 0, 29 } },
}

local function isHand(x, y) return x >= 21 and y >= 20 and y <= 23 end

for k, p in ipairs(P) do
  local img = Image(32, 32, ColorMode.RGB)
  cape(img, p.top, p.bot)
  grid(img, p.legs, p.legsY)
  if p.puff then
    local g, px0, py0 = p.puff[1], p.puff[2], p.puff[3]
    for r, s in ipairs(g) do for x = 1, #s do
      local ch = s:sub(x, x)
      if COL[ch] then img:drawPixel(px0 + x - 1, py0 + r - 1, COL[ch]) end
    end end
  end
  local function put(x, y, c) if x >= 0 and x < 32 and y >= 0 and y < 32 then img:drawPixel(x, y, c) end end
  -- lower body (rows >= 21) and the free hand, which pumps: forward on contact, up while passing
  for y = 0, 31 do for x = 0, 31 do
    local c = base:getPixel(x, y)
    if pc.rgbaA(c) > 0 and isBody(x, y) and (y >= 21 or isHand(x, y)) then
      local Y = y + p.dy
      local X = x
      if isHand(x, y) then
        if p.dy <= 0 then Y = Y - 1 else X = X + 1; put(x, Y, c) end   -- reaches forward on contact (arm 1 px longer)
      end
      put(X, Y, c)
    end
  end end
  -- stretch: fill the row the head left behind with the bodice row
  if p.hd < 0 then
    for x = 13, 20 do
      local c = base:getPixel(x, 21)
      if pc.rgbaA(c) > 0 then put(x, 20 + p.dy, c) end
    end
  end
  -- head, hood and collar (rows <= 20), leaning forward
  for y = 0, 20 do for x = 0, 31 do
    local c = base:getPixel(x, y)
    if pc.rgbaA(c) > 0 and isBody(x, y) and not isHand(x, y) then put(x + p.lean, y + p.dy + p.hd, c) end
  end end
  local f = 4 + k
  local cel = tmpl.layers[1]:cel(f)
  if cel then cel.image = img; cel.position = Point(0, 0) else tmpl:newCel(tmpl.layers[1], f, img, Point(0, 0)) end
  tmpl.frames[f].duration = p.ms / 1000
end
tmpl:saveAs(OUT)
return tmpl
