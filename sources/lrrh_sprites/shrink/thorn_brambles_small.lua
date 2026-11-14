-- thorn_brambles_small: the original brambles (19 x 31 px) made about 20% smaller by deleting
-- repeated rows and columns on both sides of the red core (see shrink.lua).
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local S = dofile(HERE .. "/shrink.lua")
local at = {}
return S.make("thorn_brambles", { hair = 1, hairBand = 4, body = 3, head = 6, feet = 1,
  colBands = { { 0.05, 0.38, 3 }, { 0.62, 0.95, 3 } }, colShift = 3, at = at }, rawget(_G, "REVIEW"))
