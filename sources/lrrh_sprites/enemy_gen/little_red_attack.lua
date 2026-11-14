-- little_red_attack.lua: rebuilds Little Red's `attack` tag (frames 9-13) as an overhead
-- basket-swing whack (see little_red_swing.lua). Frame 14, the recovery with the basket
-- back at her belly, is kept. The old attack was a straight thrust with the basket held
-- out at arm's length; it is in _backup_red_attack_v1/.
--   9 wind-up, basket back low  10 raised overhead  11 over the top (smear)
--   12 WHACK (impact hold)      13 follow-through, basket low in front
-- Run from the aseprite MCP: _G.RED_OUT = <path to write>; spr = dofile(<this file>)
-- Then rebuild the small version: dofile(".../shrink/little_red_riding_hood_small.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local D = HERE .. "/.."
local SRC = D .. "/_backup_red_attack_v1/little_red_riding_hood.aseprite"
local OUT = rawget(_G, "RED_OUT") or (D .. "/little_red_riding_hood.aseprite")
local swing = dofile(HERE .. "/little_red_swing.lua")

local src = app.open(SRC)
local function flat(f) local im = Image(32, 32, ColorMode.RGB); im:drawSprite(src, f); return im end
local frames, ms = swing.build(flat(1), flat(10), swing.LARGE)
local spr = Sprite(src)   -- copy of the whole sprite; frames 9-13 get replaced
src:close()

for k, img in ipairs(frames) do
  local f = 8 + k
  local cel = spr.layers[1]:cel(f)
  if cel then cel.image = img; cel.position = Point(0, 0) else spr:newCel(spr.layers[1], f, img, Point(0, 0)) end
  spr.frames[f].duration = ms[k] / 1000
end
spr.frames[14].duration = 0.12
spr:saveAs(OUT)

-- exports in the roster's format
local base = OUT:gsub("%.aseprite$", "")
app.command.ExportSpriteSheet {
  ui = false, askOverwrite = false, type = SpriteSheetType.ROWS,
  textureFilename = base .. "_sheet.png", dataFilename = base .. "_sheet.json",
  dataFormat = SpriteSheetDataFormat.JSON_ARRAY,
  filenameFormat = "{title} #{tag} {tagframe}.{extension}",
  splitTags = true, listLayers = true, listTags = true, listSlices = true,
  trim = false, trimSprite = false, mergeDuplicates = false, openGenerated = false,
}
app.command.SaveFileCopyAs { ui = false, filename = base .. "_preview_x4.gif", scale = 4 }
return spr
