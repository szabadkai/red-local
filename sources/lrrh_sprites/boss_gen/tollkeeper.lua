-- The Tollkeeper: story boss of the Huntsman's Bridge, bound to the mill. A hulking iron jailer:
-- dark plate armour, a helm with a glowing yellow slit, a gold padlock on his chest, chains
-- crossed over his body and a hook on a chain in his fist.
-- attack = swing the chain hook forward, special = raise both fists and slam the ground.
-- Run inside Aseprite: dofile(".../boss_gen/tollkeeper.lua")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local B = dofile(HERE .. "/blib.lua")
local L = B.L

local IRON = B.ramp({ "#15141e", "#26252f", "#35343f", "#4a4856", "#5f5c6c", "#7a7688" })
local CLOTH = B.ramp({ "#2a1a1e", "#4a2a2e", "#6b3a3a" })
local GOLD = B.ramp({ "#6e4f26", "#bc9560", "#e6c48a" })
local CHAIN = B.ramp({ "#1f1d28", "#6a6778", "#a9a5b8" })
local SLIT = B.EYE

-- p: x/y offset, lean, armN/armF (swing, + = forward/up), legs (stride), hook = {x, y} or nil, crouch
local function keeper(p)
  local c = L.canvas()
  local ox, oy = 22 + (p.x or 0), 27 + (p.y or 0) + (p.crouch or 0) * 3
  local tf = L.xf(ox, oy, p.lean or 0)
  local stride = p.legs or 0
  local function leg(dx, a, bias)
    local m = L.canvas()
    local hx, hy = tf(dx, 8)
    local kx, ky = hx + math.sin(a) * 5, hy + 5 - (p.crouch or 0) * 1.5
    local fx, fy = kx - math.sin(a) * 1, 44
    m:seg(hx, hy, kx, ky, 2.8, B.MASK)
    m:seg(kx, ky, fx, fy, 2.6, B.MASK)
    m:rect(fx - 3, 44, fx + 3, 47, B.MASK)
    L.shade(c, m, IRON, bias)
  end
  local function arm(sx, a, bias, fist)
    local m = L.canvas()
    local x0, y0 = tf(sx, -6)
    local ex, ey = x0 + math.sin(a) * 6, y0 + math.cos(a) * 6
    local hx, hy = ex + math.sin(a + .4) * 5, ey + math.cos(a + .4) * 5
    m:ell(x0, y0, 4, 3.5, B.MASK)                       -- pauldron
    m:seg(x0, y0, ex, ey, 2.6, B.MASK)
    m:seg(ex, ey, hx, hy, 2.4, B.MASK)
    m:ell(hx, hy, 2.6, 2.4, B.MASK)
    L.shade(c, m, IRON, bias)
    return hx, hy
  end
  arm(-6, -(p.armF or 0), -.32)
  leg(-4, -stride, -.3)
  -- tabard under the plate
  B.part(c, CLOTH, 0, function(m, k) m:poly(L.mapPts(tf, { { -7, 4 }, { 7, 4 }, { 6, 12 }, { -6, 12 } }), k) end)
  -- chest plate: broad barrel
  B.part(c, IRON, .05, function(m, k)
    m:poly(L.mapPts(tf, { { -10, -9 }, { 10, -9 }, { 12, -2 }, { 9, 7 }, { -9, 7 }, { -12, -2 } }), k)
  end)
  -- helm: bucket helm with a visor slit and a crest stub
  local hx, hy = tf(1, -13)
  B.part(c, IRON, .15, function(m, k)
    m:rect(hx - 5, hy - 5, hx + 5, hy + 4, k)
    m:ell(hx, hy - 5, 5, 2.5, k)
  end)
  c:line(hx - 1, hy - 1, hx + 4, hy - 1, IRON[1])
  c:set(hx + 2, hy - 1, SLIT); c:set(hx + 3, hy - 1, SLIT)
  c:set(hx + 1, hy - 8, CLOTH[3]); c:set(hx, hy - 8, CLOTH[3]); c:set(hx + 1, hy - 9, CLOTH[2])   -- crest stub
  -- crossed chains over the plate and the padlock at their knot
  local a1x, a1y = tf(-10, -8); local a2x, a2y = tf(9, 5)
  local b1x, b1y = tf(10, -8); local b2x, b2y = tf(-9, 5)
  B.chain(c, a1x, a1y, a2x, a2y, CHAIN)
  B.chain(c, b1x, b1y, b2x, b2y, CHAIN)
  local lx, ly = tf(0, -1)
  B.part(c, GOLD, .1, function(m, k) m:rect(lx - 3, ly - 1, lx + 3, ly + 4, k) end)
  c:set(lx - 2, ly - 3, GOLD[2]); c:set(lx - 2, ly - 2, GOLD[2]); c:set(lx + 2, ly - 3, GOLD[2]); c:set(lx + 2, ly - 2, GOLD[2]); c:line(lx - 1, ly - 4, lx + 1, ly - 4, GOLD[2])
  c:set(lx, ly + 1, IRON[1]); c:set(lx, ly + 2, IRON[1])
  leg(4, stride, 0)
  local fx, fy = arm(7, p.armN or 0, .08)
  -- hook on a chain from the near fist
  if p.hook then
    B.chain(c, fx + 1, fy + 1, p.hook[1], p.hook[2], CHAIN)
    local hx2, hy2 = p.hook[1], p.hook[2]
    c:line(hx2, hy2, hx2 + 2, hy2 + 2, CHAIN[3]); c:line(hx2 + 2, hy2 + 2, hx2 + 1, hy2 + 4, CHAIN[3]); c:set(hx2, hy2 + 4, CHAIN[2])
  end
  return c
