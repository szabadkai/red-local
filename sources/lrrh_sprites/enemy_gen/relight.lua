-- relight.lua: readability pass for dark sprites on dark game backgrounds.
--   lift: dark body colours get brighter by a fixed luma step that tapers to zero
--         toward the mid-tones; hue, saturation and the order of shades are kept,
--         and the outline colours are left alone.
--   rim:  body pixels with sky or outline above and body below catch moonlight
--         (the raven's lavender, so the whole cast shares one light).
-- Usage inside Aseprite:
--   local R = dofile(".../enemy_gen/relight.lua")
--   R.file(path, opts)            relight every frame of a .aseprite and re-export
--   R.image(img, opts) -> img     relight one image (for generators and previews)
-- opts: outline = {"#hex", ...}, lift = 7 (luma), liftTop = 60 (no lift above),
--       rim = "#hex" or nil, rimMax = 36 (only body colours darker than this get rim)
local R = {}
local pc = app.pixelColor

local function hex(h)
  return pc.rgba(tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16), 255)
end
local function luma(p) return (0.2126 * pc.rgbaR(p) + 0.7152 * pc.rgbaG(p) + 0.0722 * pc.rgbaB(p)) / 2.55 end

local function setOf(list)
  local s = {}
  for _, h in ipairs(list or {}) do s[hex(h)] = true end
  return s
end

-- full lift below L24, tapering linearly to 0 at liftTop
local function lifted(p, o)
  local L = luma(p)
  local full, top = o.lift or 7, o.liftTop or 60
  local d = L <= 24 and full or (L >= top and 0 or full * (top - L) / (top - 24))
  if d <= 0 or L <= 0 then return p end
  local k = (L + d) / L
  local function ch(v) return math.min(255, math.floor(v * k + 0.5)) end
  return pc.rgba(ch(pc.rgbaR(p)), ch(pc.rgbaG(p)), ch(pc.rgbaB(p)), pc.rgbaA(p))
end

function R.image(src, o)
  local out = src:clone()
  local W, H = out.width, out.height
  local outline = setOf(o.outline)
  local memo, isBody = {}, {}
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local p = src:getPixel(x, y)
      if pc.rgbaA(p) == 255 and not outline[p] then
        local q = memo[p]
        if not q then q = lifted(p, o); memo[p] = q end
        out:drawPixel(x, y, q)
      end
    end
  end
  if o.rim then
    local rim, max = hex(o.rim), o.rimMax or 36
    local function body(x, y)
      if x < 0 or y < 0 or x >= W or y >= H then return false end
      local p = src:getPixel(x, y)
      if pc.rgbaA(p) < 255 or outline[p] then return false end
      local b = isBody[p]
      if b == nil then b = luma(p) < max; isBody[p] = b end
      return b
    end
    local function open(x, y)
      if y < 0 then return true end
      local p = src:getPixel(x, y)
      return pc.rgbaA(p) == 0 or outline[p]
    end
    for y = 0, H - 1 do
      for x = 0, W - 1 do
        if body(x, y) and open(x, y - 1) and body(x, y + 1) then out:drawPixel(x, y, rim) end
      end
    end
  end
  return out
end

-- same exports as lib.lua's L.build
function R.export(spr, base)
  app.activeSprite = spr
  app.command.ExportSpriteSheet {
    ui = false, askOverwrite = false,
    type = SpriteSheetType.ROWS,
    textureFilename = base .. "_sheet.png",
    dataFilename = base .. "_sheet.json",
    dataFormat = SpriteSheetDataFormat.JSON_ARRAY,
    filenameFormat = "{title} #{tag} {tagframe}.{extension}",
    splitTags = true, listLayers = true, listTags = true, listSlices = true,
    trim = false, trimSprite = false, mergeDuplicates = false, openGenerated = false,
  }
  app.command.SaveFileCopyAs { ui = false, filename = base .. "_preview_x4.gif", scale = 4 }
end

function R.file(path, o)
  local spr = app.open(path)
  for _, layer in ipairs(spr.layers) do
    for _, cel in ipairs(layer.cels) do cel.image = R.image(cel.image, o) end
  end
  spr:saveAs(path)
  R.export(spr, path:gsub("%.aseprite$", ""))
  return spr
end

return R
