-- Grandmother at red-local scale (16 px tall, stooped over her cane, shorter than Red).
-- attack = cane thwack (spectacles glint), special = lantern held up on the cane with a big glow.
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
local K = dofile(HERE .. "/kit.lua")

local MAP = {
  H = "#ece0ee", h = "#a891b4",                 -- hair (lavender grey)
  s = "#ffeec8", b = "#ff9f89", o = "#ffeec8",  -- skin, blush, mouth (skin until opened)
  E = "#000000", e = "#000000",                 -- eye top / eye bottom, near shoe
  D = "#ad5a9e", d = "#6e3068",                 -- dress
  k = "#7a4228",                                -- cane, lantern frame, far shoe
  Y = "#fffdae", y = "#ffc24a",                 -- lantern light
}
local function A(rows) return K.art(rows, MAP) end
local C = {}
for k, v in pairs(MAP) do C[k] = K.rgb(v) end
local MARK, MARK2 = K.MARK, K.MARK2

------------------------------------------------------------------ parts
local HEAD = A {
  ".hHh.........",
  "hHHHhhHHHh...",
  "hhhHHHHHHHH..",
  ".hHHHHHHHHHH.",
  "hHHhHHsssssH.",
  "hhHHHsEssEsH.",
  "hHhHHsessesss",
  ".hhHHbssssbs.",
  "..hhhhsssss..",
}
local HEAD_BLINK = K.swap(HEAD, { E = "s" }, MAP)
local HEAD_HURT = K.swap(HEAD, { E = "s", e = "h", o = "d" }, MAP)
local HEAD_GLINT = K.art({   -- spectacles flash while she scolds
  ".hHh.........",
  "hHHHhhHHHh...",
  "hhhHHHHHHHH..",
  ".hHHHHHHHHHH.",
  "hHHhHHsssssH.",
  "hhHHHkWkkWkH.",
  "hHhHHsWssWsss",
  ".hhHHbssssbs.",
  "..hhhhssdss..",
}, { H = MAP.H, h = MAP.h, s = MAP.s, b = MAP.b, k = MAP.k, d = MAP.d, W = "#f6ecee" })

local BODY = {
  idle = A {
    ".dDDD.......",
    "dDDDDD......",
    "dDDDDDDDDD..",
    "dDDDDDDDDDD.",
    "dDDDDDDDDDD.",
    "ddDDDDDDDDDD",
    ".dddddDDDDd.",
  },
  idle2 = A {   -- breath out: shoulders sink, hem flares
    "............",
    ".dDDD.......",
    "dDDDDDDDDD..",
    "dDDDDDDDDDD.",
    "dDDDDDDDDDD.",
    "ddDDDDDDDDDD",
    "dddddDDDDDdd",
  },
  hunch = A {   -- bent further forward (run / effort)
    "..dDD.......",
    ".dDDDDD.....",
    "dDDDDDDDDDD.",
    "dDDDDDDDDDDD",
    "dDDDDDDDDDD.",
    "ddDDDDDDDDD.",
    ".ddddDDDDDd.",
  },
  tall = A {    -- straightened up (raising the cane / lantern)
    "..dDDDD.....",
    ".dDDDDDDD...",
    "dDDDDDDDDD..",
    "dDDDDDDDDD..",
    "dDDDDDDDDDD.",
    "ddDDDDDDDDD.",
    ".ddddDDDDDd.",
  },
}
local LEGS = {
  stand = A { "....kk.ee...", "...kkk.eee.." },
  r1 = A { "...kk...ee..", "..kk....eee." },   -- near foot forward
  r2 = A { ".....kkee...", ".....kkeee.." },   -- passing
  r3 = A { "...ee...kk..", "..eee...kkk." },   -- far foot forward
  r4 = A { ".....eekk...", ".....eeekk.." },   -- passing
  wide = A { "...kk....ee.", "..kkk....eee" },
  kneel = A { "............", ".kkkk..eeee." },
}
local LANTERN = A { ".k.", "kkk", "kYk", "kyk", "kkk" }
local DOWN = A {   -- face down on the ground, back of the dress humped up (head drawn separately)
  ".....dDDDDD..",
  "...ddDDDDDDDD",
  "kk.dDDDDDDDDD",
  "kkeddddddDDDD",
}

------------------------------------------------------------------ figure
local OX, OY = 9, 16   -- top-left of the 14x16 figure box when standing (feet on y = 31)
-- straight cane from its handle end (x0, y0) to (x1, y1) in canvas coords;
-- hook = -1 / 1 curls the handle left / right, 2 / -2 = a longer curl that can carry the lantern
local function cane(c, x0, y0, x1, y1, hook)
  c:line(x0, y0, x1, y1, C.k)
  if hook == false then return end
  hook = hook or -1
  local h = hook > 0 and 1 or -1
  c:set(x0, y0 - 1, C.k); c:set(x0 + h, y0 - 1, C.k)
  if math.abs(hook) == 2 then c:set(x0 + 2 * h, y0 - 1, C.k); c:set(x0 + 3 * h, y0, C.k) end