end

local function dust(c, x, y, r, seed) L.puff(c, x, y, r, B.DUST, seed) end

local function draw(tag, i, n)
  if tag == "idle" then
    local b = (i == 1 or i == 2) and 1 or 0
    return B.finish(keeper({ y = b, armN = .1 + b * .05, armF = .05, hook = { 36 + (i % 2), 44 - b } }))
  elseif tag == "run" then
    local S = { .5, 0, -.5, 0 }
    local c = L.canvas()
    if i % 2 == 0 then dust(c, 12, 46, 1.4, i + 3) end
    return B.finish(c:over(keeper({ y = (i % 2 == 1) and -1 or 0, lean = .08, legs = S[i + 1], armN = -S[i + 1] * .8, armF = S[i + 1] * .8, hook = { 34 - (i % 2) * 2, 43 } })))
  elseif tag == "attack" then
    -- 0-2 wind the hook back over the shoulder, 3-4 whip it forward, 5 reel it in
    if i <= 2 then return B.finish(keeper({ x = -i, lean = -.1 - i * .05, armN = 2.2 + i * .3, hook = { 14 - i * 3, 8 + i } })) end
    if i == 5 then return B.finish(keeper({ armN = .4, hook = { 38, 36 } })) end
    local c = B.finish(keeper({ x = 2, lean = .18, armN = 1.2, legs = .4, hook = { 46, 22 + (i - 3) * 4 } }))
    B.arc(c, 26, 26, 17, -1.6, .2, L.FLASH, L.MARK2)
    return c
  elseif tag == "special" then
    -- raise both fists (0-3), slam down (4), dust and shockwave (5-7)
    local c = L.canvas()
    if i <= 3 then return B.finish(keeper({ y = -math.min(i, 2), lean = -.12, armN = 2.6 + i * .1, armF = 2.5 + i * .1, hook = { 30, 2 + i } })) end
    if i == 4 then dust(c, 30, 46, 2.6, 81); dust(c, 14, 46, 2.2, 82) end
    if i == 5 then dust(c, 36, 46, 2, 83); dust(c, 8, 46, 1.8, 84) end
    c:over(keeper({ crouch = i == 4 and 1 or .5, lean = .25, armN = .9, armF = .8, hook = { 40, 44 } }))
    B.finish(c)
    if i >= 4 and i <= 6 then local w = (i - 3) * 5; c:line(24 - w, 46, 24 - w + 3, 46, L.FLASH); c:line(24 + w, 46, 24 + w + 3, 46, L.FLASH) end
    return c
  elseif tag == "hit" then
    if i == 0 then return keeper({ x = -1 }):flash() end
    local c = B.finish(keeper({ x = i == 1 and -3 or -2, lean = -.12, armN = -.3, hook = { 34, 44 } }))
    if i < 3 then L.impact(c, 33, 4 + i) end
    return c
  elseif tag == "death" then
    -- sway, drop to one knee, topple backwards; the padlock falls open
    if i <= 1 then return B.finish(keeper({ x = -2, lean = -.15 - i * .1, crouch = i, armN = -.2, hook = { 34, 44 } })) end
    local c = L.canvas()
    if i == 3 then dust(c, 16, 46, 2.4, 91); dust(c, 30, 46, 2, 92) end
    c:over(keeper({ x = -4, y = 12, lean = -1.2, armN = -.6, armF = -.4, hook = { 36, 45 } }))
    B.finish(c)
    if i >= 4 and i <= 6 then L.dizzy(c, 16, 22 - (i - 4) // 2, i) end
    return c
  end
end

return B.build("tollkeeper", draw)
