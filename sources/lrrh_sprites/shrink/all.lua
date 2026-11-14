-- Rebuilds every <name>_small.* from its config (characters in ORIGINAL stay as drawn), then the review images:
--   lrrh_sprites/small_overview.png        every small sheet at 3x, 2 columns, transparent
--   lrrh_sprites/small_size_lineup_x4.png  the game's Red, then each small character's idle frame
-- Run from the aseprite MCP: dofile(".../shrink/all.lua")
-- _G.OVERVIEW_ONLY = true skips the shrinking and only redraws the two review images.
-- Note: forest_crow_small and thorn_brambles_small were relit in place (enemy_gen/relight_roster.lua);
-- a full re-run re-shrinks them from the relit originals, so their rim pixels may move slightly.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local D = HERE .. "/.."
local NAMES = {
  "little_red_riding_hood", "grandmother", "mother", "woodcutter", "rogue_hunter", "forest_witch",
  "wolf_in_disguise", "big_bad_wolf", "wild_boar", "forest_crow", "living_tree", "thorn_brambles", "lost_wisp",
}
-- kept at their original size (the overview and lineup show the original sheet)
local ORIGINAL = { wild_boar = true, big_bad_wolf = true }   -- the beasts keep their full size next to Red
local function sheetOf(n) return D .. "/" .. n .. (ORIGINAL[n] and "" or "_small") .. "_sheet.png" end
local report = {}
for _, n in ipairs(NAMES) do if not ORIGINAL[n] and not rawget(_G, "OVERVIEW_ONLY") then
  local spr, log = dofile(HERE .. "/" .. n .. "_small.lua")
  local orphans = 0
  for _, l in ipairs(log) do orphans = orphans + tonumber(l:match("orphans (%d+)") or 0) end
  report[#report + 1] = string.format("%-24s orphan px removed: %d", n, orphans)
end end

-- overview: small sheets at 3x, 2 columns
local S3, M, G = 3, 12, 24
local CW, CH = 256 * S3, 192 * S3
local rows = (#NAMES + 1) // 2
local out = Image(M * 2 + CW * 2 + G, M * 2 + CH * rows + G * (rows - 1), ColorMode.RGB)
for k, name in ipairs(NAMES) do
  local col, row = (k - 1) % 2, (k - 1) // 2
  local ox, oy = M + col * (CW + G), M + row * (CH + G)
  local sheet = Image { fromFile = sheetOf(name) }
  for y = 0, sheet.height - 1 do
    for x = 0, sheet.width - 1 do
      local c = sheet:getPixel(x, y)
      if app.pixelColor.rgbaA(c) > 0 then
        for dy = 0, S3 - 1 do for dx = 0, S3 - 1 do out:drawPixel(ox + x * S3 + dx, oy + y * S3 + dy, c) end end
      end
    end
  end
end
out:saveAs(D .. "/small_overview.png")

-- size lineup: the game's Red first, then every small character's idle frame 0
local pc = app.pixelColor
local red = Image { fromFile = D .. "/_small_redraw_rejected/small_gen/ref/red_idle.png" }
local GAP, PAD = 3, 4
local Wd = PAD + red.width + 6 + #NAMES * (32 + GAP) + PAD
local img = Image(Wd, 34, ColorMode.RGB)
img:clear(pc.rgba(36, 40, 52, 255))
for x = 0, Wd - 1 do img:drawPixel(x, 32, pc.rgba(110, 116, 130, 255)) end
for x = 0, Wd - 1 do if x % 4 < 2 then img:drawPixel(x, 32 - red.height - 1, pc.rgba(253, 49, 80, 255)) end end
img:drawImage(red, Point(PAD, 32 - red.height))
local x = PAD + red.width + 6
for _, n in ipairs(NAMES) do
  local sheet = Image { fromFile = sheetOf(n) }
  local cell = Image(32, 32, ColorMode.RGB)
  cell:drawImage(sheet, Point(0, 0))
  img:drawImage(cell, Point(x, 0))
  x = x + 32 + GAP
end
local spr = Sprite(Wd, 34, ColorMode.RGB)
spr.cels[1].image = img
spr:resize(Wd * 4, 34 * 4)
spr:saveCopyAs(D .. "/small_size_lineup_x4.png")
spr:close()
return report
