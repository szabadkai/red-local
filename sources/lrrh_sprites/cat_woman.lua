-- Loads cat_woman_frames.lua (written by cat_woman.py) into a sprite with an
-- "idle" tag. Run from the aseprite MCP:  spr = dofile(".../cat_woman.lua")
local D = (os.getenv("LRRH_SPRITES") or ".") .. "/"
local data = dofile(D .. "cat_woman_frames.lua")
local pc = app.pixelColor
local cols = {}
for k, v in pairs(data.key) do
  cols[k] = pc.rgba(tonumber(v:sub(2, 3), 16), tonumber(v:sub(4, 5), 16), tonumber(v:sub(6, 7), 16), 255)
end

local s = Sprite(data.w or 32, data.h or 32, ColorMode.RGB)
s.layers[1].name = "sprite"
for i = 2, #data.frames do s:newEmptyFrame() end
for i, rows in ipairs(data.frames) do
  local im = Image(s.width, s.height, ColorMode.RGB)
  for y, row in ipairs(rows) do
    for x = 1, #row do
      local c = cols[row:sub(x, x)]
      if c then im:drawPixel(x - 1, y - 1, c) end
    end
  end
  s:newCel(s.layers[1], s.frames[i], im, Point(0, 0))
  s.frames[i].duration = data.dur[i] / 1000
end
for _, t in ipairs(data.tags or {{"idle", 1, #data.frames}}) do
  local tag = s:newTag(t[2], t[3])
  tag.name = t[1]
end
return s
