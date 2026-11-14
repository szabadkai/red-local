-- woodcutter_small: original woodcutter (27 px) shortened to 22 px by deleting repeated rows
-- (see shrink.lua). The axe is protected so its head keeps its shape.
-- Frame map after the 2026-11-10 animation fix (enemy_gen/woodcutter.lua):
--   axe resting at his front: 1-4 idle, 14 attack recovery, 22 special end, 26 hit recovery
--   blade bitten into the ground: 11-13 attack chop, 21 special finishing chop
--   axe raised overhead: 9 attack lift, 16-20 spin (19/17 mirrored), and 10 / 15 the same pose sunk 1 px
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local S = dofile(HERE .. "/shrink.lua")
local lying = {}
for f = 30, 34 do lying[f] = true end
-- axe resting blade-down at his front
local function axe(bb) return { { bb.x1 - 9, bb.y1 - 12, bb.x1, bb.y1 } } end
local protect = {}
for _, f in ipairs({ 1, 2, 3, 4, 14, 22, 26 }) do protect[f] = axe end
for _, f in ipairs({ 11, 12, 13, 21 }) do protect[f] = { { 17, 23, 28, 31 } } end   -- blade in the ground
-- axe overhead: cut hair, plaid shirt and trousers instead of only the legs
local at = {}
for _, f in ipairs({ 9, 16, 17, 18, 19, 20 }) do at[f] = { fixedRows = { 12, 20, 22, 24, 27 } } end
for _, f in ipairs({ 10, 15 }) do at[f] = { fixedRows = { 13, 21, 23, 25, 28 } } end
-- the chop pose: same rows in every frame (hair, beard, shirt), never the blade in the ground.
-- Left on auto these frames followed their tag's raised-axe reference and cut through the axe head.
for _, f in ipairs({ 11, 12, 13, 21 }) do at[f] = { fixedRows = { 10, 12, 14, 20, 22 } } end
-- standing with the axe at the end of attack / special: same cuts as idle frame 1, so the hand-off is seamless
for _, f in ipairs({ 14, 22 }) do at[f] = { fixedRows = { 8, 15, 17, 19, 24 } } end
return S.make("woodcutter", { hair = 1, hairBand = 4, body = 4, head = 10, feet = 2,
  lying = lying, protect = protect, at = at }, rawget(_G, "REVIEW"))
