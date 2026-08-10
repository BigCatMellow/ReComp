-- Standalone: luajit mods/useful_move_info/tests/useful_move_info_test.lua
-- Loads the mod through the real headless loader, fires game.ready so the
-- input wraps install, then drives the real Input module with Q presses and
-- Start presses and asserts the info text builder, edge consumption, and
-- the open-box latch (a press while the info box is showing must never
-- queue a second loop).
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Data = require("src.core.Data")
Data:load()

local run = T.sdk.loadMod("mods/useful_move_info", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")
T.eq(run.mod and run.mod.state, "loaded", "reached the loaded state")

local ex = run.loader.exports.useful_move_info
T.check(type(ex.infoText) == "function", "infoText is published")

-- install the input wraps the way the game would
local Runtime = require("src.mods.Runtime")
Runtime.emit("game.ready", { game = { data = Data } })

local Input = require("src.core.Input")
Input:init()

-- ---------- info text formatting ----------

local text = ex.infoText(Data, Data.moves.FIX_EMBERISH)
T.check(text:find("^FIX EMBER\v"), "first line is the move name")
T.check(text:find("\vTYPE: FIRE"), "type line")
T.check(text:find("\vPWR: 40"), "power line")
T.check(text:find("\vACC: 100"), "accuracy line")
T.check(text:find("\vEFFECT: 10%% burn chance"),
  "known effect ids get their curated description")
T.check(not text:find("\n", 1, true), "lines are ContText (\\v), not free-flowing")

-- a status move (power 0) shows dashes
local status = ex.infoText(Data, {
  id = "FIX_STATUS", name = "FIX STATUS", type = "NORMAL",
  power = 0, accuracy = 100, effect = "NO_ADDITIONAL_EFFECT",
})
T.check(status:find("PWR: --"), "zero power renders as dashes")

-- an unknown effect falls back to a readable id
local unknown = ex.infoText(Data, {
  id = "FIX_WEIRD", name = "FIX WEIRD", type = "NORMAL",
  power = 10, accuracy = 100, effect = "MY_WEIRD_EFFECT",
})
T.check(unknown:find("EFFECT: My Weird Effect"), "unknown effects humanize")

-- ---------- type-effectiveness readout ----------

T.eq(ex.effectivenessLabel(Data, "FIRE", { "GRASS" }),
  "VS GRASS: SUPER EFFECTIVE (x2)", "2x matchup reads super effective")
T.eq(ex.effectivenessLabel(Data, "FIRE", { "WATER" }),
  "VS WATER: NOT VERY EFFECTIVE (x0.5)", "0.5x matchup reads not very")
T.eq(ex.effectivenessLabel(Data, "FIRE", { "NORMAL" }),
  "VS NORMAL: NEUTRAL (x1)", "a missing row reads neutral")
T.eq(ex.effectivenessLabel(Data, "FIRE", { "WATER", "GRASS" }),
  "VS WATER/GRASS: NEUTRAL (x1)", "dual types multiply to neutral")
T.eq(ex.effectivenessLabel(Data, "FIRE", nil), nil,
  "no defender types yields no readout")
T.eq(ex.effectivenessLabel(nil, "FIRE", { "GRASS" }), nil,
  "no chart yields no readout")

local eff = ex.infoText(Data, Data.moves.FIX_EMBERISH, { "GRASS" })
T.check(eff:find("\vVS GRASS: SUPER EFFECTIVE %(x2%)"),
  "infoText appends the super-effective line for a damaging move")
local effW = ex.infoText(Data, Data.moves.FIX_EMBERISH, { "WATER" })
T.check(effW:find("\vVS WATER: NOT VERY EFFECTIVE %(x0%.5%)"),
  "infoText appends the not-very line")
local noFoe = ex.infoText(Data, Data.moves.FIX_EMBERISH)
T.check(not noFoe:find("VS "), "no foe: the info box keeps its five lines")
local statusVs = ex.infoText(Data, {
  id = "FIX_STATUS", name = "FIX STATUS", type = "NORMAL",
  power = 0, accuracy = 100, effect = "NO_ADDITIONAL_EFFECT",
}, { "GRASS" })
T.check(not statusVs:find("VS "),
  "status moves (power 0) never read the type chart")

-- ---------- press / open / close lifecycle ----------

local pushed = 0
local battle = {
  phase = "moveSelect",
  moveIndex = 1,
  player = { curMoves = { { id = "FIX_EMBERISH", pp = 5 } } },
  data = Data,
}
local function pushBox() pushed = pushed + 1 end

local ok = ex.tryOpen(battle, pushBox)
T.check(not ok, "no press yet: nothing opens")

Input:keypressed("q")
T.check(ex.state.edge, "Q press sets the edge")
local ok, text = ex.tryOpen(battle, pushBox)
T.check(ok, "Q in moveSelect opens the box")
T.check(type(text) == "string" and #text > 0, "the info text is returned")
T.eq(pushed, 1, "the push callback ran once")
T.check(not ex.state.edge, "the edge is consumed")
T.check(ex.state.open, "the box session is marked open")

-- the reported bug: Q while the box is showing must not queue a second loop
Input:keypressed("q")
T.check(not ex.state.edge, "Q while the box is open sets no edge")
T.eq(ex.tryOpen(battle, pushBox), false, "no reopen while the box is open")
T.eq(pushed, 1, "still only one push")
Input:keyreleased("q")

-- the same drop applies to a Start press while the box is open
local joy = { name = "stub" }
Input:gamepadpressed(joy, "start")
T.check(not ex.state.edge, "Start while the box is open sets no edge")
Input:gamepadreleased(joy, "start")

-- the box closes (onDone): a fresh tap works again
ex.state.open = false
Input:keyreleased("q")
Input:keypressed("q")
T.check(ex.state.edge, "a fresh Q press after closing re-arms")
ex.tryOpen(battle, pushBox)
T.eq(pushed, 2, "the second Q press opens again")
Input:keyreleased("q")

-- held auto-repeat: two keypressed events while held, one edge, one open
ex.state.open = false
Input:keypressed("q")
T.check(ex.state.edge, "the held press sets the edge")
Input:keypressed("q")
T.check(ex.state.edge, "a repeat while held adds no second edge")
ex.tryOpen(battle, pushBox)
T.eq(pushed, 3, "one open from the held press")
Input:keyreleased("q")

-- release, then press again: a fresh edge
ex.state.open = false
Input:keypressed("q")
T.check(ex.state.edge, "a fresh Q press after release re-arms")
ex.tryOpen(battle, pushBox)
T.eq(pushed, 4, "the fresh press opens")
Input:keyreleased("q")

-- Start path: press, open, release, re-arm
ex.state.open = false
Input:gamepadpressed(joy, "start")
T.check(ex.state.edge, "Start sets the edge")
ex.tryOpen(battle, pushBox)
T.eq(pushed, 5, "Start opens the box")
Input:gamepadreleased(joy, "start")
T.check(not ex.state.edge, "Start release clears the held latch")
ex.state.open = false
Input:gamepadpressed(joy, "start")
T.check(ex.state.edge, "a fresh Start press re-arms")

-- edge outside moveSelect is consumed without opening
local inMenu = ex.tryOpen({ phase = "menu", player = { curMoves = {} } }, pushBox)
T.check(not inMenu, "edge in another phase opens nothing")
T.check(not ex.state.edge, "the stray edge is still consumed")
T.eq(pushed, 5, "no extra pushes")

-- empty slot / unknown move guarded
Input:keypressed("q")
local emptySlot = ex.tryOpen({
  phase = "moveSelect", moveIndex = 2,
  player = { curMoves = { { id = "FIX_EMBERISH" }, nil } },
  data = Data,
}, pushBox)
T.check(not emptySlot, "an empty slot opens nothing")
T.check(not ex.state.edge, "the edge is consumed on the guarded path")

-- focus loss / soft reset: Input:reset clears the held latches and an
-- open box (the engine calls it on those transitions, where a swallowed
-- release or a stack wipe would otherwise strand the mod's state)
ex.state.open = true
Input:keypressed("q")
Input:reset()
T.check(not ex.state.open, "reset clears an open box")
T.check(not ex.state.qHeld, "reset clears the keyboard latch")
Input:keypressed("q")
T.check(ex.state.edge, "a press after reset sets an edge")
Input:reset()
T.check(not ex.state.edge, "reset drops a pending edge")
Input:keypressed("q")
T.check(ex.state.edge, "a fresh press re-arms")
ex.tryOpen(battle, pushBox)
T.eq(pushed, 6, "the re-armed edge opens")

-- ---------- learn-move screen inspection ----------

-- the last battle-lifecycle block left the open latch + held latch set;
-- clean up so a fresh Q press can arm the edge
ex.state.open = false
Input:keyreleased("q")

-- a separate game stub with a working stack; the input wraps were already
-- installed by the game.ready above
local StateStack = require("src.core.StateStack")
local lstack = setmetatable({}, { __index = StateStack })
lstack:init()
local lgame = {
  data = Data,
  stack = lstack,
  input = { wasPressed = function() return false end },
}
local Screens = require("src.ui.Screens")
local mon = {
  nickname = "FIX MON", species = "FIX_SPECIES",
  moves = { { id = "FIX_TACKLE", pp = 35 }, { id = "FIX_SCRATCH", pp = 35 },
            { id = "FIX_EMBERISH", pp = 25 }, { id = "FIX_CUT", pp = 30 } },
}
local learn = Screens.get(lgame, "MoveLearnMenu").new(lgame, mon, "FIX_EMBERISH", nil)

learn:update(1 / 60)
T.check(lstack:top() == nil, "the preamble phase pushes nothing")
T.check(not ex.state.edge, "the preamble phase swallows no edges")

-- Start/Q on a current move opens its info box
learn.selecting = true
learn:update(1 / 60) -- entering the forget list drops any stale edge
T.check(not ex.state.edge, "entering the forget list drops a stale edge")
learn.index = 1
Input:keypressed("q")
learn:update(1 / 60)
T.check(lstack:top() ~= nil, "Start on a current move pushes the info box")
T.check(ex.state.open, "the learn info box is latched open")
Input:keyreleased("q")
ex.state.open = false
lstack:pop()

-- Start/Q on the NEW MOVE row shows the move being learned
learn.index = #mon.moves + 1
Input:keypressed("q")
learn:update(1 / 60)
T.check(lstack:top() ~= nil, "Start on the NEW MOVE row pushes the info box")
T.check(ex.state.open, "the NEW-row info box is latched open")
Input:keyreleased("q")
ex.state.open = false
lstack:pop()

-- CANCEL row (last row) opens nothing on Start
learn.index = #mon.moves + 2
Input:keypressed("q")
learn:update(1 / 60)
T.check(lstack:top() == nil, "Start on CANCEL opens nothing")
T.check(not ex.state.edge, "the CANCEL-row edge is consumed")
Input:keyreleased("q")

run.release()
T.finish("useful_move_info")
