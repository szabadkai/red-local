-- Rogue hunter: green-hooded woodsman with a bow and bear traps.
-- "Ranged • Traps • Precise". attack = bow shot, special = sets a bear trap that snaps.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local L = dofile(HERE .. "/lib.lua")
local round = L.round

local P = L.pal {
  ol = "#161a12",
  hood = { "#243522", "#36542c", "#52763a", "#7fa04a" },
  shade = "#2a2228",      -- face shadow inside the hood, far leg
  skin = "#d8a07a",
  lea = { "#45301f", "#6e4a2e", "#9a6c40" },
  pants = "#3c3644",
  metal = { "#76767a", "#c9c6bc" },
}

local BX, BY = 13, 26     -- canvas position of the hip when standing (feet on y = 31)

local function stamp(c, x, y, rows, map)
  for j, row in ipairs(rows) do
    for i = 1, #row do
      local col = map[row:sub(i, i)]
      if col then c:set(x + i - 1, y + j - 1, col) end
    end
  end
end
local TRAPMAP = { o = P.ol, m = P.metal[1], l = P.metal[2], d = P.lea[1] }
local TRAP_OPEN = {
  ".l.l.l.l.",
  "lmmmmmmml",
  "oodmlmdoo",
}
local TRAP_SHUT = {
  ".l.l.l.l.",
  "lmlmlmlml",
  ".mmmmmmm.",
  "..m...m..",
  "oodmlmdoo",
}
local TRAP_HELD = {
  ".l.l.",
  "lmlml",
  "mdddm",
}

