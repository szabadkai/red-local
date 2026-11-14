-- living_tree_small: the original living tree (30 x 26 px) made about 20% smaller by deleting
-- repeated rows (canopy and trunk) and columns (see shrink.lua).
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local S = dofile(HERE .. "/shrink.lua")
local lying = {}
for f = 30, 34 do lying[f] = true end
local at = {}
for f = 24, 26 do at[f] = { guard = { { 22, 0, 31, 11 } } } end   -- the "!!" marks
-- lying: the same columns in all five frames (picked clear of the dizzy swirl)
local per = {}
for f = 30, 34 do per[f] = { rows = {}, cols = { 2, 4, 8, 10, 21, 24 } } end
return S.make("living_tree", { hair = 2, hairBand = 7, body = 4, head = 14, feet = 2,
  colBands = { { 0.02, 0.3, 2 }, { 0.72, 0.98, 2 } }, colShift = 2, lying = lying, lyingBand = { 0.04, 0.85 }, at = at, per = per }, rawget(_G, "REVIEW"))
