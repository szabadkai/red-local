-- rogue_hunter_small: the original rogue_hunter shortened by deleting repeated rows (see shrink.lua).
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local S = dofile(HERE .. "/shrink.lua")
local lying = {}
for f = 30, 34 do lying[f] = true end
local at = {}
for f = 19, 21 do at[f] = { guard = { { 22, 12, 31, 31 } } } end   -- trap snapping shut and its "!"
return S.make("rogue_hunter", { hair = 1, hairBand = 4, body = 4, head = 11, feet = 2, lying = lying, at = at }, rawget(_G, "REVIEW"))