end
-- o: ox, oy, hx, hy, head, body, legs, by (body drop),
--    hand = {x, y} front hand (figure coords), armFrom = {x, y},
--    cane = {x0, y0, x1, y1[, hook]} in figure coords or false, after = fn(c, X, Y) drawn last
local function fig(o)
  local c = K.canvas()
  local X, Y = OX + (o.ox or 0), OY + (o.oy or 0)
  if o.before then o.before(c, X, Y) end
  local body = o.body or BODY.idle
  K.put(c, o.legs or LEGS.stand, X, Y + 14)
  K.put(c, body, X, Y + 13 - body.h + 1 + (o.by or 0))
  K.put(c, o.head or HEAD, X + 2 + (o.hx or 0), Y + (o.hy or 0))
  local cn = o.cane
  if cn == nil then cn = { 13, 10, 13, 15 } end
  if cn then cane(c, X + cn[1], Y + cn[2], X + cn[3], Y + cn[4], cn[5]) end
  local hand = o.hand or { 12, 10 }
  local from = o.armFrom or { 9, 10 }
  c:line(X + from[1], Y + from[2], X + hand[1] - (hand[1] >= from[1] and 1 or -1), Y + hand[2], C.d)
  c:set(X + hand[1], Y + hand[2], C.s)
  if o.after then o.after(c, X, Y) end
  return c
end

-- lantern glow: two flat discs (warm rim, pale core) behind the figure, plus twinkles
local function glow(c, cx, cy, r, k)
  c:ell(cx, cy, r, r, C.y)
  if r >= 5 then c:ell(cx, cy, r - 3, r - 3, C.Y) end
  if r >= 5 then
    local d = r + 2
    local pts = (k % 2 == 0) and { { 0, -d }, { d, 0 }, { -d + 1, 2 }, { 1, d - 1 } }
                               or { { d - 1, -d + 2 }, { d - 1, d - 2 }, { -d + 2, -d + 3 } }
    for _, q in ipairs(pts) do K.sparkle(c, cx + q[1], cy + q[2], MARK, k % 2 == 0 and 1 or 0) end
  end
end