------------------------------------------------------------------ rig
-- Local coordinates: hip at (0, 0), ground at y = 5, +x forward. Everything goes
-- through T, which rotates about the feet (for the fall) and offsets the figure.
-- p: ox, oy, ang, hy (hip drop), bob (upper body drop), lean (head forward),
--    fa / fb near / far foot, ha / hb near / far hand,
--    bow = "front" | "back" | nil, bowang, pull = {x, y} string pulled to,
--    tipx, tipy (hood tip flop), cape (cape blown back), face = "hurt" | "ko"
local function rig(c, p)
  local ca, sa = math.cos(p.ang or 0), math.sin(p.ang or 0)
  local ox, oy = BX + (p.ox or 0), BY + (p.oy or 0)
  local function T(x, y)
    local dx, dy = x, y - 5
    return ox + dx * ca - dy * sa, oy + 5 + dx * sa + dy * ca
  end
  local function seg(x0, y0, x1, y1, r, col)
    local a, b = T(x0, y0); local e, f = T(x1, y1); c:seg(a, b, e, f, r, col)
  end
  local function poly(pts, col)
    local q = {}
    for i, v in ipairs(pts) do local x, y = T(v[1], v[2]); q[i] = { x, y } end
    c:poly(q, col)
  end
  local function ell(x, y, rx, ry, col) local a, b = T(x, y); c:ell(a, b, rx, ry, col) end
  local function ball(x, y, rx, ry, ramp, bias) local a, b = T(x, y); c:ball(a, b, rx, ry, ramp, bias) end
  local function dot(x, y, col) local a, b = T(x, y); c:set(a, b, col) end
  local function curve(x0, y0, cx, cy, x1, y1, col, r)
    local a, b = T(x0, y0); local d, e = T(cx, cy); local f, g = T(x1, y1)
    c:curve(a, b, d, e, f, g, col, r)
  end

  local hy, bob, lean = p.hy or 0, p.bob or 0, p.lean or 0
  local up = hy + bob                  -- upper-body vertical offset
  local sx = lean * 0.5                -- shoulder x
  local hcx, hcy = lean + 0.5, up - 11 -- hood centre
  local info = {}

  local function leg(side, foot, col)
    local hx_, hy_ = side, hy
    local fx, fy = foot[1], foot[2] - 1
    local dx, dy = fx - hx_, fy - hy_
    local dist = math.max(0.01, math.sqrt(dx * dx + dy * dy))
    local half = 2.0
    local k = math.sqrt(math.max(0, half * half - (dist / 2) ^ 2))
    local nx, ny = -dy / dist, dx / dist
    if nx < 0 then nx, ny = -nx, -ny end
    local kx, ky = hx_ + dx / 2 + nx * k, hy_ + dy / 2 + ny * k
    seg(hx_, hy_, kx, ky, 0.85, col)
    seg(kx, ky, fx, fy, 0.85, col)
    -- boot, toe forward
    poly({ { fx - 1.4, fy - 0.6 }, { fx + 1.6, fy - 0.6 }, { fx + 1.6, fy + 1.4 }, { fx - 1.4, fy + 1.4 } }, P.lea[1])
  end

  local function bowAt(gx, gy, ang, pull)
    -- grip at (gx, gy); limbs curve forward; tips 5 px above/below
    local s, co = math.sin(ang or 0), math.cos(ang or 0)
    local function R(dx, dy) return gx + dx * co - dy * s, gy + dx * s + dy * co end
    local bend = pull and 2.6 or 2.0
    local t1x, t1y = R(-bend, -5)
    local t2x, t2y = R(-bend, 5)
    local mx, my = R(bend, 0)
    curve(t1x, t1y, mx, my, t2x, t2y, P.lea[3], 0.55)
    local a, b = T(t1x, t1y); local d, e = T(t2x, t2y)
    info.tips = { a, b, d, e }
    if pull then info.nock = { T(pull[1], pull[2]) } end
  end

  -- quiver on the back, fletchings over the shoulder
  seg(sx - 3.2, up - 9, sx - 1.6, up - 2.5, 1.1, P.lea[1])
  dot(sx - 4, up - 10, L.FLASH); dot(sx - 3, up - 10, L.MARK2); dot(sx - 4, up - 9, L.MARK2)

  if p.bow == "back" then bowAt(p.hb[1], p.hb[2], p.bowang or 0.3) end
  -- far arm
  seg(sx - 1.5, up - 5, p.hb[1], p.hb[2], 0.85, P.lea[1])
  dot(p.hb[1], p.hb[2], P.skin)
  -- legs
  leg(-1, p.fb, P.shade)
  leg(1, p.fa, P.pants)
  -- tunic
  poly({ { sx - 3.4, up - 6.4 }, { sx + 3.4, up - 6.4 }, { 3.4, hy + 0.4 }, { -3.4, hy + 0.4 } }, P.lea[2])
  poly({ { sx + 1.6, up - 6.4 }, { sx + 3.4, up - 6.4 }, { 3.4, hy + 0.4 }, { 1.6, hy + 0.4 } }, P.lea[3])
  poly({ { sx - 3.4, up - 6.4 }, { sx - 2.4, up - 6.4 }, { -2.4, hy + 0.4 }, { -3.4, hy + 0.4 } }, P.lea[1])
  seg(-3, hy - 1, 3, hy - 1, 0.5, P.lea[1])
  dot(1, hy - 1, P.metal[2])
  -- capelet over the shoulders, back flap blown by `cape`
  local cp = p.cape or 0
  poly({ { sx - 4.6, up - 7.6 }, { sx + 4.4, up - 7.6 }, { sx + 4.4, up - 4.6 }, { sx + 1, up - 3.4 },
         { sx - 4.4 - cp, up - 2.4 + cp * 0.3 } }, P.hood[2])
  seg(sx - 4 - cp, up - 3 + cp * 0.3, sx + 1, up - 3.8, 0.5, P.hood[1])
  -- hood tip (behind the hood ball)
  local tx, ty = p.tipx or 0, p.tipy or 0
  curve(hcx - 2, hcy - 4, hcx - 5.5 - tx * 0.4, hcy - 5.5 + ty * 0.3, hcx - 7 - tx, hcy - 2 + ty,
        P.hood[2], function(t) return 1.7 - 1.2 * t end)
  ball(hcx, hcy, 5.5, 5, P.hood, -0.05)
  -- face in the hood's shadow
  ell(hcx + 2.7, hcy + 1.4, 2.3, 2.8, P.shade)
  ell(hcx + 3.4, hcy + 2.0, 1.3, 1.6, P.skin)
  if p.face == "hurt" then
    dot(hcx + 3, hcy + 1, P.ol); dot(hcx + 4, hcy + 1.5, P.ol)
  elseif p.face ~= "ko" then
    dot(hcx + 3, hcy + 1, P.ol)
  end
  dot(hcx + 5, hcy + 3, P.skin)
  -- near arm and the bow it holds
  seg(sx + 1.5, up - 5, p.ha[1], p.ha[2], 0.85, P.lea[2])
  if p.bow == "front" then bowAt(p.ha[1], p.ha[2], p.bowang, p.pull) end
  dot(p.ha[1], p.ha[2], P.skin)
  if p.held then info.held = { T(p.ha[1], p.ha[2]) } end
  return info
