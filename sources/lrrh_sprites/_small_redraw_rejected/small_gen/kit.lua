-- Kit for the red-local-scale roster.
-- The game's Red (small_gen/ref/red_idle.png) is 15x18 art pixels, drawn at 2x in the game.
-- Every roster character here is drawn at that scale and in that style:
--   * no dark outline: shapes read through flat, saturated colour blocks
--   * 2 tones per material (base + one shade), rarely a 3rd
--   * big heads (about half the figure), eyes = 1x2 black pixels, a blush pixel
--   * one light from the upper right, so shade sits on the back/left and bottom
-- Frame format is unchanged from the old roster so engines keep working:
--   32x32 cells, one "sprite" layer, 34 frames tagged
--   idle(4) run(4) attack(6) special(8) hit(4) death(8), facing right, feet on y = 31.
--
-- Usage from a character script:
--   local K = dofile(HERE .. "/kit.lua")
--   local head = K.art({ "..RR..", ... }, { R = "#fd3150", ... })
--   K.put(c, head, x, y)            -- top-left at (x, y)
--   K.foot(c, legs, x)              -- bottom row on the ground (y = 31)
--   return K.build("name", draw)    -- draw(tag, i, n) -> canvas, i 0-based
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")   -- frozen copy of enemy_gen/lib.lua (canvas, fx, export)
local K = setmetatable({}, { __index = L })
local W, H = L.W, L.H
K.HERE, K.DIR, K.GROUND = HERE, HERE .. "/..", H - 1

-- Red's own colours, for reference and for anything that should sit in her world
K.RED = {
  red = "#fd3150", red_dk = "#94031a",
  hair = "#fffff2", hair_dk = "#b2af9a",
  skin = "#ffeec8", blush = "#ff9f89",
  black = "#000000", pom = "#fffdae",
}
K.EYE = L.rgb("#000000")

