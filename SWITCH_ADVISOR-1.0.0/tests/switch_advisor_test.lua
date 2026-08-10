-- Standalone: luajit mods/SWITCH_ADVISOR/tests/switch_advisor_test.lua
--
-- Loads SWITCH_ADVISOR through the real headless loader against the
-- ROM-free fixture dataset, then drives the pure decision functions the
-- mod publishes on mod.exports.
--
-- Two stated effects, two halves of the suite:
--
--   1. PARTY GRADES  markerFor / markersFor turn "this party member vs the
--      foe that is on the field" into the two-glyph marker the party row
--      draws.  Every case below is a hand-built view, so no graphics
--      context and no live BattleState are involved.
--   2. SKIP NICKNAME  the BattleState.askNicknameUI wrap really is
--      installed by the load, and the stand-in state it hands back pops
--      itself and settles the two battle flags the vanilla prompt owns.
--
-- WHY THIS FILE CARRIES ITS OWN TYPE CHART
--
-- tests/fixture_data/type_chart.lua is only the GRASS/FIRE/WATER triangle,
-- which cannot express "Pikachu against a Butterfree".  The grades this
-- mod exists to print are Gen 1 grades, so the suite loads the real Gen 1
-- TypeEffects pairs (below) into src.battle.TypeChart and asserts against
-- matchups a player can check in-game.  The engine's own chart file is
-- generated from the player's ROM and is absent in a clean checkout, which
-- is exactly why it is restated here rather than required.
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local Data = T.fixtures.fresh()

-- ------------------------------------------------------------ the type chart
--
-- Gen 1 TypeEffects, as x10 multipliers, keyed by attacker.  Row order does
-- not matter here: TypeChart.effectiveness indexes by [attacker][defender].
-- PSYCHIC's engine id is PSYCHIC_TYPE.
local GEN1 = {
  NORMAL       = { ROCK = 5, GHOST = 0 },
  FIGHTING     = { NORMAL = 20, ROCK = 20, ICE = 20,
                   POISON = 5, FLYING = 5, PSYCHIC_TYPE = 5, BUG = 5, GHOST = 0 },
  FLYING       = { FIGHTING = 20, BUG = 20, GRASS = 20, ROCK = 5, ELECTRIC = 5 },
  POISON       = { GRASS = 20, BUG = 20,
                   POISON = 5, GROUND = 5, ROCK = 5, GHOST = 5 },
  GROUND       = { FIRE = 20, ELECTRIC = 20, POISON = 20, ROCK = 20,
                   GRASS = 5, BUG = 5, FLYING = 0 },
  ROCK         = { FIRE = 20, ICE = 20, FLYING = 20, BUG = 20,
                   FIGHTING = 5, GROUND = 5 },
  BUG          = { GRASS = 20, POISON = 20, PSYCHIC_TYPE = 20,
                   FIRE = 5, FIGHTING = 5, FLYING = 5, GHOST = 5 },
  GHOST        = { GHOST = 20, NORMAL = 0, PSYCHIC_TYPE = 0 },
  FIRE         = { GRASS = 20, ICE = 20, BUG = 20,
                   FIRE = 5, WATER = 5, ROCK = 5, DRAGON = 5 },
  WATER        = { FIRE = 20, GROUND = 20, ROCK = 20,
                   WATER = 5, GRASS = 5, DRAGON = 5 },
  GRASS        = { WATER = 20, GROUND = 20, ROCK = 20,
                   FIRE = 5, GRASS = 5, POISON = 5, FLYING = 5, BUG = 5, DRAGON = 5 },
  ELECTRIC     = { WATER = 20, FLYING = 20,
                   ELECTRIC = 5, GRASS = 5, DRAGON = 5, GROUND = 0 },
  PSYCHIC_TYPE = { FIGHTING = 20, POISON = 20, PSYCHIC_TYPE = 5 },
  ICE          = { GRASS = 20, GROUND = 20, FLYING = 20, DRAGON = 20,
                   WATER = 5, ICE = 5 },
  DRAGON       = { DRAGON = 20 },
}

