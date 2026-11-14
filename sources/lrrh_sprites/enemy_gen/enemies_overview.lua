-- Builds enemies_overview.png: every enemy sheet at 3x, 2 columns, transparent,
-- same layout as roster_overview.png (12 px margin, 24 px gap). Order follows the concept sheet.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local DIR = HERE .. "/.."
local ORDER = {
  "big_bad_wolf", "rogue_hunter",
  "forest_witch", "wild_boar",
  "forest_crow", "living_tree",
  "thorn_brambles", "lost_wisp",
  "brown_bear", "forest_stag",
  "spore_mushroom", "ghost_hunter",
  "raven", "will_o_wisp",
}
local S, M, G = 3, 12, 24
local CW, CH = 256 * S, 192 * S
local ROWS = (#ORDER + 1) // 2
local out = Image(M * 2 + CW * 2 + G, M * 2 + CH * ROWS + G * (ROWS - 1), ColorMode.RGB)
for k, name in ipairs(ORDER) do
  local col, row = (k - 1) % 2, (k - 1) // 2
  local ox, oy = M + col * (CW + G), M + row * (CH + G)
  local sheet = Image { fromFile = DIR .. "/" .. name .. "_sheet.png" }
  for y = 0, sheet.height - 1 do
    for x = 0, sheet.width - 1 do
      local c = sheet:getPixel(x, y)
      if app.pixelColor.rgbaA(c) > 0 then
        for dy = 0, S - 1 do
          for dx = 0, S - 1 do out:drawPixel(ox + x * S + dx, oy + y * S + dy, c) end
        end
      end
    end
  end
end
out:saveAs(DIR .. "/enemies_overview.png")
return out
