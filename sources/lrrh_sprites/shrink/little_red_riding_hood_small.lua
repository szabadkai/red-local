-- little_red_riding_hood_small: original Little Red (23 px) shortened to 18 px, Red's height in
-- the game, by deleting repeated rows (see shrink.lua). The hood loses 2 rows; the basket is protected.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local S = dofile(HERE .. "/shrink.lua")
local lying = {}
for f = 30, 34 do lying[f] = true end
-- basket hangs at the front-bottom of the figure
local function basket(bb) return { { bb.x1 - 6, bb.y1 - 9, bb.x1, bb.y1 - 1 } } end
local protect = {}
for _, f in ipairs({ 1, 2, 3, 4, 9, 14, 15, 16, 17, 18, 19, 20, 21, 22, 26 }) do protect[f] = basket end
for f = 10, 13 do protect[f] = { { 20, 18, 31, 30 } } end   -- basket flying out on the swing
-- run (redrawn by enemy_gen/little_red_run.lua): fixed cuts so every run frame loses the same rows
-- (2 hood, bodice, basket middle, skirt), moved with the 1 px bob; the legs stay whole.
local per = {}
for f = 5, 8 do
  local dy = (f % 2 == 1) and 1 or 0
  per[f] = { rows = { 11 + dy, 14 + dy, 21 + dy, 24 + dy, 26 + dy }, cols = {} }
end
-- attack 9-13 (the basket swing, enemy_gen/little_red_swing.lua): row cuts would slice the
-- basket as it travels round her, so these frames are drawn at small size from the small
-- idle body (frame 1) and the old small lunge body (frame 10 of the thrust attack, kept in
-- _backup_red_attack_v1/) instead of being shrunk.
local swing = dofile(HERE .. "/../enemy_gen/little_red_swing.lua")
local old = app.open(HERE .. "/../_backup_red_attack_v1/little_red_riding_hood_small.aseprite")
local function flat(f) local im = Image(32, 32, ColorMode.RGB); im:drawSprite(old, f); return im end
local small = swing.build(flat(1), flat(10), swing.SMALL)
old:close()
local fixes = {}
for k, img in ipairs(small) do
  fixes[8 + k] = function(out) out:clear(); out:drawImage(img, Point(0, 0)) end
end
return S.make("little_red_riding_hood", { hair = 2, hairBand = 5, body = 3, head = 12, feet = 2,
  lying = lying, protect = protect, per = per, fixes = fixes }, rawget(_G, "REVIEW"))
