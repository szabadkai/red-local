-- Faithful shrink: makes a roster sprite smaller by deleting whole pixel rows (and, for
-- long animals, columns) where the art repeats itself. No resampling, so outlines,
-- shading and faces stay exactly as drawn. Feet stay on y = 31.
--
--   local S = dofile(".../shrink/shrink.lua")
--   S.run{ src = ".../<name>.aseprite", name = "<name>_small",
--          hair = 1,      -- rows cut near the top of the figure (hair, hood, ears, canopy)
--          hairBand = 4,  -- ...within this many rows below the top
--          body = 4,      -- rows cut between the protected head and the feet
--          head = 12,     -- rows from the figure top protected from body cuts
--          feet = 2,      -- rows at the bottom protected (shoes, paws)
--          cols = 0,      -- columns cut from the body (long animals)
--          colBand = {0.15, 0.55},  -- ...within this fraction of the figure width, from its left (tail) end
--          lying = { [f] = true },  -- frames lying flat: cut (hair + body) columns instead of rows
--          per = { [f] = spec },    -- explicit cuts: { rows = {...}, cols = {...}, shift = n } or fn(bb) -> spec
--          fixes = { [f] = fn(img) } }
-- The figure is the largest 8-connected blob, so detached "!!", dizzy swirls, sparks and
-- projectiles don't move the head/feet bands. Cuts in each frame prefer the rows the first
-- frame of its tag used (measured from the feet / from the top), so animations don't jitter.
local S = {}
local pc = app.pixelColor
local W, H = 32, 32

local function flat(spr, f)
  local im = Image(W, H, ColorMode.RGB)
  im:drawSprite(spr, f)
  return im
end
local function opaque(im, x, y)
  return x >= 0 and y >= 0 and x < W and y < H and pc.rgbaA(im:getPixel(x, y)) > 0
