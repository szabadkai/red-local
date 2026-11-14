-- wolf_in_disguise_small: the original wolf_in_disguise shortened by deleting repeated rows (see shrink.lua).
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local S = dofile(HERE .. "/shrink.lua")
local lying = {}
for f = 30, 34 do lying[f] = true end
local at = {}
-- unmasked lunge: keep the open jaws whole, take the rows from the shawl and legs
local function jaws(bb) return { { bb.x0 + 15, bb.y0, bb.x1, bb.y0 + 11 } } end
for f = 15, 22 do at[f] = { guard = { jaws } } end
for f = 10, 13 do at[f] = { guard = { { 14, 10, 31, 21 } } } end   -- bite
return S.make("wolf_in_disguise", { hair = 1, hairBand = 4, body = 4, head = 11, feet = 2, lying = lying, at = at }, rawget(_G, "REVIEW"))
