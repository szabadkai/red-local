-- forest_witch_small: the original forest_witch shortened by deleting repeated rows (see shrink.lua).
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local S = dofile(HERE .. "/shrink.lua")
local lying = {}
for f = 30, 34 do lying[f] = true end
local at = {}
return S.make("forest_witch", { hair = 1, hairBand = 4, body = 4, head = 12, feet = 2, lying = lying, at = at }, rawget(_G, "REVIEW"))
