-- Readability pass for the hand-imported enemies (2026-11-09). Relights each original and its
-- _small version in place and re-exports sheet, json and preview. Originals of every file are in
-- ../_backup_before_readability/. Run once; running it again would lift the colours a second time.
-- The raven gets the same treatment inside its generator (raven.lua / raven_poses.lua).
-- Run inside Aseprite:  dofile(".../enemy_gen/relight_roster.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local D = HERE .. "/.."
local R = dofile(HERE .. "/relight.lua")
local OUT = { "#1f191e", "#170d10" }   -- the imported pack's outline colours
local MOON = "#9c98c2"                 -- the raven's rim, so the cast shares one light
local PLAN = {
  { "forest_crow",    { outline = OUT, rim = MOON, rimMax = 26 } },  -- 26: the branch stays unlit
  { "big_bad_wolf",   { outline = OUT, rim = MOON } },
  { "thorn_brambles", { outline = OUT } },                           -- lift only: a rim makes every thorn a spike
}
for _, p in ipairs(PLAN) do
  for _, suffix in ipairs({ "", "_small" }) do
    local path = D .. "/" .. p[1] .. suffix .. ".aseprite"
    if app.fs.isFile(path) then
      R.file(path, p[2]):close()
      print("relit " .. p[1] .. suffix)
    end
  end
end