end

-- string, arrows and other unoutlined bits after the body outline
local function strings(c, info)
  if not info.tips then return end
  local t = info.tips
  if info.nock then
    c:line(t[1], t[2], info.nock[1], info.nock[2], P.metal[2])
    c:line(info.nock[1], info.nock[2], t[3], t[4], P.metal[2])
  else
    c:line(t[1], t[2], t[3], t[4], P.metal[2])
  end
end
local function arrow(c, x, y, len, streak)
  c:line(x - len + 1, y, x - 1, y, P.lea[3])
  c:set(x, y, P.metal[2]); c:set(x + 1, y, P.metal[2])
  c:set(x - len + 1, y - 1, L.FLASH); c:set(x - len, y - 1, L.MARK2); c:set(x - len + 1, y + 1, L.MARK2)
  if streak then c:line(x - len - streak, y, x - len - 1, y, L.MARK2) end
end

local function body(p, fx)
  local c = L.canvas()
  local info = rig(c, p)
  c:outline(P.ol)
  strings(c, info)
  if fx then fx(c, info) end
  return c
end

------------------------------------------------------------------ poses
local STAND = { fa = { 2, 5 }, fb = { -2, 5 }, ha = { 6, -1 }, hb = { -3, -1 }, bow = "front" }
local function pose(t)
  local o = {}
  for k, v in pairs(STAND) do o[k] = v end
  for k, v in pairs(t or {}) do o[k] = v end
  return o
end

local function idle(i)
  local bob = ({ 0, 1, 1, 0 })[i + 1]
  local lag = ({ 0, 0, 1, 1 })[i + 1]          -- hood tip and cape trail the body by a frame
  return pose { bob = bob, ha = { 6, -1 + bob }, hb = { -3, -1 + bob }, tipy = lag, cape = lag }
end

local RUN = {
  { fa = { 4, 5 }, fb = { -4, 3 }, hy = 0, hb = { -4, -2 }, ha = { 5, -2 } },
  { fa = { 1, 5 }, fb = { -1, 2 }, hy = -1, hb = { -1, -3 }, ha = { 4, -3 } },
  { fa = { -4, 3 }, fb = { 4, 5 }, hy = 0, hb = { 2, -3 }, ha = { 5, -2 } },
  { fa = { -1, 2 }, fb = { 1, 5 }, hy = -1, hb = { -1, -3 }, ha = { 4, -3 } },
}
local function run(i)
  local r = RUN[i + 1]
  local flap = ({ 0, 1, 0, 1 })[i + 1]
  return pose { fa = r.fa, fb = r.fb, hy = r.hy, ha = r.ha, hb = r.hb, lean = 2, bowang = 0.45,
                tipx = 2 + flap, tipy = 1 - flap, cape = 2 + flap }
end

local function hitPose(k)
  return pose { ox = -1, lean = -1, ha = { 4, -4 }, hb = { -4, -4 }, face = "hurt", tipx = 1 - k, tipy = -1, cape = 1,
                fa = { 3, 5 }, fb = { -2, 5 }, bowang = -0.4 }
end

