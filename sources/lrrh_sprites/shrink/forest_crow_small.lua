-- forest_crow_small: the original crow (19 x 22 px with its branch) made about 20% smaller
-- by deleting repeated rows and columns (see shrink.lua).
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local S = dofile(HERE .. "/shrink.lua")
local at = {}
-- perched: keep the head and beak whole; the branch and tail take the cuts
local function head(bb) return { { bb.x1 - 8, bb.y0, bb.x1, bb.y0 + 5 } } end
for _, f in ipairs({ 1, 2, 3, 4, 9, 14, 26 }) do at[f] = { guard = { head }, hair = 0, body = 3, head = 4 } end
return S.make("forest_crow", { hair = 1, hairBand = 3, body = 3, head = 6, feet = 1,
  cols = 4, colShift = 2, colBand = { 0.1, 0.6 }, at = at }, rawget(_G, "REVIEW"))
