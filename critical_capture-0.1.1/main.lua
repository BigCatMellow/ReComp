-- Critical Capture: Gen 5's critical capture adapted to the Gen 1 catch
-- algorithm.  A thrown ball can go critical -- a rising whistle, a mid-air
-- pause and shudder, then a single decisive shake that is far more likely
-- to catch than the vanilla three-wobble check, exactly like the modern
-- games' one-shake critical capture.
--
-- Faithful to Bulbapedia's Gen 5 model, with the one adaptation Gen 1
-- forces: the modern games scale the critical chance off the modified
-- catch rate a, which this engine's two-roll algorithm never computes.
-- The mod uses the exact Gen 1 catch probability of the throw (the rate
-- roll and the HP roll combined) scaled to a 0-255 a value.  The critical
-- chance is then c = floor(a * multiplier / 6), rolled as rng(0,255) < c,
-- and a critical capture's single decisive shake succeeds with the normal
-- catch chance raised to 1/root: 1/3 for GEN 5, 1/4 for GEN 6.
--
-- The multiplier table is Gen 5's rescaled from its 600+ species dex to
-- Gen 1's 151 (each tier spans ~25 species): a completed dex keeps the
-- full 2.5x ceiling, a new game starts at 0.

-- species-caught tiers, top first; 151 is the complete Gen 1 dex.  Gen
-- 5's six tiers rescaled to the 151-species dex, then split into a
-- quarter-step ladder (0.25 .. 2.5): each band is ~15 species wide
local TIERS = {
  { min = 151, multiplier = 2.5 },
  { min = 136, multiplier = 2.25 },
  { min = 121, multiplier = 2 },
  { min = 106, multiplier = 1.75 },
  { min = 91,  multiplier = 1.5 },
  { min = 76,  multiplier = 1.25 },
  { min = 61,  multiplier = 1 },
  { min = 46,  multiplier = 0.75 },
  { min = 31,  multiplier = 0.5 },
  { min = 16,  multiplier = 0.25 },
  { min = 0,   multiplier = 0 },
}

-- the OPTIONS row ladder; GEN 5 is the default (the mod is on out of
-- the box), GEN 6 uses the fourth root, OFF restores vanilla exactly
local ORDER = { "gen5", "gen6", "off" }
local LABELS = { gen5 = "GEN 5", gen6 = "GEN 6", off = "OFF" }
local ROOTS = { gen5 = 3, gen6 = 4 }