------------------------------------------------------------------ draw
local AIM = { fa = { 3, 5 }, fb = { -2, 5 }, ha = { 6, -5 } }
local function draw(tag, i, n)
  if tag == "idle" then return body(idle(i)) end
  if tag == "run" then return body(run(i)) end

  if tag == "attack" then
    if i == 0 then      -- raise the bow, reach for the string
      return body(pose { fa = AIM.fa, fb = AIM.fb, ha = { 6, -4 }, hb = { 3, -4 }, tipy = 0, bowang = -0.15 })
    elseif i == 1 then  -- draw
      return body(pose { fa = AIM.fa, fb = AIM.fb, ha = AIM.ha, hb = { 2, -5 }, pull = { 2, -5 }, lean = -1, tipx = 1 },
        function(c) arrow(c, BX + 9, BY - 5, 7) end)
    elseif i == 2 then  -- full draw, held
      return body(pose { fa = AIM.fa, fb = AIM.fb, ha = AIM.ha, hb = { 0, -5 }, pull = { 0, -5 }, lean = -1, tipx = 1, tipy = 1 },
        function(c) arrow(c, BX + 9, BY - 5, 9) end)
    elseif i == 3 then  -- release: string snaps, arrow away
      return body(pose { fa = AIM.fa, fb = AIM.fb, ha = AIM.ha, hb = { -3, -6 }, ox = -1, lean = -1, tipx = 2, tipy = 1, cape = 1 },
        function(c) arrow(c, 29, BY - 5, 6, 5) end)
    elseif i == 4 then
      return body(pose { fa = AIM.fa, fb = AIM.fb, ha = AIM.ha, hb = { -3, -5 }, ox = -1, lean = -1, tipx = 1, tipy = 0, cape = 1 },
        function(c) arrow(c, 34, BY - 5, 6, 4) end)
    else
      return body(pose { fa = AIM.fa, fb = AIM.fb, ha = { 5, -3 }, hb = { -3, -2 }, bob = 1, tipy = 1 })
    end
  end

  if tag == "special" then
    local TX = 22    -- trap lands at x 22..30
    local S = {
      -- reach to the belt, bow swapped to the far hand
      pose { bow = "back", hb = { -3, 0 }, ha = { 3, -1 }, hy = 1, bob = 0, lean = 0 },
      -- pull the trap out
      pose { bow = "back", hb = { -3, 0 }, ha = { 4, -3 }, hy = 1, lean = 1, held = true, tipy = 1 },
      -- crouch and set it down
      pose { bow = "back", hb = { -4, 1 }, ha = { 8, 2 }, hy = 3, lean = 3, fa = { 4, 5 }, fb = { -3, 5 }, held = true, tipy = 1, cape = 1 },
      -- trap open on the ground, hand coming back
      pose { bow = "back", hb = { -4, 1 }, ha = { 6, 1 }, hy = 2, lean = 2, fa = { 4, 5 }, fb = { -3, 5 }, tipy = 2, cape = 1 },
      -- stand up, glint
      pose { bow = "back", hb = { -3, 0 }, ha = { 4, -1 }, hy = 1, lean = 0, tipy = 1 },
      -- snap!
      pose { bow = "back", hb = { -3, -1 }, ha = { 4, -2 }, ox = -1, lean = -1, tipx = 1 },
      pose { bow = "back", hb = { -3, -1 }, ha = { 4, -2 }, ox = -1, lean = -1, tipx = 0, tipy = 1 },
      pose { bob = 1, tipy = 1 },
    }
    return body(S[i + 1], function(c, info)
      if i == 1 and info.held then stamp(c, round(info.held[1]) - 2, round(info.held[2]) - 1, TRAP_HELD, TRAPMAP) end
      if i == 2 and info.held then stamp(c, round(info.held[1]) - 2, 29, TRAP_HELD, TRAPMAP) end
      if i == 3 or i == 4 then stamp(c, TX, 29, TRAP_OPEN, TRAPMAP) end
      if i == 4 then L.sparkle(c, TX + 7, 27, P.metal[2], 1, L.FLASH) end
      if i >= 5 then stamp(c, TX, 27, TRAP_SHUT, TRAPMAP) end
      if i == 5 then L.impact(c, TX + 7, 25) end
      if i == 6 then L.impact(c, TX + 8, 24) end
    end)
  end

  if tag == "hit" then
    if i == 0 then return body(hitPose(0)):flash() end
    if i == 1 then return body(hitPose(0), function(c) L.impact(c, 24, 11) end) end
    if i == 2 then return body(hitPose(1), function(c) L.impact(c, 25, 10) end) end
    return body(pose { bob = 1, tipy = 1, cape = 1 })
  end

  if tag == "death" then
    local function droppedBow(c)
      c:curve(2, 31, 7, 27, 12, 31, P.lea[3], 0.55)
    end
    -- face-down on the ground, hood to the right (drawn flat, not a rotated rig)
    local function lying(dy, tip)
      local c = L.canvas()
      droppedBow(c)
      c:seg(12, 27 + dy, 6, 27 + dy, 0.85, P.shade)                -- far leg
      c:seg(12, 30 + dy, 6, 30 + dy, 0.85, P.pants)                -- near leg
      c:rect(3, 26 + dy, 5, 27 + dy, P.lea[1]); c:rect(3, 29 + dy, 5, 30 + dy, P.lea[1])
      c:rect(11, 26 + dy, 17, 30 + dy, P.lea[2])                   -- tunic
      c:line(11, 26 + dy, 17, 26 + dy, P.lea[3])
      c:line(12, 27 + dy, 12, 30 + dy, P.lea[1]); c:set(12, 28 + dy, P.metal[2])
      c:seg(13, 25 + dy, 17, 24 + dy, 0.9, P.lea[1])               -- quiver on the back
      c:set(12, 24 + dy, L.FLASH); c:set(12, 25 + dy, L.MARK2)
      c:poly({ { 15.4, 24.6 + dy }, { 21, 24 + dy }, { 21, 30.6 + dy }, { 15.4, 30.6 + dy } }, P.hood[2])
      c:line(16, 30 + dy, 20, 30 + dy, P.hood[1])
      c:curve(21, 24 + dy, 18, 21 + dy + tip, 15, 23 + dy + tip, P.hood[2], function(t) return 1.6 - 1.1 * t end)
      c:ball(24, 27 + dy, 5, 3.6, P.hood, -0.05)
      c:seg(22, 31, 28, 31, 0.5, P.lea[2])                         -- arm flung forward
      c:set(29, 31, P.skin)
      c:set(28, 30 + dy, P.shade); c:set(27, 30 + dy, P.skin)      -- a sliver of face
      return c:outline(P.ol)
    end
    if i <= 2 then
      local D = {
        pose { ox = -1, lean = -1, face = "hurt", ha = { 4, -4 }, hb = { -4, -3 }, tipx = 1, tipy = -1, bowang = -0.5 },
        pose { hy = 2, lean = 2, face = "hurt", ha = { 6, 1 }, hb = { -3, 1 }, fa = { 3, 5 }, fb = { -2, 5 }, bowang = 0.9, tipy = 1 },
        pose { ang = 0.7, ox = 1, hy = 1, lean = 1, face = "ko", bow = false, ha = { 6, -1 }, hb = { -3, 0 }, tipx = -1, tipy = 2 },
      }
      local c = L.canvas()
      if i == 2 then droppedBow(c); c:outline(P.ol) end
      return c:over(body(D[i + 1]))
    end
    local c = lying(i == 3 and -1 or 0, i == 3 and -1 or (i % 2))
    if i == 3 then L.puff(c, 29, 29, 1.6, { P.metal[1], L.MARK2 }, i); L.puff(c, 13, 30, 1.4, { P.metal[1], L.MARK2 }, 9) end
    if i >= 4 and i <= 6 then L.dizzy(c, 23, 16 - (i - 4), i) end
    return c
  end
end

return L.build("rogue_hunter", HERE .. "/..", draw, REVIEW)
