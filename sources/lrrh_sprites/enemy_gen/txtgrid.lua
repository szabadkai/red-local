-- Reads a text grid file: "# <char> #rrggbb" key lines, then equal-length rows
-- ('.' = transparent). Returns {key = {char = color}, rows = {...}}.
-- img(grid) -> Image of the grid.
local M = {}
local pc = app.pixelColor

function M.read(path)
  local key, rows = {}, {}
  for line in io.lines(path) do
    local k, hex = line:match("^# (%S) #(%x%x%x%x%x%x)")
    if k then
      key[k] = pc.rgba(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), 255)
    elseif #line > 0 and line:sub(1, 1) ~= "#" then
      rows[#rows + 1] = line
    end
  end
  return { key = key, rows = rows }
end

function M.img(g)
  local w, h = #g.rows[1], #g.rows
  local im = Image(w, h, ColorMode.RGB)
  for y, row in ipairs(g.rows) do
    for x = 1, #row do
      local c = g.key[row:sub(x, x)]
      if c then im:drawPixel(x - 1, y - 1, c) end
    end
  end
  return im
end

-- big(img list, scale, out, bg): images side by side, enlarged, over bg
function M.big(ims, S, out, bg)
  local w, h = ims[1].width, ims[1].height
  local o = Image(#ims * (w + 2) * S, (h + 2) * S, ColorMode.RGB)
  o:clear(bg or pc.rgba(44, 42, 50, 255))
  for i, im in ipairs(ims) do
    for y = 0, h - 1 do for x = 0, w - 1 do
      local c = im:getPixel(x, y)
      if pc.rgbaA(c) > 0 then
        local ox, oy = ((i - 1) * (w + 2) + 1 + x) * S, (1 + y) * S
        for j = 0, S - 1 do for k = 0, S - 1 do o:drawPixel(ox + k, oy + j, c) end end
      end
    end end
  end
  o:saveAs(out)
end

return M
