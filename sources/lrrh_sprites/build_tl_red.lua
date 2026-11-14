-- Builds a 96-frame "waiting at the gate" performance from Thomas Lean's purchased
-- Platform Character Pack frames (Light variant), adding subtle wind to her own pixels.
local A = (os.getenv("RED_LOCAL") or "../..") .. "/Assets/Light/"
local pc = app.pixelColor
local PADX = 4                       -- room on the left for wind-blown pixels
local W, H = 15 + PADX, 18

local function load(rel)
  local s = app.open(A .. rel)
  local im = Image(W, H, ColorMode.RGB)
  local src = Image(s.width, s.height, ColorMode.RGB); src:drawSprite(s, 1); s:close()
  im:drawImage(src, Point(PADX, 0))
  return im
end
local function eq(c, hex)
  return pc.rgbaA(c) > 0 and string.format("#%02x%02x%02x", pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)) == hex
end
local RED, DARK, HAIR, POM = "#fd3150", "#94031a", "#fffff2", "#fffdae"
local function col(hex) return pc.rgba(tonumber(hex:sub(2,3),16), tonumber(hex:sub(4,5),16), tonumber(hex:sub(6,7),16), 255) end
local CLEAR = pc.rgba(0, 0, 0, 0)
local function inb(x, y) return x >= 0 and y >= 0 and x < W and y < H end
local function get(im, x, y) if inb(x, y) then return im:getPixel(x, y) end return CLEAR end
local function set(im, x, y, c) if inb(x, y) then im:drawPixel(x, y, c) end end

-- wind phases: 0 rest, 1 push, 2 peak, 3 release
local POM_OFF = {[0] = {0, 0}, {-1, 0}, {-2, -1}, {-1, -1}}
local CAPE_ROWS = {[0] = {}, {12, 13}, {13, 14, 15}, {15, 16}}

local function wind(src, phase)
  local im = src:clone()
  -- 1) hood tassel (pom) bobs back in the wind, the hood tail stretches to follow
  local pts, ax, ay = {}, 99, 99
  for y = 0, H - 1 do for x = 0, W - 1 do
    if eq(im:getPixel(x, y), POM) then pts[#pts+1] = {x, y}; if x < ax then ax = x end; if y < ay then ay = y end end
  end end
  if #pts > 0 and phase > 0 then
    local o = POM_OFF[phase]
    for _, p in ipairs(pts) do set(im, p[1], p[2], CLEAR) end
    -- re-attach: tail fill between the old anchor and the new tassel position
    if phase == 1 then set(im, ax, ay, col(DARK)) end
    if phase == 2 then set(im, ax, ay, col(DARK)); set(im, ax - 1, ay, col(DARK)) end
    for _, p in ipairs(pts) do set(im, p[1] + o[1], p[2] + o[2], col(POM)) end
  end
  -- 2) a 1px ripple travels down the cape's back edge
  for _, r in ipairs(CAPE_ROWS[phase]) do
    for x = 0, W - 1 do
      local c = im:getPixel(x, r)
      if pc.rgbaA(c) > 0 then
        if eq(c, RED) or eq(c, DARK) then set(im, x - 1, r, (r >= 15) and col(DARK) or c) end
        break
      end
    end
  end
  -- 3) the long hair strand behind her cheek drifts back at its tip
  local hx = PADX + 6
  if phase > 0 and eq(get(im, hx, 11), HAIR) and eq(get(im, hx - 1, 11), RED) then
    set(im, hx - 1, 11, col(HAIR)); set(im, hx, 11, col(RED))
    if phase == 2 and eq(get(im, hx, 10), HAIR) and eq(get(im, hx - 1, 10), RED) then
      set(im, hx - 1, 10, col(HAIR)); set(im, hx, 10, col(RED))
    end
  end
  return im
end

local idle = load("idle.png")
local blink = {load("idle_blink/idle_blink0.png"), load("idle_blink/idle_blink1.png"), load("idle_blink/idle_blink2.png")}
local intro = {} for i = 0, 6 do intro[#intro+1] = load("look_intro/look_intro" .. i .. ".png") end
local back = {} for i = 0, 4 do back[#back+1] = load("look_back/look_back" .. i .. ".png") end
local lblink = {load("look_blink/look_blink0.png"), load("look_blink/look_blink1.png"), load("look_blink/look_blink2.png")}

local CYCLE = {0, 0, 1, 1, 2, 2, 3, 3}         -- 8-frame gust ripple, 2 frames per pose
local function phaseAt(t) return CYCLE[t % 8 + 1] end

-- 96-frame timeline (80 ms per frame, 7.68 s)
local N = 96
local frames = {}
for t = 0, N - 1 do
  local base
  if t >= 18 and t <= 20 then base = blink[t - 17]
  elseif t >= 40 and t <= 46 then base = intro[t - 39]                 -- turns to look back
  elseif t >= 47 and t <= 70 then
    if t >= 60 and t <= 62 then base = lblink[t - 59]
    else base = back[((t - 47) // 2) % 5 + 1] end
  elseif t >= 71 and t <= 77 then base = intro[7 - (t - 71)]           -- turns back to the forest
  else base = idle end
  frames[t + 1] = wind(base, phaseAt(t))
end

local s = Sprite(W, H, ColorMode.RGB)
for i = 2, N do s:newEmptyFrame() end
for i = 1, N do
  s:newCel(s.layers[1], s.frames[i], frames[i], Point(0, 0))
  s.frames[i].duration = 0.08
end
s.layers[1].name = "red (Thomas Lean pack)"
local tg = s:newTag(1, N); tg.name = "waiting_in_wind"
return s
