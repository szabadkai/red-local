-- grandmother_small: original grandmother (23 px) shortened to 18 px by deleting repeated rows
-- (see shrink.lua). In the lantern special, glow-only columns right of the lantern are also cut
-- (then shifted back) so the glow stays round after the row cuts.
-- Since the 2026-11-10 animation fix (enemy_gen/grandmother.lua) the glow grows and fades, so the
-- special's cuts are explicit per frame: no column cuts while the glow is small (they would slice
-- the lantern), 2 columns for the medium glow, 4 for the full one; the last frame is the idle pose.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local S = dofile(HERE .. "/shrink.lua")
local lying = {}
for f = 30, 34 do lying[f] = true end
local at = {}
for f = 10, 13 do at[f] = { guard = { { 19, 0, 31, 14 } } } end   -- keep the "!!" mark whole
local ROWS = { 12, 23, 27, 29 }   -- one hair row, one lantern-glass row, two rows behind the glow
local per = {
  [15] = { rows = ROWS, cols = {} },                                  -- unlit
  [16] = { rows = ROWS, cols = {} },                                  -- glow r 6
  [17] = { rows = ROWS, cols = { 22, 24 }, shift = 2 },               -- r 9
  [18] = { rows = ROWS, cols = { 21, 23, 25, 27 }, shift = 4 },       -- r 11
  [19] = { rows = ROWS, cols = { 21, 23, 25, 27 }, shift = 4 },       -- r 12
  [20] = { rows = ROWS, cols = { 21, 23, 25, 27 }, shift = 4 },       -- r 11
  [21] = { rows = ROWS, cols = { 22, 24 }, shift = 2 },               -- r 8
  [22] = { rows = { 10, 21, 23, 26, 28 }, cols = {} },                -- standing: same cuts as idle 1
}
return S.make("grandmother", { hair = 1, hairBand = 4, body = 4, head = 11, feet = 2,
  lying = lying, at = at, per = per }, rawget(_G, "REVIEW"))