------------------------------------------------------------------ animation
local function draw(tag, i)
  if tag == "idle" then
    local P = {
      { },
      { hy = 1, body = BODY.idle2, hand = { 12, 11 }, cane = { 13, 11, 13, 15 } },
      { hy = 1, body = BODY.idle, head = HEAD_BLINK, hand = { 12, 11 }, cane = { 13, 11, 13, 15 } },
      { hx = 1, legs = LEGS.stand, hand = { 12, 10 } },
    }
    return fig(P[i + 1])
  end

  if tag == "run" then
    -- hobbling shuffle: the cane plants ahead, then she catches up with it
    local P = {
      { hx = 1, body = BODY.hunch, legs = LEGS.r1, hand = { 13, 10 }, armFrom = { 10, 10 }, cane = { 14, 10, 16, 15 } },
      { hx = 1, oy = -1, body = BODY.hunch, legs = LEGS.r2, hand = { 13, 10 }, armFrom = { 10, 10 }, cane = { 14, 10, 14, 14 } },
      { hx = 1, body = BODY.hunch, legs = LEGS.r3, hand = { 12, 10 }, armFrom = { 9, 10 }, cane = { 13, 10, 12, 15 } },
      { hx = 1, oy = -1, body = BODY.hunch, legs = LEGS.r4, hand = { 13, 10 }, armFrom = { 10, 10 }, cane = { 14, 10, 15, 14 } },
    }
    local c = fig(P[i + 1])
    if i == 0 or i == 2 then K.dust(c, OX + 3, 31, i) end
    return c
  end

  if tag == "attack" then
    -- cane up, spectacles flash, a hard thwack forward, then back on the cane
    local P = {
      { hx = -1, hy = 1, body = BODY.idle2, legs = LEGS.wide, armFrom = { 9, 10 }, hand = { 11, 11 },
        cane = { 12, 11, 15, 15, false } },
      { hy = -1, body = BODY.tall, legs = LEGS.wide, armFrom = { 11, 9 }, hand = { 15, 7 },
        cane = { 15, 6, 15, -2, false } },
      { hx = 1, head = HEAD_GLINT, body = BODY.hunch, legs = LEGS.wide, armFrom = { 10, 10 }, hand = { 15, 8 },
        cane = { 16, 7, 20, 2, false } },
      { hx = 2, head = HEAD_GLINT, body = BODY.hunch, legs = LEGS.wide, armFrom = { 10, 10 }, hand = { 15, 10 },
        cane = { 16, 10, 22, 12, false } },
      { hx = 1, body = BODY.hunch, legs = LEGS.wide, armFrom = { 10, 10 }, hand = { 14, 10 },
        cane = { 15, 10, 17, 15, false } },
      { body = BODY.idle2, hand = { 12, 11 }, cane = { 13, 11, 13, 15 } },
    }
    local c = fig(P[i + 1])
    local X, Y = OX, OY
    if i == 2 then
      c:curve(X + 16, Y - 3, X + 22, Y - 2, X + 23, Y + 5, MARK2)
    elseif i == 3 then
      c:curve(X + 20, Y + 1, X + 24, Y + 4, X + 23, Y + 10, MARK2)
      K.bang(c, X + 19, Y + 2)
    end
    return c
  end

  if tag == "special" then
    -- hooks the lantern on the cane, raises it, and the glow swells and pulses
    -- the cane is held by its foot with the handle up, so the lantern hangs off the curl
    local R = { 0, 3, 6, 8, 7, 8, 5, 3 }
    local UP = { 15, -4, 15, 6, -2 }
    local P = {
      { body = BODY.tall, hand = { 12, 10 }, cane = { 13, 10, 13, 15 } },
      { hy = -1, body = BODY.tall, legs = LEGS.wide, armFrom = { 11, 9 }, hand = { 15, 8 }, cane = { 15, -2, 15, 7, -2 } },
      { hy = -1, body = BODY.tall, legs = LEGS.wide, armFrom = { 11, 9 }, hand = { 15, 7 }, cane = UP },
      { hy = -1, body = BODY.tall, legs = LEGS.wide, armFrom = { 11, 9 }, hand = { 15, 7 }, cane = UP },
      { hy = -1, head = HEAD_BLINK, body = BODY.tall, legs = LEGS.wide, armFrom = { 11, 9 }, hand = { 15, 7 }, cane = UP },
      { hy = -1, body = BODY.tall, legs = LEGS.wide, armFrom = { 11, 9 }, hand = { 15, 7 }, cane = UP },
      { hy = -1, body = BODY.tall, legs = LEGS.wide, armFrom = { 11, 9 }, hand = { 15, 7 }, cane = UP },
      { body = BODY.idle2, hand = { 12, 11 }, cane = { 13, 11, 13, 15 } },
    }
    local p = P[i + 1]
    local cn = p.cane
    -- lantern ring hangs under the end of the curl
    local lx, ly = cn[1] - 4, cn[2] + 1
    if i == 0 or i == 7 then lx, ly = 14, i == 0 and 10 or 11 end
    local gx, gy = OX + lx + 1, OY + ly + 2
    p.before = function(c) if R[i + 1] > 0 then glow(c, gx, gy, R[i + 1], i) end end
    p.after = function(c) K.put(c, LANTERN, OX + lx, OY + ly) end
    return fig(p)
  end

  local HURT = { hx = -1, hy = 1, head = HEAD_HURT, body = BODY.tall, legs = LEGS.wide, armFrom = { 9, 10 }, hand = { 12, 8 },
                 cane = { 13, 8, 15, 14, false } }
  if tag == "hit" then
    if i == 0 then return K.flashOf(fig(HURT)) end
    if i == 3 then return fig({ hy = 1, body = BODY.idle2, hand = { 12, 11 }, cane = { 13, 11, 13, 15 } }) end
    local s = i - 1
    local c = fig({ ox = -1 - s, hx = -1 - s, hy = 1, head = HEAD_HURT, body = BODY.tall, legs = LEGS.wide,
                    armFrom = { 9, 10 }, hand = { 12, 8 + s }, cane = { 13, 8 + s, 15 + s, 14, false } })
    K.bang(c, OX + 14 - s, OY - 2 + s)
    return c
  end

  if tag == "death" then
    if i == 0 then
      local c = fig(HURT); K.bang(c, OX + 15, OY - 2); return c
    end
    if i == 1 then   -- knees give, cane slips forward
      return fig({ hx = 1, hy = 3, by = 1, head = HEAD_HURT, body = BODY.hunch, legs = LEGS.kneel,
                   armFrom = { 10, 12 }, hand = { 14, 12 }, cane = { 15, 12, 19, 15, false } })
    end
    if i == 2 then   -- toppling forward
      return fig({ ox = 1, hx = 3, hy = 6, by = 2, head = HEAD_HURT, body = BODY.hunch, legs = LEGS.kneel,
                   armFrom = { 10, 13 }, hand = { 15, 14 }, cane = { 15, 15, 20, 15, false } })
    end
    -- face down: dress hump on the left, head resting at the right, cane flat beside her
    local c = K.canvas()
    local dy = (i == 3) and -1 or 0
    c:line(18, 31, 26, 31, C.k); c:set(26, 30, C.k)
    K.foot(c, DOWN, 5, 31 + dy)
    K.foot(c, HEAD_HURT, 11, 31 + dy)
    if i == 3 then K.dust(c, 5, 31, 0); K.dust(c, 27, 30, 1) end
    if i >= 4 and i <= 6 then K.dizzy(c, 17, 16 - (i - 4), i) end
    return c
  end
end

return K.build("grandmother", draw)
