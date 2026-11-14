-- NOT USED: the wolf stays at its original size (see ORIGINAL in all.lua). Kept in case that changes.
-- big_bad_wolf_small: the original wolf (23 x 27 px) made about 20% smaller in both
-- directions by deleting repeated rows and columns (see shrink.lua).
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local S = dofile(HERE .. "/shrink.lua")
local lying = {}
for f = 30, 34 do lying[f] = true end
local at = {}
-- bite: the head fills the whole pose height, so rows by hand: an ear tip, one row of the
-- open mouth, one of the lower jaw and one of the legs; body columns still picked automatically
for f = 10, 13 do at[f] = { fixedRows = { 14, 22, 26, 30 } } end
return S.make("big_bad_wolf", { hair = 1, hairBand = 3, body = 4, head = 9, feet = 2,
  cols = 4, colShift = 2, colBand = { 0.12, 0.6 }, lying = lying, lyingExtra = 0, at = at }, rawget(_G, "REVIEW"))
