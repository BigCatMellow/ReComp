-- Standalone: luajit mods/critical_capture/tests/critical_capture_test.lua
-- Loads the mod through the real headless loader and asserts the OPTIONS
-- row ladder, the Gen 1-rescaled multiplier tiers, the modified-rate
-- proxy, the critical/decisive rolls, the catch.rate wrap wiring, the
-- crit toss anim swap and the whistle chip program.
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Runtime = require("src.mods.Runtime")
local Data = require("src.core.Data")
Data:load()

local run = T.sdk.loadMod("mods/critical_capture", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")
local ex = run.loader.exports.critical_capture
T.neq(ex, nil, "exports reachable")

-- ------------------------------------------------ the OPTIONS row

local function findRow(game)
  local rows = Runtime.call("ui.options.rows", function(_, r) return r end,
    game, { { id = "text_speed" } })
  for _, row in ipairs(rows) do
    if row.id == "critical_capture" then return row end
  end
  return nil
end

local written = 0
local game = {
  save = { options = {} },
  writeOptions = function(self)
    assert(type(self) == "table" and self.save ~= nil,
           "writeOptions must be called with a colon")
    written = written + 1
  end,
}

local row = findRow(game)
T.neq(row, nil, "the CRIT CAPTURE row joins the options menu")
T.eq(row.label, "CRIT CAPTURE", "row label")
T.eq(row.value(game), "GEN 5", "defaults to GEN 5")
T.eq(row.step(game, 1), true, "stepping right works")
T.eq(game.save.options.critCapture, "gen6", "GEN 5 cycles to GEN 6")
T.eq(row.value(game), "GEN 6", "GEN 6 label")
T.eq(row.step(game, 1), true, "step again")
T.eq(game.save.options.critCapture, "off", "GEN 6 cycles to OFF")
T.eq(row.value(game), "OFF", "OFF label")
T.eq(row.step(game, 1), true, "step again")
T.eq(game.save.options.critCapture, "gen5", "OFF cycles back to GEN 5")
T.eq(row.step(game, -1), true, "stepping left works")
T.eq(game.save.options.critCapture, "off", "GEN 5 left-cycles to OFF")
T.eq(written, 4, "each step persists via writeOptions")

game.save.options.critCapture = "bogus"
T.eq(ex.modeOf(game), "gen5", "a garbage value normalizes to GEN 5")
T.eq(ex.modeOf({}), "gen5", "no save still defaults to GEN 5")
T.eq(ex.modeOf(nil), "gen5", "no game still defaults to GEN 5")
T.eq(ex.cycle({}), nil, "no save -> nil (launcher is untouched)")
T.eq(ex.cycle({ save = {} }), nil, "no options table -> nil")

-- ------------------------------------------------ the Pokedex scale

T.eq(ex.countOwned(nil), 0, "no save -> 0 species")
T.eq(ex.countOwned({}), 0, "no pokedex -> 0 species")
T.eq(ex.countOwned({ pokedex = { owned = {} } }), 0, "empty dex -> 0")
T.eq(ex.countOwned({ pokedex = { owned = { BULBASAUR = true,
                                          IVYSAUR = true } } }), 2,
  "owned counts the species keys")

-- the Gen 1 rescale of Gen 5's tiers, split into quarter steps: 151
-- replaces 600, each band is ~15 species, and a fresh dex starts at 0
T.eq(ex.multiplierFor(0), 0, "0-15 caught: no critical captures")
T.eq(ex.multiplierFor(15), 0, "tier floor at 15")
T.eq(ex.multiplierFor(16), 0.25, "16-30 caught: 0.25x")
T.eq(ex.multiplierFor(30), 0.25, "tier floor at 30")
T.eq(ex.multiplierFor(31), 0.5, "31-45 caught: 0.5x")
T.eq(ex.multiplierFor(45), 0.5, "tier floor at 45")
T.eq(ex.multiplierFor(46), 0.75, "46-60 caught: 0.75x")
T.eq(ex.multiplierFor(60), 0.75, "tier floor at 60")
T.eq(ex.multiplierFor(61), 1, "61-75 caught: 1x")
T.eq(ex.multiplierFor(75), 1, "tier floor at 75")
T.eq(ex.multiplierFor(76), 1.25, "76-90 caught: 1.25x")
T.eq(ex.multiplierFor(90), 1.25, "tier floor at 90")
T.eq(ex.multiplierFor(91), 1.5, "91-105 caught: 1.5x")
T.eq(ex.multiplierFor(105), 1.5, "tier floor at 105")
T.eq(ex.multiplierFor(106), 1.75, "106-120 caught: 1.75x")
T.eq(ex.multiplierFor(120), 1.75, "tier floor at 120")
T.eq(ex.multiplierFor(121), 2, "121-135 caught: 2x")
T.eq(ex.multiplierFor(135), 2, "tier floor at 135")
T.eq(ex.multiplierFor(136), 2.25, "136-150 caught: 2.25x")
T.eq(ex.multiplierFor(150), 2.25, "tier floor at 150")
T.eq(ex.multiplierFor(151), 2.5, "the complete dex keeps Gen 5's 2.5x")

-- ------------------------------------------------ the modified-rate proxy

-- POKE_BALL (randMax 255, hpFactor 12), rate 20, full HP, no status:
-- p1 = 21/256, f = floor(floor(10*255/12)/2) = 106, p2 = 107/256,
-- a = 255 * (1 - (235/256)(149/256)) -- every intermediate is an exact
-- binary fraction, so the comparison is exact
local pokeball = { randMax = 255, hpFactor = 12 }
local mon10 = { hp = 10, stats = { hp = 10 } }
T.eq(ex.modifiedRateA(pokeball, mon10, { catchRate = 20 }, nil, {}),
  255 * (1 - (1 - 21 / 256) * (1 - 107 / 256)),
  "a tracks the two-roll probability scaled to 0-255")
T.eq(ex.modifiedRateA(nil, mon10, { catchRate = 20 }, nil, {}),
  255 * (1 - (1 - 21 / 256) * (1 - 107 / 256)),
  "a nil ball def falls back to the POKE_BALL roll")
T.eq(ex.modifiedRateA(pokeball, mon10, { catchRate = 255 }, nil, {}), 255,
  "a guaranteed rate caps a at 255")
T.eq(ex.modifiedRateA({ autoCatch = true }, mon10, { catchRate = 20 }, nil, {}),
  255, "an auto-catch ball reads 255")
T.eq(ex.modifiedRateA(pokeball, mon10, { catchRate = 20 }, nil,
  { SLP = { catchBonus = 25 } }),
  255 * (1 - (1 - 21 / 256) * (1 - 107 / 256)),
  "a status table alone adds no bonus to a healthy mon")
T.eq(ex.modifiedRateA(pokeball, { hp = 10, stats = { hp = 10 },
  status = "SLP" }, { catchRate = 20 }, nil, { SLP = { catchBonus = 25 } }),
  255 * (1 - (1 - 46 / 256) * (1 - 107 / 256)),
  "a statused mon gets the sleep bonus")
T.eq(ex.modifiedRateA(pokeball, { hp = 10, stats = { hp = 10 },
  status = "BRN" }, { catchRate = 20 }, nil, { BRN = { catchBonus = 12 } }),
  255 * (1 - (1 - 33 / 256) * (1 - 107 / 256)),
  "a paralyzed mon gets the smaller paralysis bonus")
T.eq(ex.modifiedRateA(pokeball, { hp = 4, stats = { hp = 10 } },
  { catchRate = 20 }, nil, {}),
  255 * (1 - (1 - 21 / 256) * (1 - 213 / 256)),
  "a wounded mon's HP roll scales a up")
T.eq(ex.modifiedRateA(pokeball, mon10, { catchRate = 20 }, 150, {}),
  255 * (1 - (1 - 151 / 256) * (1 - 107 / 256)),
  "the safari rateOverride replaces the species rate")

-- ------------------------------------------------ the critical roll

T.eq(ex.rollCritical(T.rng.seq(0), 255, 2.5), true, "c=106, roll 0 is critical")
T.eq(ex.rollCritical(T.rng.seq(105), 255, 2.5), true, "roll 105 < 106 is critical")
T.eq(ex.rollCritical(T.rng.seq(106), 255, 2.5), false, "roll 106 is not critical")
T.eq(ex.rollCritical(T.rng.seq(20), 255, 0.5), true, "c=21 with a 0.5x multiplier")
T.eq(ex.rollCritical(T.rng.seq(21), 255, 0.5), false, "roll 21 is not critical")
T.eq(ex.rollCritical(T.rng.seq(0), 0, 2.5), false, "a 0 never rolls critical")
T.eq(ex.rollCritical(T.rng.seq(0), 255, 0), false, "a 0x tier never rolls critical")

-- ------------------------------------------------ the decisive shake

T.eq(ex.decisiveRoll(T.rng.seq(255), 1, 3), true, "a guaranteed catch stays caught")
T.eq(ex.decisiveRoll(T.rng.seq(127), 0.125, 3), true, "0.125^1/3 = 0.5, t=127")
T.eq(ex.decisiveRoll(T.rng.seq(128), 0.125, 3), false, "roll 128 misses t=127")
T.eq(ex.decisiveRoll(T.rng.seq(127), 0.0625, 4), true, "0.0625^1/4 = 0.5, t=127")
T.eq(ex.decisiveRoll(T.rng.seq(202), 0.5, 3), true, "0.5^1/3, t=202")
T.eq(ex.decisiveRoll(T.rng.seq(203), 0.5, 3), false, "roll 203 misses t=202")

-- ------------------------------------------------ the catch.rate wrap

local queuedWhistles = {}
local function stubBattle(owned, balls, mode)
  local b = {
    critToss = false,
    data = {
      balls = balls or { POKE_BALL = { randMax = 255, hpFactor = 12 } },
      statuses = {},
    },
    game = { save = { pokedex = { owned = owned or {} },
                      options = mode and { critCapture = mode } or {} } },
  }
  -- mirrors BattleState:ballDef (data.balls over Catching.BALLS)
  b.ballDef = function(self, id) return (self.data.balls or {})[id] end
  b.actNext = function(_, fn) queuedWhistles[#queuedWhistles + 1] = fn end
  return b
end

local function owned151()
  local t = {}
  for i = 1, 151 do t["MON" .. i] = true end
  return t
end

local vanillaCalls = 0
local function vanillaFn()
  vanillaCalls = vanillaCalls + 1
  return false, 2
end

do
  -- a critical throw replaces the vanilla roll: one decisive shake, the
  -- battle flagged for the crit toss, the whistle queued for the toss
  queuedWhistles = {}
  local b = stubBattle(owned151())
  local caught, shakes = Runtime.call("catch.rate", vanillaFn, "POKE_BALL",
    mon10, { catchRate = 255 },
    { rng = T.rng.seq(0, 0), battle = b })
  T.eq(vanillaCalls, 0, "a critical capture never runs the vanilla roll")
  T.eq(caught, true, "the decisive shake catches at a=255")
  T.eq(shakes, 1, "a critical capture shows one shake")
  T.eq(b.critToss, true, "the battle is flagged for the crit toss anim")
  T.eq(#queuedWhistles, 1, "the whistle is queued behind the throw")
  queuedWhistles[1]() -- headless: love.audio is stubbed, no-op
end

do
  -- the decisive shake can fail: one shake, then a breakout
  local b = stubBattle(owned151())
  local caught, shakes = Runtime.call("catch.rate", vanillaFn, "POKE_BALL",
    mon10, { catchRate = 255 },
    { rng = T.rng.seq(0, 300), battle = b })
  T.eq(vanillaCalls, 0, "a failed critical shake still skips the vanilla roll")
  T.eq(caught, false, "the decisive shake can break free")
  T.eq(shakes, 1, "a failed critical capture breaks after one shake")
end

do
  -- a non-critical throw defers to the vanilla roll and resets the flag
  local b = stubBattle(owned151())
  b.critToss = true
  local caught, shakes = Runtime.call("catch.rate", vanillaFn, "POKE_BALL",
    mon10, { catchRate = 255 },
    { rng = T.rng.seq(106), battle = b })
  T.eq(vanillaCalls, 1, "a non-critical throw runs the vanilla roll")
  T.eq(caught, false, "the vanilla outcome stands")
  T.eq(shakes, 2, "the vanilla shake count stands")
  T.eq(b.critToss, false, "the crit flag resets on a normal throw")
end

do
  -- Master Ball never rolls critical
  local b = stubBattle(owned151(), { MASTER_BALL = { autoCatch = true } })
  local caught = Runtime.call("catch.rate", vanillaFn, "MASTER_BALL",
    mon10, { catchRate = 255 },
    { rng = T.rng.seq(0), battle = b })
  T.eq(vanillaCalls, 2, "an auto-catch ball defers to the vanilla roll")
  T.eq(caught, false, "the vanilla outcome stands for the Master Ball")
end

do
  -- an empty dex (multiplier 0) never rolls critical
  local b = stubBattle({})
  local caught = Runtime.call("catch.rate", vanillaFn, "POKE_BALL",
    mon10, { catchRate = 255 },
    { rng = T.rng.seq(0), battle = b })
  T.eq(vanillaCalls, 3, "a 0x dex defers to the vanilla roll")
  T.eq(caught, false, "the vanilla outcome stands for an empty dex")
end

do
  -- OFF restores vanilla exactly
  local b = stubBattle(owned151(), nil, "off")
  b.critToss = true
  local caught = Runtime.call("catch.rate", vanillaFn, "POKE_BALL",
    mon10, { catchRate = 255 },
    { rng = T.rng.seq(0), battle = b })
  T.eq(vanillaCalls, 4, "OFF defers to the vanilla roll")
  T.eq(caught, false, "the vanilla outcome stands in OFF")
  T.eq(b.critToss, false, "OFF resets the crit flag too")
end

do
  -- GEN 6 uses the fourth root for the decisive shake
  local b = stubBattle(owned151(), nil, "gen6")
  local caught, shakes = Runtime.call("catch.rate", vanillaFn, "POKE_BALL",
    mon10, { catchRate = 255 },
    { rng = T.rng.seq(0, 0), battle = b })
  T.eq(vanillaCalls, 4, "GEN 6 rolls critical without the vanilla roll")
  T.eq(caught, true, "GEN 6 decisive shake catches at a=255")
  T.eq(shakes, 1, "GEN 6 critical still shakes once")
end

-- ------------------------------------------------ the crit toss anim

-- the tossAnimFor swap installs on game.ready (the nuzlocke pattern)
run.loader.events:emit("game.ready", { game = {} })
local BattleState = require("src.battle.BattleState")

local fake = {
  critToss = true,
  animationsOn = function() return true end,
  ballDef = function() return { tossAnim = "TOSS_ANIM" } end,
}
T.eq(BattleState.tossAnimFor(fake, "POKE_BALL"), "CRIT_TOSS_ANIM",
  "a critical throw takes the crit toss arc")
fake.ballDef = function() return { tossAnim = "GREATTOSS_ANIM" } end
T.eq(BattleState.tossAnimFor(fake, "GREAT_BALL"), "CRIT_GREATTOSS_ANIM",
  "the Great Ball crit arc")
fake.ballDef = function() return { tossAnim = "ULTRATOSS_ANIM" } end
T.eq(BattleState.tossAnimFor(fake, "ULTRA_BALL"), "CRIT_ULTRATOSS_ANIM",
  "the Ultra Ball crit arc")
fake.critToss = false
T.eq(BattleState.tossAnimFor(fake, "ULTRA_BALL"), "ULTRATOSS_ANIM",
  "a normal throw keeps the vanilla arc")
fake.critToss = true
fake.animationsOn = function() return false end
T.eq(BattleState.tossAnimFor(fake, "ULTRA_BALL"), "ULTRATOSS_ANIM",
  "battle animations off keep the vanilla arc (BALL_ANIMS gating)")

-- ------------------------------------------------ registries

local whistle = run.loader.content.sfx:get("SFX_CRIT_WHISTLE")
T.neq(whistle, nil, "the whistle sfx is registered")
T.eq(type(whistle.chip.blob), "string", "the whistle is an authored chip program")
T.eq(type(whistle.chip.channels), "table", "the chip program has channels")

local toss = run.loader.content.battle_anims:get("CRIT_TOSS_ANIM")
T.neq(toss, nil, "CRIT_TOSS_ANIM is registered")
T.eq(#toss.seq, 1, "the crit toss is one row")
T.eq(toss.seq[1].subanim, 601, "the Poke crit toss routes to subanim 601")
T.eq(run.loader.content.battle_anims:get("CRIT_GREATTOSS_ANIM").seq[1].subanim,
  602, "the Great crit toss routes to subanim 602")
T.eq(run.loader.content.battle_anims:get("CRIT_ULTRATOSS_ANIM").seq[1].subanim,
  603, "the Ultra crit toss routes to subanim 603")

local sub = run.loader.content.battle_anims:get("subanim:601")
T.neq(sub, nil, "subanim 601 is registered")
T.eq(#sub.blocks, 17, "11 arc blocks + 6 apex repeats")
T.eq(sub.blocks[7].coord, 51, "the shudder splices in at the apex")
T.eq(sub.blocks[9].coord, 14, "the apex triplet ends block 9")
T.eq(sub.blocks[10].coord, 51, "the apex triplet replays")
T.eq(sub.blocks[15].coord, 14, "the third apex pass")
T.eq(sub.blocks[16].coord, 169, "the descent resumes")
T.eq(sub.blocks[17].coord, 52, "the ball lands at the ground coord")
T.eq(sub.type, "NORMAL", "the crit arc plays untransformed")

run.release()
T.finish("critical_capture")