end
-- bounding box of the largest 8-connected blob
function S.figure(im)
  local seen, best, bestN = {}, nil, 0
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local k = y * W + x
      if not seen[k] and opaque(im, x, y) then
        local stack, n = { k }, 0
        local bb = { x0 = x, y0 = y, x1 = x, y1 = y }
        seen[k] = true
        while #stack > 0 do
          local q = table.remove(stack)
          local qx, qy = q % W, q // W
          n = n + 1
          bb.x0, bb.x1 = math.min(bb.x0, qx), math.max(bb.x1, qx)
          bb.y0, bb.y1 = math.min(bb.y0, qy), math.max(bb.y1, qy)
          for dy = -1, 1 do
            for dx = -1, 1 do
              local nx, ny = qx + dx, qy + dy
              local nk = ny * W + nx
              if (dx ~= 0 or dy ~= 0) and not seen[nk] and opaque(im, nx, ny) then
                seen[nk] = true; stack[#stack + 1] = nk
              end
            end
          end
        end
        if n > bestN then best, bestN = bb, n end
      end
    end
  end
  return best
end
-- pixels that differ between line a and line b (rows, or columns when cols)
local function diff(im, a, b, cols)
  if a < 0 or b < 0 or (cols and (a >= W or b >= W)) or (not cols and (a >= H or b >= H)) then return 0 end
  local n = 0
  local w = S._weight        -- per-frame fn(x, y) -> weight; protected props weigh 10
  local cg = S._colorGuard   -- fn(colour) -> true for protected colours (eyes); weigh 10
  for k = 0, (cols and H or W) - 1 do
    local p, q
    if cols then p, q = im:getPixel(a, k), im:getPixel(b, k)
    else p, q = im:getPixel(k, a), im:getPixel(k, b) end
    if p ~= q then
      local wt = w and (cols and w(a, k) or w(k, a)) or 1
      if cg and (cg(p) or cg(q)) then wt = math.max(wt, S._colorWeight or 10) end
      n = n + wt
    end
  end
  return n
end
-- protect = list of rectangles {x0, y0, x1, y1} (canvas coords); pixels inside weigh 10
local function weightFor(rects)
  if not rects or #rects == 0 then return nil end
  return function(x, y)
    for _, r in ipairs(rects) do
      if x >= r[1] and x <= r[3] and y >= r[2] and y <= r[4] then return 10 end
    end
    return 1
  end
end
local function lineCost(im, r, cols) return math.min(diff(im, r, r + 1, cols), diff(im, r, r - 1, cols)) end
S.lineCost = lineCost
-- choose n lines in [lo, hi] whose removal loses least; never two adjacent lines.
-- prefer: set of lines that get a bonus (stability with the tag's first frame)
local function pick(im, lo, hi, n, cols, prefer)
  local cand = {}
  -- a reference row just above the band (head bobbed down onto it) may still be reused
  if prefer and prefer[lo - 1] then lo = lo - 1 end
  for r = lo, hi do
    local cost = lineCost(im, r, cols)
    if prefer and prefer[r] then cost = cost - 3 end
    cand[#cand + 1] = { r = r, cost = cost }
  end
  table.sort(cand, function(a, b) if a.cost ~= b.cost then return a.cost < b.cost end return a.r > b.r end)
  local chosen, taken = {}, {}
  for _, c in ipairs(cand) do
    if #chosen >= n then break end
    if not taken[c.r - 1] and not taken[c.r + 1] then chosen[#chosen + 1] = c.r; taken[c.r] = true end
  end
  table.sort(chosen)
  return chosen
end
-- rebuild without the cut rows (bottom-anchored) and cut columns (right-anchored)
local function remove(im, rows, cols)
  local cutR, cutC = {}, {}
  for _, r in ipairs(rows or {}) do cutR[r] = true end
  for _, c in ipairs(cols or {}) do cutC[c] = true end
  local out = Image(W, H, ColorMode.RGB)
  local dy = H - 1
  for y = H - 1, 0, -1 do
    if not cutR[y] then
      local dx = W - 1
      for x = W - 1, 0, -1 do
        if not cutC[x] then out:drawPixel(dx, dy, im:getPixel(x, y)); dx = dx - 1 end
      end
      dy = dy - 1
    end
  end
  return out
end
local function shifted(im, sx)
  if not sx or sx == 0 then return im end
  local c = Image(W, H, ColorMode.RGB); c:drawImage(im, Point(-sx, 0)); return c
end

local TAGS = { { "idle", 1, 4 }, { "run", 5, 8 }, { "attack", 9, 14 }, { "special", 15, 22 }, { "hit", 23, 26 }, { "death", 27, 34 } }
local function tagOf(f) for _, t in ipairs(TAGS) do if f >= t[2] and f <= t[3] then return t end end end

function S.plan(o, f, im)
  -- o.at[f] = { option overrides for this frame } (hair, body, head, cols, colBand, colShift, protect...)
  if o.at and o.at[f] then o = setmetatable(o.at[f], { __index = o }) end
  local bb = S.figure(im)
  if not bb then return { rows = {}, cols = {} }, "empty" end
  -- o.protect[f] = rects, or fn(bb) -> rects; o.protectAll applies to every frame
  local pr = o.protect and o.protect[f]
  if type(pr) == "function" then pr = pr(bb) end
  -- o.guard (handy inside o.at[f]) = list of rects or fn(bb) -> rects, added to the above
  local rects = {}
  for _, r in ipairs(pr or o.protectAll or {}) do rects[#rects + 1] = r end
  for _, g in ipairs(o.guard or {}) do
    if type(g) == "function" then for _, r in ipairs(g(bb)) do rects[#rects + 1] = r end
    else rects[#rects + 1] = g end
  end
  S._weight = weightFor(rects)
  local spec = o.per and o.per[f]
  if type(spec) == "function" then spec = spec(bb, im) end
  if spec then return spec, "manual" end
  local hair, body, head, feet = o.hair or 1, o.body or 4, o.head or 12, o.feet or 2
  local ncols = o.cols or 0
  local ref = o._ref
  if o.lying and o.lying[f] then
    local w = bb.x1 - bb.x0
    local band = o.lyingBand or { 0.1, 0.5 }
    local n = hair + body + (o.lyingExtra or 0)
    local cols = pick(im, bb.x0 + math.floor(w * band[1]), bb.x0 + math.floor(w * band[2]), n, true)
    return { rows = {}, cols = cols, shift = o.lyingShift }, "lying"
  end
  -- stability: rows the tag's first frame cut, re-expressed from this frame's top / feet
  local preferH, preferB, preferC = {}, {}, {}
  if ref then
    for _, d in ipairs(ref.hairFromTop) do preferH[bb.y0 + d] = true end
    for _, d in ipairs(ref.bodyFromFeet) do preferB[bb.y1 - d] = true end
    for _, d in ipairs(ref.colsFromLeft) do preferC[bb.x0 + d] = true end
  end
  local rows = {}
  if o.fixedRows then
    -- rows chosen by hand (list, or fn(bb) -> list); columns may still be picked automatically
    rows = type(o.fixedRows) == "function" and o.fixedRows(bb) or o.fixedRows
  else
    if hair > 0 then
      for _, r in ipairs(pick(im, bb.y0 + 1, bb.y0 + (o.hairBand or 4), hair, false, preferH)) do rows[#rows + 1] = r end
    end
    for _, r in ipairs(pick(im, bb.y0 + head, bb.y1 - feet, body, false, preferB)) do rows[#rows + 1] = r end
  end
  local cols = {}
  local w = bb.x1 - bb.x0
  if o.colBands then
    -- several bands, each { fromFrac, toFrac, n } (e.g. both sides of a centre to protect)
    for _, b in ipairs(o.colBands) do
      for _, c in ipairs(pick(im, bb.x0 + math.floor(w * b[1]), bb.x0 + math.floor(w * b[2]), b[3], true, preferC)) do
        cols[#cols + 1] = c
      end
    end
  elseif ncols > 0 then
    local band = o.colBand or { 0.15, 0.55 }
    cols = pick(im, bb.x0 + math.floor(w * band[1]), bb.x0 + math.floor(w * band[2]), ncols, true, preferC)
  end
  return { rows = rows, cols = cols, shift = o.colShift }, "auto", bb
end

function S.run(o)
  S._colorGuard, S._colorWeight = o.guardColor, o.guardWeight
  local spr = app.open(o.src)
  local flats = {}
  for f = 1, #spr.frames do flats[f] = flat(spr, f) end
  local all = {}
  for _, c in ipairs(spr.cels) do all[#all + 1] = c end
  for _, c in ipairs(all) do spr:deleteCel(c) end
  local log = {}
  for f = 1, #spr.frames do
    local im = flats[f]
    local tag = tagOf(f)
    if tag and f == tag[2] then o._ref = nil end
    local spec, how, bb = S.plan(o, f, im)
    local out = shifted(remove(im, spec.rows, spec.cols), spec.shift)
    -- drop pixels a cut orphaned (lone now, not lone in the original); lone sparkle and
    -- mark dots that were already alone in the original are kept
    local function lonely(img, x, y)
      for dy = -1, 1 do for dx = -1, 1 do
        if (dx ~= 0 or dy ~= 0) and opaque(img, x + dx, y + dy) then return false end
      end end
      return true
    end
    local keep = {}
    for y = 0, H - 1 do for x = 0, W - 1 do
      if opaque(im, x, y) and lonely(im, x, y) then
        -- where it lands: rows are bottom-anchored (drops by the cut rows below it),
        -- columns right-anchored (moves right by the cut columns right of it), then the shift
        local gone, below = false, 0
        for _, r in ipairs(spec.rows or {}) do
          if r > y then below = below + 1 elseif r == y then gone = true end
        end
        local right = 0
        for _, c in ipairs(spec.cols or {}) do if c > x then right = right + 1 end; if c == x then gone = true end end
        if not gone then keep[(y + below) * W + (x + right - (spec.shift or 0))] = true end
      end
    end end
    local orphans = 0
    for y = 0, H - 1 do for x = 0, W - 1 do
      if opaque(out, x, y) and lonely(out, x, y) and not keep[y * W + x] then
        out:drawPixel(x, y, pc.rgba(0, 0, 0, 0)); orphans = orphans + 1
      end
    end end
    spec.orphans = orphans
    if o.fixes and o.fixes[f] then o.fixes[f](out) end
    spr:newCel(spr.layers[1], f, out, Point(0, 0))
    -- the first auto frame of each tag becomes that tag's reference
    if how == "auto" and not o._ref and bb then
      local r = { hairFromTop = {}, bodyFromFeet = {}, colsFromLeft = {} }
      for _, y in ipairs(spec.rows) do
        if y < bb.y0 + (o.head or 12) then r.hairFromTop[#r.hairFromTop + 1] = y - bb.y0
        else r.bodyFromFeet[#r.bodyFromFeet + 1] = bb.y1 - y end
      end
      for _, x in ipairs(spec.cols or {}) do r.colsFromLeft[#r.colsFromLeft + 1] = x - bb.x0 end
      o._ref = r
    end
    local lost = 0
    for _, r in ipairs(spec.rows or {}) do lost = lost + lineCost(im, r, false) end
    for _, c in ipairs(spec.cols or {}) do lost = lost + lineCost(im, c, true) end
    log[#log + 1] = string.format("%2d %-7s %-6s rows %-18s cols %-14s lost %d orphans %d", f, tag and tag[1] or "", how,
      table.concat(spec.rows or {}, ","), table.concat(spec.cols or {}, ","), lost, spec.orphans or 0)
  end
  o._ref = nil
  S._colorGuard, S._colorWeight, S._weight = nil, nil, nil
  local dir = o.src:match("^(.*)/[^/]*$")
  local base = dir .. "/" .. o.name
  spr:saveAs(base .. ".aseprite")
  app.command.ExportSpriteSheet {
    ui = false, askOverwrite = false, type = SpriteSheetType.ROWS,
    textureFilename = base .. "_sheet.png", dataFilename = base .. "_sheet.json",
    dataFormat = SpriteSheetDataFormat.JSON_ARRAY,
    filenameFormat = "{title} #{tag} {tagframe}.{extension}",
    splitTags = true, listLayers = true, listTags = true, listSlices = true,
    trim = false, trimSprite = false, mergeDuplicates = false, openGenerated = false,
  }
  app.command.SaveFileCopyAs { ui = false, filename = base .. "_preview_x4.gif", scale = 4 }
  return spr, log
end

-- review: original sheet above the shrunk one, s x, checkerboard per cell
function S.compare(a, b, out, s)
  s = s or 4
  local A, B = Image { fromFile = a }, Image { fromFile = b }
  local img = Image(A.width * s, (A.height * 2 + 8) * s, ColorMode.RGB)
  local bg, bg2 = pc.rgba(74, 68, 80, 255), pc.rgba(69, 64, 75, 255)
  local function blit(src, oy)
    for y = 0, src.height - 1 do
      for x = 0, src.width - 1 do
        local c = src:getPixel(x, y)
        local base = ((x // 32 + y // 32) % 2 == 0) and bg or bg2
        local col = pc.rgbaA(c) > 0 and c or base
        for dy = 0, s - 1 do for dx = 0, s - 1 do img:drawPixel(x * s + dx, (oy + y) * s + dy, col) end end
      end
    end
  end
  blit(A, 0); blit(B, A.height + 8)
  img:saveAs(out)
end

-- compact text dump of chosen frames (one char per pixel: S skin, a-j by brightness)
function S.dump(path, frames, y0)
  local spr = app.open(path)
  for _, f in ipairs(frames) do
    local im = flat(spr, f)
    local bb = S.figure(im)
    print(string.format("frame %d  figure x%d-%d y%d-%d", f, bb.x0, bb.x1, bb.y0, bb.y1))
    for y = y0 or 0, H - 1 do
      local s = {}
      for x = 0, W - 1 do
        local c = im:getPixel(x, y)
        if pc.rgbaA(c) == 0 then s[#s + 1] = "."
        elseif pc.rgbaR(c) > 200 and pc.rgbaG(c) > 150 and pc.rgbaB(c) < 170 and pc.rgbaR(c) - pc.rgbaB(c) > 60 then s[#s + 1] = "S"
        else
          local l = (pc.rgbaR(c) * 0.3 + pc.rgbaG(c) * 0.59 + pc.rgbaB(c) * 0.11) / 255
          local k = math.min(10, math.floor(l * 10) + 1); s[#s + 1] = string.sub("abcdefghij", k, k)
        end
      end
      local line = table.concat(s)
      if line:find("[^%.]") then print(string.format("%2d %s", y, line)) end
    end
  end
end

-- one call per character: shrink <name>.aseprite into <name>_small.* and write a review sheet
function S.make(name, o, review)
  local here = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
  local D = here .. "/.."
  o.src, o.name = D .. "/" .. name .. ".aseprite", name .. "_small"
  local spr, log = S.run(o)
  S.compare(D .. "/" .. name .. "_sheet.png", D .. "/" .. name .. "_small_sheet.png", review or (here .. "/" .. name .. "_compare.png"), 4)
  return spr, log
end

return S
