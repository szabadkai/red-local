-- Rebuilds roster_overview.png and enemies_overview.png (same layout as the old ones:
-- every sheet at 3x, 2 columns x 4 rows, 12 px margin, 24 px gap, transparent) and
-- size_lineup_x4.png (the game's Red next to every character's idle frame).
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local K = dofile(HERE .. "/kit.lua")
local DIR = K.DIR

local function sheetGrid(order, out)
  local S, M, G = 3, 12, 24
  local CW, CH = 256 * S, 192 * S
  local img = Image(M * 2 + CW * 2 + G, M * 2 + CH * 4 + G * 3, ColorMode.RGB)
  for k, name in ipairs(order) do
    local col, row = (k - 1) % 2, (k - 1) // 2
    local ox, oy = M + col * (CW + G), M + row * (CH + G)
    local sheet = Image { fromFile = DIR .. "/" .. name .. "_sheet.png" }
    for y = 0, sheet.height - 1 do
      for x = 0, sheet.width - 1 do
        local c = sheet:getPixel(x, y)
        if app.pixelColor.rgbaA(c) > 0 then
          for dy = 0, S - 1 do
            for dx = 0, S - 1 do img:drawPixel(ox + x * S + dx, oy + y * S + dy, c) end
          end
        end
      end
    end
  end
  img:saveAs(out)
end

sheetGrid({
  "little_red_riding_hood", "big_bad_wolf",
  "grandmother", "woodcutter",
  "mother", "wolf_in_disguise",
  "forest_crow", "thorn_brambles",
}, DIR .. "/roster_overview.png")
sheetGrid({
  "big_bad_wolf", "rogue_hunter",
  "forest_witch", "wild_boar",
  "forest_crow", "living_tree",
  "thorn_brambles", "lost_wisp",
}, DIR .. "/enemies_overview.png")
K.lineup({
  "little_red_riding_hood", "grandmother", "mother", "woodcutter", "rogue_hunter", "forest_witch",
  "big_bad_wolf", "wolf_in_disguise", "wild_boar", "forest_crow", "lost_wisp", "living_tree", "thorn_brambles",
}, DIR .. "/size_check_vs_red_local_x4.png", 4)