------------------------------------------------------------------ ASCII art
-- rows: equal-length strings; map: char -> "#rrggbb" (or colour int).
-- Any char missing from map ('.', ' ') is transparent.
function K.art(rows, map)
  local a = { w = 0, h = #rows, px = {} }
  local cmap = {}
  for k, v in pairs(map) do cmap[k] = L.rgb(v) end
  for j, row in ipairs(rows) do
    a.w = math.max(a.w, #row)
    for i = 1, #row do
      local ch = row:sub(i, i)
      local col = cmap[ch]
      if col then a.px[#a.px + 1] = { i - 1, j - 1, col, ch } end
    end
  end
  return a
end
-- mirror left-right
function K.flip(a)
  local o = { w = a.w, h = a.h, px = {} }
  for k, p in ipairs(a.px) do o.px[k] = { a.w - 1 - p[1], p[2], p[3], p[4] } end
  return o
end
-- quarter turns clockwise (q = 1, 2, 3; negative = counter-clockwise)
function K.rot(a, q)
  q = q % 4
  local o = a
  for _ = 1, q do
    local n = { w = o.h, h = o.w, px = {} }
    for k, p in ipairs(o.px) do n.px[k] = { o.h - 1 - p[2], p[1], p[3], p[4] } end
    o = n
  end
  return o
end
-- copy with chars swapped: swap = { e = "s" } re-maps by source char using `map`,
-- or swap = { e = "#hex" } sets a colour; swap[ch] = false drops the pixel.
function K.swap(a, swap, map)
  local o = { w = a.w, h = a.h, px = {} }
  for _, p in ipairs(a.px) do
    local s = swap[p[4]]
    if s == nil then o.px[#o.px + 1] = p
    elseif s ~= false then
      local col = (map and map[s] and L.rgb(map[s])) or L.rgb(s)
      o.px[#o.px + 1] = { p[1], p[2], col, p[4] }
    end
  end
  return o
end
-- draw art with its top-left at (x, y). opts.col = force one colour (hit flash)
function K.put(c, a, x, y, opts)
  local force = opts and opts.col and L.rgb(opts.col)
  for _, p in ipairs(a.px) do c:set(x + p[1], y + p[2], force or p[3]) end
  return c
end
-- draw art with its bottom row on the ground line (or on `bottom`)
function K.foot(c, a, x, bottom, opts)
  return K.put(c, a, x, (bottom or K.GROUND) - a.h + 1, opts)
end

------------------------------------------------------------------ whole-figure ops
-- turn the whole figure a quarter turn and set it on the ground, centred on cx.
-- dir = -1: fell backwards (head to the left, face up); dir = 1: fell forwards (head right).
function K.lay(c, dir, cx, dy)
  local x0, y0, x1, y1 = L.bounds(c)
  if x0 > x1 then return c end
  local fw, fh = y1 - y0 + 1, x1 - x0 + 1     -- new width / height
  local nx0 = L.round((cx or (x0 + x1) / 2) - fw / 2)
  local ny0 = K.GROUND - fh + 1 + (dy or 0)
  local o = L.canvas()
  for k, v in pairs(c.p) do
    local x, y = k % W, k // W
    if dir < 0 then o:set(nx0 + (y - y0), ny0 + (x1 - x), v)
    else o:set(nx0 + (y1 - y), ny0 + (x - x0), v) end
  end
  return o
end
-- the white hit-flash silhouette used on hit frame 0
function K.flashOf(c) return c:copy():flash() end

------------------------------------------------------------------ small fx (scaled for ~18 px figures)
local BANG = { "#.#", "#.#", "...", "#.#" }
-- "!!" surprise/impact marks, top-left at (x, y)
function K.bang(c, x, y, col)
  col = col or L.MARK
  for j, row in ipairs(BANG) do
    for i = 1, #row do if row:sub(i, i) == "#" then c:set(x + i - 1, y + j - 1, col) end end
  end
end
-- dizzy swirl above a knocked-out character (same icon as the old roster)
K.dizzy = L.dizzy
-- 1-2 px dust kick at the feet
function K.dust(c, x, y, k, col)
  col = col or L.MARK2
  c:set(x, y, col)
  if k % 2 == 0 then c:set(x - 1, y - 1, col) else c:set(x - 2, y, col) end
end
-- short horizontal motion lines behind a dash, right end at x
function K.speed(c, x, y, n, len, col, seed)
  L.streaks(c, x, y, n, len, col or L.MARK, seed)
end

------------------------------------------------------------------ build
-- writes <DIR>/<name>.aseprite, _sheet.png/.json, _preview_x4.gif (same as the old roster),
-- plus a big review PNG when _G.REVIEW is set to a path
function K.build(name, draw)
  return L.build(name, K.DIR, draw, rawget(_G, "REVIEW"))
end

------------------------------------------------------------------ size check
-- one PNG: the game's Red, then each named roster character's idle frame 0, feet aligned,
-- a dashed line at Red's head height, scaled by s
function K.lineup(names, out, s)
  s = s or 4
  local pc = app.pixelColor
  local red = Image { fromFile = HERE .. "/ref/red_idle.png" }
  local GAP, PAD = 3, 4
  local Wd = PAD + red.width + 6 + #names * (32 + GAP) + PAD
  local img = Image(Wd, 34, ColorMode.RGB)
  img:clear(pc.rgba(36, 40, 52, 255))
  for x = 0, Wd - 1 do img:drawPixel(x, 32, pc.rgba(110, 116, 130, 255)) end
  for x = 0, Wd - 1 do if x % 4 < 2 then img:drawPixel(x, 32 - red.height - 1, pc.rgba(253, 49, 80, 255)) end end
  img:drawImage(red, Point(PAD, 32 - red.height))
  local x = PAD + red.width + 6
  for _, n in ipairs(names) do
    local sheet = Image { fromFile = K.DIR .. "/" .. n .. "_sheet.png" }
    local cell = Image(32, 32, ColorMode.RGB)
    cell:drawImage(sheet, Point(0, 0))
    img:drawImage(cell, Point(x, 0))
    x = x + 32 + GAP
  end
  local spr = Sprite(Wd, 34, ColorMode.RGB)
  spr.cels[1].image = img
  spr:resize(Wd * s, 34 * s)
  spr:saveCopyAs(out)
  spr:close()
end

return K
