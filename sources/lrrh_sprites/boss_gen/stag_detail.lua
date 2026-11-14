-- Detail passes for the 48 px stag (the Briar Hart boss), applied to every pose:
--   clean:  interior specks become their surroundings (the 48 px conversion is noisy)
--   detail: rim light from the upper right, darker undersides, short fur strokes on the
--           flanks, three-tone antlers (lit tops, shaded undersides), lit hoof fronts
-- Usage: local D = dofile(".../stag_detail.lua")(L, K); c = D.detail(D.clean(c))
return function(L, K)
  local D = {}
  local W = L.W
  local FUR = { K["1"], K["2"], K["3"], K["4"], K["5"], K["6"] }
  local idx = {}
  for i, c in ipairs(FUR) do idx[c] = i end
  local HORN = { [K.a] = 1, [K.b] = 2, [K.c] = 3 }
  local function nb8(c, x, y)
    local o = {}
    for dy = -1, 1 do for dx = -1, 1 do
      if dx ~= 0 or dy ~= 0 then o[#o + 1] = c:get(x + dx, y + dy) or false end
    end end
    return o
  end

  function D.clean(c)
    local out = c:copy()
    for k, v in pairs(c.p) do
      local x, y = k % W, k // W
      if v ~= K.y and not HORN[v] then
        local cnt, total, air = {}, 0, 0
        for _, n in ipairs(nb8(c, x, y)) do
          if n then cnt[n] = (cnt[n] or 0) + 1; total = total + 1 else air = air + 1 end
        end
        local best, bn = nil, 0
        for col, n in pairs(cnt) do if n > bn and col ~= K.y then best, bn = col, n end end
        local mine = cnt[v] or 0
        -- a lone pixel inside the body that differs from a clear majority around it
        if air == 0 and mine <= 1 and bn >= 5 and best ~= v then out.p[k] = best end
      end
    end
    return out
  end

  -- volume: across each vertical run of fur (body, neck, head) the top third is lit and the
  -- bottom third shaded; thin horizontal runs (legs) are lit on the right, shaded on the left
  function D.volume(c)
    local out = c:copy()
    local function fur(x, y) return idx[c:get(x, y)] end
    for x = 0, W - 1 do
      local y = 0
      while y < L.H do
        if fur(x, y) then
          local y0 = y
          while y < L.H and fur(x, y) do y = y + 1 end
          local y1 = y - 1
          local h = y1 - y0 + 1
          if h >= 4 and h <= 16 then
            for yy = y0, y1 do
              local t = (yy - y0) / (h - 1)
              local i = idx[c:get(x, yy)]
              if t < 0.28 and i < 6 then out:set(x, yy, FUR[i + 1])
              elseif t > 0.72 and i > 1 then out:set(x, yy, FUR[i - 1]) end
            end
          end
        else y = y + 1 end
      end
    end
    for y = 0, L.H - 1 do
      local x = 0
      while x < W do
        if fur(x, y) then
          local x0 = x
          while x < W and fur(x, y) do x = x + 1 end
          local x1 = x - 1
          if x1 - x0 + 1 <= 3 and y > L.H * 0.7 then
            local i = idx[c:get(x1, y)]
            out:set(x1, y, FUR[math.min(6, i + 1)])
            if x1 > x0 then local j = idx[c:get(x0, y)]; out:set(x0, y, FUR[math.max(1, j - 1)]) end
          end
        else x = x + 1 end
      end
    end
    return out
  end

  function D.detail(c)
    c = D.volume(c)
    local out = c:copy()
    local function air(x, y) local n = c:get(x, y); return not n or n == K.o end
    for k, v in pairs(c.p) do
      local x, y = k % W, k // W
      local i = idx[v]
      if i == 1 and air(x + 1, y) then
        out.p[k] = FUR[3]                                     -- legs and chest: lit front edge
      elseif i and i >= 2 then
        if air(x, y - 1) or (air(x + 1, y) and air(x + 1, y - 1)) then
          out.p[k] = FUR[math.min(6, i + 1)]                 -- rim light, upper right
        elseif i <= 3 and air(x + 1, y) then
          out.p[k] = FUR[i + 1]
        elseif air(x, y + 1) and i >= 3 then
          out.p[k] = FUR[i - 1]                               -- underside falls into shade
        elseif i >= 4 and not air(x, y - 2) and not air(x, y + 2) and not air(x - 1, y) and not air(x + 1, y)
          and L.hash(x * 31 + y * 7) < 0.07 then
          out.p[k] = FUR[i - 1]                               -- fur stroke, two pixels tall
          if idx[c:get(x, y + 1)] == i then out:set(x, y + 1, FUR[i - 1]) end
        end
      elseif HORN[v] then
        local up, down = c:get(x, y - 1), c:get(x, y + 1)
        if not HORN[up] then out.p[k] = K.c                   -- tines catch the light on top
        elseif not HORN[down] then out.p[k] = K.a             -- and shade underneath
        elseif HORN[v] == 3 then out.p[k] = K.b end
      end
    end
    -- shaggy ruff: the dark fur under the neck hangs down in little points
    for k, v in pairs(c.p) do
      local x, y = k % W, k // W
      if (v == K["1"] or v == K["2"]) and c:get(x, y + 1) == K.o and not c:get(x, y + 2)
        and y < L.H - 10 and (x + y) % 3 == 0 then
        out:set(x, y + 1, v); out:set(x, y + 2, K.o)
        if not out:get(x - 1, y + 2) then out:set(x - 1, y + 2, nil) end
      end
    end
    -- hooves: the front pixel of each foot gets a glint
    for k, v in pairs(c.p) do
      local x, y = k % W, k // W
      if y == L.H - 1 and v ~= K.o and idx[v] and air(x + 1, y) then out.p[k] = K["3"] end
    end
    return out
  end
  return D
end