local matchups = {}
for attacker, row in pairs(GEN1) do
  for defender, multiplier in pairs(row) do
    matchups[#matchups + 1] =
      { attacker = attacker, defender = defender, multiplier = multiplier }
  end
end
Data.type_chart = { matchups = matchups, types = nil }

local TypeChart = require("src.battle.TypeChart")
TypeChart.load(Data)
-- guard the guard: a silently unloaded chart would make every defensive
-- lookup read as an immunity and hand out straight As
T.eq(TypeChart.effectiveness("ELECTRIC", { "BUG", "FLYING" }), 20,
  "the suite's Gen 1 chart is live (ELECTRIC vs BUG/FLYING is 2x)")
T.eq(TypeChart.effectiveness("BUG", { "GRASS", "POISON" }), 40,
  "dual-type rows stack (BUG vs GRASS/POISON is 4x)")

-- ------------------------------------------------------------------- the mod

local run = T.sdk.loadMod("mods/SWITCH_ADVISOR", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")
T.eq(run.mod and run.mod.state, "loaded", "reached the loaded state")

local ex = run.loader.exports.SWITCH_ADVISOR
T.check(type(ex) == "table", "the mod publishes an exports table")
T.eq(ex.version, "1.0.0", "the exported version tracks the manifest")
for _, name in ipairs({ "offensePoints", "defensePoints", "grade",
                        "markerFor", "markersFor", "dismissNickname",
                        "enabled" }) do
  T.check(type(ex[name]) == "function", name .. " is published")
end

-- ------------------------------------------------------------ the move bench
--
-- A move registry of the shape markerFor takes: id -> { type, power }.
-- Powers are the vanilla ones; only `type` and `power > 0` are read.
local MOVES = {
  TACKLE       = { type = "NORMAL",   power = 35 },
  QUICK_ATTACK = { type = "NORMAL",   power = 40 },
  SCRATCH      = { type = "NORMAL",   power = 40 },
  THUNDERSHOCK = { type = "ELECTRIC", power = 40 },
  LOW_KICK     = { type = "FIGHTING", power = 50 },
  KARATE_CHOP  = { type = "NORMAL",   power = 50 }, -- NORMAL in Gen 1
  VINE_WHIP    = { type = "GRASS",    power = 35 },
  LEECH_LIFE   = { type = "BUG",      power = 20 },
  EMBER        = { type = "FIRE",     power = 40 },
  LICK         = { type = "GHOST",    power = 20 },
  -- status moves: power 0, so the damage formula never runs for them
  GROWL        = { type = "NORMAL",   power = 0 },
  LEER         = { type = "NORMAL",   power = 0 },
  SLEEP_POWDER = { type = "GRASS",    power = 0 },
  STUN_SPORE   = { type = "GRASS",    power = 0 },
  POISONPOWDER = { type = "POISON",   power = 0 },
  -- a FIRE status move, to prove a super-effective status move is still
  -- worth nothing offensively
  WILL_O_STATUS = { type = "FIRE",    power = 0 },
}

local function slots(...)
  local out = {}
  for _, id in ipairs({ ... }) do out[#out + 1] = { id = id } end
  return out
end

-- one party candidate against one foe, with the danger flag on and the
-- move bench wired unless a case says otherwise.  `noRegistry` is how a
-- case asks for a view with no moves_data at all, which a plain nil
-- cannot express here.
local function marker(view)
  if view.danger == nil then view.danger = true end
  if view.hp == nil then view.hp = 20 end
  if view.moves_data == nil and not view.noRegistry then
    view.moves_data = MOVES
  end
  return ex.markerFor(view)
end

-- ------------------------------------------------------ the Butterfree bench
--
-- The foe is a Butterfree (BUG/FLYING).  Every expectation here was
-- checked by hand in-game first; the movesets are named so a reader can
-- re-derive the arithmetic.
local BUTTERFREE = { "BUG", "FLYING" }

-- Pikachu: THUNDERSHOCK is 2x into FLYING (+2), and neither of the foe's
-- types is better than neutral into ELECTRIC (0).  Score 2 -> B, and the
-- foe never reaches 2x, so no danger flag.
T.eq(marker({ types = { "ELECTRIC" }, foeTypes = BUTTERFREE,
              moves = slots("THUNDERSHOCK", "QUICK_ATTACK", "GROWL") }), "B",
  "Pikachu vs Butterfree grades B")

-- Mankey: FIGHTING is resisted twice into BUG/FLYING, so the best it has
-- is its NORMAL move at neutral (0); FLYING hits FIGHTING for 2x (-2).
-- Score -2 -> D, and 2x incoming raises the flag.
T.eq(marker({ types = { "FIGHTING" }, foeTypes = BUTTERFREE,
              moves = slots("KARATE_CHOP", "LOW_KICK", "LEER") }), "D!",
  "Mankey vs Butterfree grades D!")

-- Weepinbell: its only damaging move is GRASS, resisted by both foe types
-- (-2); BUG is 4x into GRASS/POISON (-3).  Score -5 -> E, flagged.
T.eq(marker({ types = { "GRASS", "POISON" }, foeTypes = BUTTERFREE,
              moves = slots("VINE_WHIP", "POISONPOWDER", "SLEEP_POWDER",
                            "STUN_SPORE") }), "E!",
  "Weepinbell vs Butterfree grades E!")

-- Paras: LEECH_LIFE is BUG, resisted by FLYING (-2); FLYING is 4x into
-- BUG/GRASS (-3).  Score -5 -> E, flagged.
T.eq(marker({ types = { "BUG", "GRASS" }, foeTypes = BUTTERFREE,
              moves = slots("LEECH_LIFE", "STUN_SPORE") }), "E!",
  "Paras vs Butterfree grades E!")

-- The A band: 4x offence and a defensive resist.  ROCK is 2x into BUG and
-- 2x into FLYING (+3); neither foe type beats neutral into ROCK/GROUND --
-- FLYING is resisted and BUG is resisted, so the worst case is 0.5 (+2).
T.eq(marker({ types = { "ROCK", "GROUND" }, foeTypes = BUTTERFREE,
              moves = slots("ROCK_THROW") ,
              moves_data = { ROCK_THROW = { type = "ROCK", power = 50 } } }), "A",
  "a 4x rock type vs Butterfree grades A")

-- The silent band: nothing to say prints nothing, which keeps the party
-- screen identical to vanilla.
T.eq(marker({ types = { "NORMAL" }, foeTypes = BUTTERFREE,
              moves = slots("TACKLE") }), nil,
  "an even matchup prints no marker at all")

-- ------------------------------------------------------ status vs immunity
--
-- A status move never runs the damage formula, so it must not earn
-- offensive credit -- even when its type would be super effective.
local statusOnly = marker({ types = { "WATER" }, foeTypes = { "GRASS" },
                            moves = slots("WILL_O_STATUS", "GROWL") })
T.eq(statusOnly, "D!",
  "a super-effective STATUS move earns no offence (a counted FIRE would "
  .. "have cancelled the -2 and printed just !)")

-- The same mon with the FIRE move made damaging flips the grade, which is
-- what proves the previous case turned on `power`, not on the move id.
T.eq(marker({ types = { "WATER" }, foeTypes = { "GRASS" },
              moves = slots("EMBER") }), "!",
  "the damaging FIRE move cancels the deficit but keeps the danger flag")

-- Immunity, on the other hand, is a real damage result and still counts.
-- A NORMAL mon is immune to GHOST (+3) but its NORMAL move cannot touch a
-- GHOST either (-3): the two cancel and the row stays silent.
T.eq(marker({ types = { "NORMAL" }, foeTypes = { "GHOST" },
              moves = slots("TACKLE", "QUICK_ATTACK") }), nil,
  "a 0x damaging move still scores (offence -3 cancels the 0x defence +3)")

-- Drop the useless move and the defensive immunity stands alone.
T.eq(marker({ types = { "NORMAL" }, foeTypes = { "GHOST" },
              moves = slots("GROWL") }), "A",
  "immunity to the foe's only type grades A on its own")

-- And a mon that carries a move that CAN touch the ghost keeps the A.
T.eq(marker({ types = { "NORMAL" }, foeTypes = { "GHOST" },
              moves = slots("LICK", "TACKLE") }), "A",
  "the best damaging move wins: GHOST vs GHOST beats the 0x NORMAL")

-- A defensive immunity from a dual type: GROUND cannot touch FLYING.
T.eq(marker({ types = { "FLYING" }, foeTypes = { "GROUND" },
              moves = slots("GROWL") }), "A",
  "GROUND vs a FLYING defender is 0x, which grades A")

-- --------------------------------------------------------- the score bands

T.eq(ex.offensePoints(40), 3, "4x offence is +3")
T.eq(ex.offensePoints(20), 2, "2x offence is +2")
T.eq(ex.offensePoints(10), 0, "neutral offence is 0")
T.eq(ex.offensePoints(5), -2, "a resisted attacker is -2")
T.eq(ex.offensePoints(2), -2, "a double resist is still -2")
T.eq(ex.offensePoints(0), -3, "an immune defender is -3")

T.eq(ex.defensePoints(40), -3, "taking 4x is -3")
T.eq(ex.defensePoints(20), -2, "taking 2x is -2")
T.eq(ex.defensePoints(10), 0, "taking neutral is 0")
T.eq(ex.defensePoints(5), 2, "resisting is +2")
T.eq(ex.defensePoints(2), 2, "double resisting is still +2")
T.eq(ex.defensePoints(0), 3, "immunity is +3")

T.eq(ex.grade(5), "A", "5 grades A")
T.eq(ex.grade(3), "A", "3 is the A floor")
T.eq(ex.grade(2), "B", "2 is the B floor")
T.eq(ex.grade(1), nil, "1 is inside the silent band")
T.eq(ex.grade(0), nil, "0 is silent")
T.eq(ex.grade(-1), nil, "-1 is the silent floor")
T.eq(ex.grade(-2), "D", "-2 is the D ceiling")
T.eq(ex.grade(-3), "D", "-3 still grades D")
T.eq(ex.grade(-4), "E", "-4 is the E ceiling")
T.eq(ex.grade(-6), "E", "-6 still grades E")

-- --------------------------------------------------------------- the guards

T.eq(marker({ types = { "GRASS" }, foeTypes = BUTTERFREE,
              moves = slots("VINE_WHIP"), hp = 0 }), nil,
  "a fainted mon is never graded (the row already says FNT)")
T.eq(marker({ types = { "GRASS" }, foeTypes = {},
              moves = slots("VINE_WHIP") }), nil,
  "no foe on the field means no marker")
T.eq(marker({ types = {}, foeTypes = BUTTERFREE,
              moves = slots("VINE_WHIP") }), nil,
  "a candidate with no types is skipped")
T.eq(ex.markerFor(nil), nil, "markerFor tolerates a nil view")
T.eq(ex.markerFor("nope"), nil, "markerFor tolerates a non-table view")
-- With no offence to add, the score is the defensive half only: BUG is 4x
-- into GRASS/POISON, so -3 -> D, flagged.  The E! the same mon earns above
-- is exactly the -2 its resisted VINE_WHIP contributes.
T.eq(marker({ types = { "GRASS", "POISON" }, foeTypes = BUTTERFREE,
              moves = nil }), "D!",
  "a mon with no move list is graded on defence alone")
T.eq(marker({ types = { "GRASS", "POISON" }, foeTypes = BUTTERFREE,
              moves = slots("VINE_WHIP"), noRegistry = true }), "D!",
  "no move registry falls back to defence alone")

-- the danger flag is a switch, not a fact about the matchup
T.eq(marker({ types = { "FIGHTING" }, foeTypes = BUTTERFREE,
              moves = slots("KARATE_CHOP"), danger = false }), "D",
  "with the danger flag off the same matchup prints just the letter")

-- the marker is hard-capped at the two glyphs the party row has room for
for _, view in ipairs({
  { types = { "GRASS", "POISON" }, foeTypes = BUTTERFREE, moves = slots("VINE_WHIP") },
  { types = { "FIGHTING" }, foeTypes = BUTTERFREE, moves = slots("KARATE_CHOP") },
  { types = { "ELECTRIC" }, foeTypes = BUTTERFREE, moves = slots("THUNDERSHOCK") },
}) do
  local text = marker(view)
  T.check(type(text) == "string" and #text <= 2, "every marker fits two glyphs")
end

-- ------------------------------------------------- markersFor on a live menu
--
-- The shape PartyMenu:draw hands over: a menu table with .battle set (which
-- only BattleState ever does), .party, and .game.data for the pokedex.

local function menuWith(over)
  local menu = {
    game = { data = { pokemon = {
      PIKACHU_FIX    = { types = { "ELECTRIC" } },
      WEEPINBELL_FIX = { types = { "GRASS", "POISON" } },
      GEODUDE_FIX    = { types = { "ROCK", "GROUND" } },
    }, moves = MOVES } },
    party = {
      { species = "PIKACHU_FIX", hp = 20, moves = slots("THUNDERSHOCK") },
      { species = "WEEPINBELL_FIX", hp = 18, moves = slots("VINE_WHIP") },
      { species = "GEODUDE_FIX", hp = 0, moves = slots("TACKLE") }, -- fainted
    },
    battle = {
      enemy = { curTypes = BUTTERFREE },
      player = {},
      data = { moves = MOVES },
    },
  }
  for key, value in pairs(over or {}) do menu[key] = value end
  return menu
end

local marks = ex.markersFor(menuWith())
T.eq(#marks, 2, "the fainted slot drops out and the other two are graded")
T.eq(marks[1].slot, 1, "the first marker names party slot 1")
T.eq(marks[1].text, "B", "slot 1 is the Pikachu grade")
T.eq(marks[2].slot, 2, "the second marker names party slot 2")
T.eq(marks[2].text, "E!", "slot 2 is the Weepinbell grade")

-- THE out-of-battle guard: the START menu, the bag pickers and the TM
-- screen all leave .battle nil, and the screen must stay vanilla.
T.eq(#ex.markersFor(menuWith({ battle = false })), 0,
  "no battle on the menu means no markers (the out-of-battle case)")
T.eq(#ex.markersFor(menuWith({ tmhm = true })), 0,
  "the TM/HM picker is left alone")
T.eq(#ex.markersFor({}), 0, "an empty menu yields nothing")
T.eq(#ex.markersFor(nil), 0, "markersFor tolerates a nil menu")

local noFoe = menuWith()
noFoe.battle.enemy = nil
T.eq(#ex.markersFor(noFoe), 0, "a battle with no foe on the field says nothing")

local blankFoe = menuWith()
blankFoe.battle.enemy = { curTypes = {} }
T.eq(#ex.markersFor(blankFoe), 0, "a foe with no curTypes says nothing")

-- curTypes wins over the species record, so Conversion / Transform are
-- followed instead of the pokedex entry.  Slot 1 is the ELECTRIC mon that
-- graded B above; re-typed to GRASS/POISON it now eats 4x from BUG, so the
-- B collapses into the silent band and only the danger flag survives.
local transformed = menuWith()
transformed.battle.player = { mon = transformed.party[1], curTypes = { "GRASS", "POISON" } }
local tmarks = ex.markersFor(transformed)
T.eq(tmarks[1].text, "!",
  "the active mon is graded on curTypes, not on its species types")

-- ...and curMoves wins over mon.moves, for Mimic / Transform.  Slot 2 is
-- the Weepinbell that graded E! on its resisted VINE_WHIP; a borrowed FIRE
-- move is 2x into BUG, which lifts it clear of the E band.
local mimicked = menuWith()
mimicked.battle.player = { mon = mimicked.party[2], curMoves = slots("EMBER") }
local mmarks = ex.markersFor(mimicked)
T.eq(mmarks[2].text, "!",
  "the active mon is graded on curMoves, not on its stored move slots")

-- ------------------------------------------------------ feature 2: nickname

T.check(ex.enabled("skipNickname"), "SKIP NICKNAME defaults on")
T.check(ex.enabled("partyGrades"), "PARTY GRADES defaults on")
T.check(ex.enabled("dangerFlag"), "the danger flag defaults on")
T.eq(ex.enabled("nope_not_a_key"), false, "an unknown option reads as off")

-- the stand-in state settles the two flags the vanilla prompt owns and
-- pops itself on its first update
local popped = 0
local battle = {
  lockedBall = "POKE_BALL",
  blankForAskName = true,
  game = { stack = { pop = function() popped = popped + 1 end } },
}
local state = ex.dismissNickname(battle)
T.check(type(state) == "table" and type(state.update) == "function",
  "dismissNickname returns something the state stack can push")
T.eq(state.draw, nil, "the stand-in has no draw, so the frame is invisible")
T.eq(battle.lockedBall, nil, "the locked ball is released")
T.eq(battle.blankForAskName, false,
  "the battle scene is not left blanked behind a prompt that never shows")
T.eq(popped, 0, "nothing pops before the first update")
state.update()
T.eq(popped, 1, "the first update pops the stand-in back off the stack")

-- a battle with no stack must not raise on the way out
local bare = ex.dismissNickname({})
bare.update()
T.check(true, "dismissNickname survives a battle with no game.stack")

-- the wrap really is installed on the real BattleState, which is the
-- stated effect: no nickname prompt is ever pushed
local BattleState = require("src.battle.BattleState")
T.check(BattleState._switchAdvisorSkipNickname,
  "the load installed the askNicknameUI wrap")
local fake = {
  lockedBall = "GREAT_BALL",
  blankForAskName = true,
  game = { stack = { pop = function() end } },
}
local wrapped = BattleState.askNicknameUI(fake, { species = "FIXMON_A" }, "FIXMON A")
T.check(type(wrapped) == "table" and type(wrapped.update) == "function",
  "askNicknameUI hands back the self-popping stand-in, not the name screen")
T.eq(fake.blankForAskName, false, "the wrap settled the blank flag")

-- and PartyMenu was wrapped exactly once, so a hot reload cannot stack
-- two markers on one row
local PartyMenu = require("src.ui.PartyMenu")
T.check(PartyMenu._switchAdvisorGrades, "the load installed the PartyMenu wrap")

run.release()
T.finish("switch_advisor")
