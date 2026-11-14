-- mother_small: the original mother (26 px) made 21 px tall by deleting repeated rows.
-- Writes mother_small.aseprite / _sheet.png / _sheet.json / _preview_x4.gif; mother.* is untouched.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local S = dofile(HERE .. "/shrink.lua")

-- standing / idle / run: one hair row 3 below the head top, and bodice + apron rows
-- at fixed distances above the feet, so the cuts ride along with the bob
local function stand(bb) return { rows = { bb.y0 + 3, bb.y1 - 12, bb.y1 - 10, bb.y1 - 6, bb.y1 - 4 } } end
local LEAN = { rows = { 12, 21, 23, 25, 27 } }   -- attack: leaning in, pointing (arm on rows 17-19; row 12 misses the "!" mark)
local SHIELD = { rows = { 12, 22, 25, 27 } }     -- special: crouched behind the shield
local HURT = { rows = { 10, 21, 23, 27 } }       -- hit / first fall frame
local DOWN = { cols = { 2, 4, 6, 9 } }           -- lying, head on the right: shorten the body

local per = {}
for f = 1, 34 do per[f] = stand end
for f = 10, 13 do per[f] = LEAN end
for f = 15, 22 do per[f] = SHIELD end
for _, f in ipairs({ 23, 24, 25, 27 }) do per[f] = HURT end
per[28] = { rows = { 12, 23, 25, 29 } }          -- sinking: same cuts, 2 px lower
per[29] = { rows = { 15, 26, 28, 30 } }          -- kneeling: 5 px lower
for f = 30, 34 do per[f] = DOWN end

local D = HERE .. "/.."
local spr, log = S.run { src = D .. "/mother.aseprite", name = "mother_small", per = per }
S.compare(D .. "/mother_sheet.png", D .. "/mother_small_sheet.png", rawget(_G, "REVIEW") or (HERE .. "/mother_compare.png"), 4)
return spr, log