-- the crit toss arcs: the tier's vanilla arc with the apex triplet
-- repeated, so the ball pauses and shudders at the top of its throw
-- (subanim blocks are the ball sprite at the arc's baseCoords)
local TOSS_COORDS = {
  POKE_BALL   = { 48, 162, 147, 97, 115, 167, 51, 168, 14, 169, 52 },
  GREAT_BALL  = { 48, 162, 49, 163, 50, 164, 146, 165, 21, 166, 52 },
  ULTRA_BALL  = { 48, 68, 148, 96, 118, 159, 141, 160, 26, 161, 52 },
}
-- the three apex blocks of each arc, replayed twice more for the shudder
local APEX = {
  POKE_BALL  = { 51, 168, 14 },
  GREAT_BALL = { 146, 165, 21 },
  ULTRA_BALL = { 141, 160, 26 },
}
local CRIT_ANIMS = {
  TOSS_ANIM = "CRIT_TOSS_ANIM", GREATTOSS_ANIM = "CRIT_GREATTOSS_ANIM",
  ULTRATOSS_ANIM = "CRIT_ULTRATOSS_ANIM",
}
-- the ball tiers: the subanim index (601-603) and the vanilla toss anim
-- each crit arc replaces (one entry per ball, so the tiers never drift)
local BALL_TIERS = {
  POKE_BALL  = { sub = 601, toss = "TOSS_ANIM" },
  GREAT_BALL = { sub = 602, toss = "GREATTOSS_ANIM" },
  ULTRA_BALL = { sub = 603, toss = "ULTRATOSS_ANIM" },
}

local api = {}

-- normalized mode: nil / garbage -> "gen5" (the mod's default state)
function api.modeOf(game)
  local options = game and game.save and game.save.options
  local mode = options and options.critCapture
  if mode == "gen6" or mode == "off" then return mode end
  return "gen5"
end

-- the row's step body: LEFT/RIGHT cycle GEN 5 -> GEN 6 -> OFF -> GEN 5.
-- Returns nil when there is no save (the launcher's stub games), so the
-- row stays inert there like every other options row.
function api.cycle(game, dir)
  local options = game and game.save and game.save.options
  if not options then return nil end
  local i = 1
  for idx, mode in ipairs(ORDER) do
    if mode == api.modeOf(game) then i = idx break end
  end
  local nextMode = ORDER[((i - 1 + (dir or 1)) % #ORDER) + 1]
  options.critCapture = nextMode
  if game.writeOptions then game:writeOptions() end
  return nextMode
end

function api.labelOf(game)
  return LABELS[api.modeOf(game)]
end

-- the number of species registered as owned in the Pokedex
function api.countOwned(save)
  local dex = save and save.pokedex
  local owned = dex and dex.owned or {}
  local n = 0
  for _ in pairs(owned) do n = n + 1 end
  return n
end

-- Gen 5's critical-capture multiplier, rescaled to the 151-species dex
function api.multiplierFor(owned)
  for _, tier in ipairs(TIERS) do
    if owned >= tier.min then return tier.multiplier end
  end
  return 0
end

-- The modified catch rate proxy a (0-255): the exact probability of the
-- Gen 1 two-roll algorithm -- the status-subtracted rate roll
-- (rng(0,randMax) - statusBonus <= rate) and the HP roll (rng(0,255) <= f)
-- -- scaled to 0-255.  Mirrors stockAttempt's math so the critical chance
-- tracks the real odds of the throw.  statuses is the merged statuses
-- table ({ SLP = { catchBonus = 25 }, ... }).
function api.modifiedRateA(ballDef, mon, def, rateOverride, statuses)
  if ballDef and ballDef.autoCatch then return 255 end
  local randMax = ballDef and ballDef.randMax or 255
  local hpFactor = ballDef and ballDef.hpFactor or 12
  local rate = rateOverride or (def and def.catchRate) or 0
  local statusBonus = 0
  if statuses and mon and mon.status then
    local record = statuses[mon.status]
    statusBonus = (record and record.catchBonus) or 0
  end
  local maxhp = (mon and mon.stats and mon.stats.hp) or 1
  local hpQuarter = math.max(1, math.floor((mon and mon.hp or maxhp) / 4))
  local f = math.min(255, math.floor(math.floor(maxhp * 255 / hpFactor) / hpQuarter))
  local p1 = math.min(1, (rate + statusBonus + 1) / (randMax + 1))
  local p2 = (f + 1) / 256
  return (1 - (1 - p1) * (1 - p2)) * 255
end

-- Gen 5's critical roll: c = floor(a * multiplier / 6); critical when
-- rng(0,255) < c.  A 0 multiplier never rolls.
function api.rollCritical(rng, a, multiplier)
  local c = math.floor(a * multiplier / 6)
  if c <= 0 then return false end
  return rng(0, 255) < c
end

-- The single decisive shake of a critical capture: succeeds with the
-- normal catch chance raised to 1/root (the cube root in Gen 5, the
-- fourth root in Gen 6).  A guaranteed catch (prob 1) always passes.
function api.decisiveRoll(rng, prob, root)
  local t = math.floor(255 * prob ^ (1 / root))
  return rng(0, 255) <= t
end

return function(mod)
  -- the pure resolution layer, exported for tests and other mods
  mod.exports.modeOf = api.modeOf
  mod.exports.cycle = api.cycle
  mod.exports.labelOf = api.labelOf
  mod.exports.countOwned = api.countOwned
  mod.exports.multiplierFor = api.multiplierFor
  mod.exports.modifiedRateA = api.modifiedRateA
  mod.exports.rollCritical = api.rollCritical
  mod.exports.decisiveRoll = api.decisiveRoll

  -- the whistle: an authored ChipAsm chip program in its own file,
  -- loaded via mod:read so it works the same installed as in the repo
  local source = mod:read("sfx.lua")
  if not source then
    mod.log:error("sfx.lua missing from %s -- reinstall the mod", mod.path)
    return
  end
  local chunk, compileErr = load(source, "@" .. mod.path .. "/sfx.lua")
  if not chunk then
    mod.log:error("sfx.lua did not compile: %s", tostring(compileErr))
    return
  end
  local ok, whistle = pcall(chunk)
  if not ok then
    mod.log:error("sfx.lua failed to assemble: %s", tostring(whistle))
    return
  end

  mod.content.sfx:register("SFX_CRIT_WHISTLE", whistle)

  -- the crit toss arcs: one subanim per ball tier (601-603) holding the
  -- vanilla arc with the apex triplet replayed, and one move anim per
  -- tier routing to it
  for ball, tier in pairs(BALL_TIERS) do
    local arc = {}
    for _, coord in ipairs(TOSS_COORDS[ball]) do
      arc[#arc + 1] = { block = 3, coord = coord, mode = 0 }
    end
    local apex = APEX[ball]
    local shudder = {}
    for _ = 1, 2 do
      for _, coord in ipairs(apex) do
        shudder[#shudder + 1] = { block = 3, coord = coord, mode = 0 }
      end
    end
    -- splice the shudder into the arc right where the ball reaches its
    -- apex (after the first two thirds of the throw)
    local insertAt = math.floor(#arc * 2 / 3)
    for i, block in ipairs(shudder) do
      table.insert(arc, insertAt + i - 1, block)
    end
    mod.content.battle_anims:register("subanim:" .. tier.sub, {
      blocks = arc, type = "NORMAL",
    })
    mod.content.battle_anims:register(CRIT_ANIMS[tier.toss], {
      seq = { { delay = 4, subanim = tier.sub, tileset = 0 } },
    })
  end

  -- the OPTIONS row; next() first keeps every other mod's rows
  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) ~= "table" then return out end
    out[#out + 1] = {
      id = "critical_capture",
      label = "CRIT CAPTURE",
      value = function(g) return api.labelOf(g) end,
      step = function(g, dir)
        return api.cycle(g, dir) ~= nil
      end,
    }
    return out
  end)

  -- catch.rate is the single choke point every ball roll passes through
  -- (wild throws and the Safari game alike; the old man's scripted catch
  -- demo never reaches it).  A critical throw replaces the vanilla
  -- outcome with the decisive single shake; everything else defers.
  mod.hooks:wrap("catch.rate", function(nextFn, ball, mon, def, o)
    local battle = o and o.battle
    if battle then battle.critToss = false end
    local mode = api.modeOf(battle and battle.game)
    if mode == "off" or not battle then return nextFn(ball, mon, def, o) end
    local data = battle.data
    -- battle:ballDef is the engine's own merged lookup (data.balls over
    -- Catching.BALLS), so the crit chance sees the same record as the roll
    local ballDef = battle:ballDef(ball)
    if ballDef and ballDef.autoCatch then return nextFn(ball, mon, def, o) end
    local multiplier = api.multiplierFor(
      api.countOwned(battle.game and battle.game.save))
    if multiplier <= 0 then return nextFn(ball, mon, def, o) end
    local a = api.modifiedRateA(ballDef, mon, def, o.rateOverride,
                                data and data.statuses)
    if not api.rollCritical(o.rng, a, multiplier) then
      return nextFn(ball, mon, def, o)
    end
    -- a critical capture: the whistle lands as the toss begins (the
    -- actNext slot plays right before the toss animation row), the ball
    -- takes the crit arc, and one decisive shake decides the catch
    battle.critToss = true
    if battle.actNext then
      battle:actNext(function()
        require("src.core.Sound").play(data, "SFX_CRIT_WHISTLE")
      end)
    end
    local caught = api.decisiveRoll(o.rng, a / 255, ROOTS[mode])
    return caught, 1
  end)

  -- the crit arcs route through BattleState:tossAnimFor; swap in the
  -- CRIT_* anim for a flagged throw (vanilla toss when battle animations
  -- are off -- BALL_ANIMS only lists the vanilla ids)
  mod.events:on("game.ready", function()
    local BattleState = require("src.battle.BattleState")
    local vanilla = BattleState.tossAnimFor
    BattleState.tossAnimFor = function(self, ball)
      if self.critToss and self:animationsOn() then
        local tier = vanilla(self, ball)
        return CRIT_ANIMS[tier] or tier
      end
      return vanilla(self, ball)
    end
  end)
end
