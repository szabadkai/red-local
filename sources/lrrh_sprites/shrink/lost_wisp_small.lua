-- lost_wisp_small: the original wisp shortened by deleting repeated rows of the flame
-- (see shrink.lua); it keeps its float height above its shadow. The eye band is guarded.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local S = dofile(HERE .. "/shrink.lua")
-- eyes sit a little below the middle of the flame
local function eyes(bb)
  local h = bb.y1 - bb.y0
  return { { bb.x0, bb.y0 + math.floor(h * 0.5), bb.x1, bb.y0 + math.ceil(h * 0.75) } }
end
local at = {}
for f = 1, 29 do at[f] = { guard = { eyes } } end
-- the squashed pose right after the burst is only 9 px tall: one row and no columns, so both eyes survive
at[18] = { guard = { eyes }, body = 1, cols = 0 }
-- its two 1 px eyes are the only near-black pixels in the flame: guard them by colour
local pc = app.pixelColor
local function eye(c) return pc.rgbaA(c) > 0 and pc.rgbaR(c) + pc.rgbaG(c) + pc.rgbaB(c) < 120 end
return S.make("lost_wisp", { guardColor = eye, guardWeight = 50, hair = 1, hairBand = 3, body = 2, head = 4, feet = 1,
  cols = 2, colBand = { 0.1, 0.5 }, colShift = 1, at = at }, rawget(_G, "REVIEW"))
