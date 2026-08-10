-- Standalone: luajit mods/useful_dex/tests/useful_dex_test.lua
-- Loads the mod through the real headless loader and asserts both page
-- builders (movelist, stats/evolution) plus the screen cycle: A advances
-- combined data/stats -> moves -> combined data, B pops from any page.  Also asserts the
-- dex list views builder (num / alpha / caught) and that SELECT on the
-- PokedexMenu cycles the live list through those three views.
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Data = require("src.core.Data")
Data:load()

local run = T.sdk.loadMod("mods/useful_dex", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")
T.eq(run.mod and run.mod.state, "loaded", "reached the loaded state")

local record = run.loader.content.screens:get("DexEntryMenu")
T.check(record ~= nil and type(record.new) == "function",
  "DexEntryMenu is a registered screen with a factory")

local buildMoves = run.loader.exports.useful_dex.buildMoves
local buildStats = run.loader.exports.useful_dex.buildStats
T.check(type(buildMoves) == "function" and type(buildStats) == "function",
  "both builders are published for tests")

-- ---------- movelist builder (unchanged behaviour) ----------

-- FIXMON_A: learnset TACKLE(1), EMBERISH(7); tmhm FIX_CUT -> TM01
local a = buildMoves(Data, Data.pokemon.FIXMON_A)
T.eq(#a.learned, 2, "both learnset entries listed")
T.eq(a.learned[1].level, 1, "learnset keeps ROM order (first)")
T.eq(a.learned[1].name, "FIX TACKLE", "move names resolve")
T.eq(a.learned[2].level, 7, "learnset keeps ROM order (second)")
T.eq(a.learned[1].type, "NORMAL", "move type is retained for the STAB marker")
T.check(a.learned[1].stab == false, "non-matching move is not marked STAB")
T.eq(#a.machines, 1, "one machine from the tmhm list")
T.eq(a.machines[1].kind, "TM", "machine kind mapped from the item")
T.eq(a.machines[1].number, 1, "machine number mapped from the item")
T.eq(a.machines[1].name, "FIX CUT", "machine move name resolves")

-- dedupe: a fake def with the same move at two levels lists it once
local deduped = buildMoves(Data, { learnset = {
  { level = 1, move = "FIX_TACKLE" }, { level = 9, move = "FIX_TACKLE" },
}, tmhm = {} })
T.eq(#deduped.learned, 1, "a duplicate learnset move is listed once")
T.eq(deduped.learned[1].level, 1, "the first occurrence wins")

-- ---------- stats builder ----------

-- FIXMON_A: hp45 atk49 def49 spd45 spc65 -> BST 253, LEVEL-16 -> FIXMON_B
local s = buildStats(Data, Data.pokemon.FIXMON_A)
T.eq(s.stats[1].key, "HP", "HP first")
T.eq(s.stats[1].value, 45, "HP value")
T.eq(s.stats[2].key, "ATK", "ATK second")
T.eq(s.stats[3].key, "DEF", "DEF third")
T.eq(s.stats[4].key, "SPD", "SPD fourth")
T.eq(s.stats[5].key, "SPC", "SPC fifth")
T.eq(s.stats[5].value, 65, "SPC value")
T.eq(s.bst, 253, "BST sums the five stats (45+49+49+45+65)")
T.eq(#s.evolutions, 1, "one evolution listed")
T.eq(s.evolutions[1].method, "LEVEL", "method id preserved")
T.eq(s.evolutions[1].label, "Level 16", "the merged method describe() labels it")
T.eq(s.evolutions[1].species, "FIXMON_B", "target species id")
T.eq(s.evolutions[1].name, "FIXMON B", "target species name resolves")

-- FIXMON_B: different stats, no evolution
local b = buildStats(Data, Data.pokemon.FIXMON_B)
T.eq(b.stats[1].value, 39, "FIXMON_B HP")
T.eq(b.bst, 39 + 52 + 43 + 65 + 60, "FIXMON_B BST sums correctly")
T.eq(#b.evolutions, 0, "no evolutions -> empty list")

-- a missing method falls back to the raw method id
local noMethod = buildStats(Data, { baseStats = { hp = 1, attack = 2,
  defense = 3, speed = 4, special = 5 }, evolutions = {
  { method = "MYSTERY", species = "FIXMON_C" } } })
T.eq(noMethod.evolutions[1].label, "MYSTERY", "unknown method falls back to the id")
T.eq(noMethod.evolutions[1].name, "FIXMON C", "target name still resolves")

-- ---------- screen cycle ----------

local pressed
local popped = 0
local game = {
  data = Data,
  save = { pokedex = { seen = { FIXMON_A = true, FIXMON_B = true }, owned = {} } },
  input = { wasPressed = function(_, key) return pressed == key end },
  stack = { popped = 0, pop = function() popped = popped + 1 end },
}
local screen = record.new(game, "FIXMON_A")
T.check(screen ~= nil and screen.view == "data", "screen starts on the data page")

pressed = "down"
screen:update(0)
T.eq(screen.def.id, "FIXMON_B", "DOWN opens the next seen species")
pressed = "up"
screen:update(0)
T.eq(screen.def.id, "FIXMON_A", "UP returns to the previous seen species")
pressed = nil

T.eq(screen.stats.bst, 253, "the combined page builds its stats content")
T.check(type(screen.drawData) == "function", "combined page has a draw path")

pressed = "a"
screen:update(0)
T.eq(screen.view, "moves", "A on the combined page opens the movelist")
T.eq(screen:rows()[1], "LEARNED", "learned section header first")

pressed = "a"
screen:update(0)
T.eq(screen.view, "data", "A on the movelist returns to the combined page")

pressed = "a"
screen:update(0)
pressed = "b"
screen:update(0)
T.eq(popped, 1, "B pops the screen from any page")

-- ---------- movelist pagination (pageRows / stepPage) ----------

-- 12 learned entries page into three pages: six rows per page.
local bigList = { learned = {}, machines = {} }
for i = 1, 12 do
  bigList.learned[#bigList.learned + 1] = {
    level = i, move = "FIX_" .. i, name = "MOVE " .. i,
  }
end
local pager = record.new(game, "FIXMON_A")
pager.view = "moves"
pager.list = bigList
T.eq(pager:pages(), 3, "12 learned rows page into three pages")
pager.page = 1
T.eq(#pager:pageRows(), 6, "page one shows six rows")
T.eq(pager:pageRows()[1], "LEARNED", "page one starts with the learned header")
pager:stepPage(1)
T.eq(pager.page, 2, "stepPage(1) advances a page")
T.eq(#pager:pageRows(), 6, "page two shows six rows")
T.eq(pager:pageRows()[1], "LV  6 MOVE 6", "page two starts at the sixth entry")
pager:stepPage(1)
T.eq(pager.page, 3, "stepPage advances to the final page")
pager:stepPage(-1)
T.eq(pager.page, 2, "stepPage(-1) goes back a page")
pager:stepPage(-1)
pager:stepPage(-1)
T.eq(pager.page, 1, "stepPage clamps at page one")

-- ---------- dex list views ----------

local buildList = run.loader.exports.useful_dex.buildList
T.check(type(buildList) == "function", "list builder is published for tests")
local pokedexRecord = run.loader.content.screens:get("PokedexMenu")
T.check(pokedexRecord ~= nil and type(pokedexRecord.new) == "function",
  "PokedexMenu is a registered screen with a factory")

-- fixture: FIXMON_A/B/C at dex 1/2/3, names already in dex order
local save = { seen = {}, owned = {} }
save.owned["FIXMON_A"] = true
save.seen["FIXMON_C"] = true

local num = buildList(Data, save, "num")
T.eq(#num.items, 3, "num mode lists every dex slot")
T.eq(num.items[1].label, "001 FIXMON A", "owned slot shows its name")
T.eq(num.items[1].value, "FIXMON_A", "owned slot is selectable")
T.eq(num.items[1].ball, true, "owned slot carries the ball marker")
T.eq(num.items[2].label, "002 -----", "unseen slot shows dashes")
T.eq(num.items[2].value, nil, "unseen slot is not selectable")
T.eq(num.items[3].label, "003 FIXMON C", "seen slot shows its name")
T.eq(num.items[3].value, "FIXMON_C", "seen slot is selectable")
T.eq(num.seen, 2, "seen count")
T.eq(num.owned, 1, "owned count")

local alpha = buildList(Data, save, "alpha")
T.eq(#alpha.items, 2, "alpha mode lists only seen/owned")
T.eq(alpha.items[1].label, "001 FIXMON A", "alpha keeps dex numbers")
T.eq(alpha.items[2].label, "003 FIXMON C", "alpha drops unseen slots")

local caught = buildList(Data, save, "caught")
T.eq(#caught.items, 1, "caught mode lists only owned")
T.eq(caught.items[1].label, "001 FIXMON A", "caught keeps dex numbering")
T.eq(caught.items[1].ball, true, "caught entries carry the ball marker")

-- sort: names that invert dex order prove alpha sorts by name
local fake = {
  constants = { dexSize = 2, dexDigits = 3 },
  pokemon = {
    ALF = { id = "ALF", dex = 1, name = "ZETA" },
    ZED = { id = "ZED", dex = 2, name = "ALPHA" },
  },
}
local fsave = { seen = { ALF = true, ZED = true }, owned = {} }
T.eq(buildList(fake, fsave, "num").items[1].label, "001 ZETA",
  "num mode keeps dex order regardless of name")
local falpha = buildList(fake, fsave, "alpha")
T.eq(falpha.items[1].label, "002 ALPHA", "alpha sorts by name")
T.eq(falpha.items[1].value, "ZED", "alpha first is the ALPHA-named mon")
T.eq(falpha.items[2].label, "001 ZETA", "alpha keeps each mon's dex number")

-- ---------- SELECT cycles the live list ----------

local pressed2
local game2 = {
  data = Data,
  save = { pokedex = { seen = { FIXMON_B = true, FIXMON_C = true },
                        owned = { FIXMON_A = true } } },
  input = { wasPressed = function(_, key) return pressed2 == key end },
  stack = { pop = function() end },
}
local list = pokedexRecord.new(game2, {})
T.check(list ~= nil and #list.items == 3, "dex list built by the wrapped vanilla")
T.eq(list.title, "POKéDEX", "starts in numbered mode")
T.eq(list.onSelectKey ~= nil, true, "SELECT is hooked")

pressed2 = "select"
list:update(0)
T.eq(list.title, "POKéDEX A-Z", "SELECT cycles to alphabetical")
T.eq(#list.items, 3, "alpha lists the seen/owned in this save")
pressed2 = "select"
list:update(0)
T.eq(list.title, "POKéDEX CAUGHT", "SELECT cycles to caught only")
T.eq(#list.items, 1, "only owned listed in caught mode")
pressed2 = "select"
list:update(0)
T.eq(list.title, "POKéDEX", "SELECT wraps back to numbered")
pressed2 = nil

T.eq(list.wrap, true, "list wraps around at the ends")
list.index = #list.items
pressed2 = "down"
list:update(0)
T.eq(list.index, 1, "down on the last row wraps to the first")
pressed2 = "up"
list:update(0)
T.eq(list.index, #list.items, "up on the first row wraps to the last")
pressed2 = nil

-- cursor restore: a SELECT switch re-finds the current species even when
-- alpha reordering moved it to a different row (fake names invert dex order)
local game3 = {
  data = fake,
  save = { pokedex = { seen = { ALF = true, ZED = true }, owned = {} } },
  input = { wasPressed = function(_, key) return pressed2 == key end },
  stack = { pop = function() end },
}
local list2 = pokedexRecord.new(game3, {})
T.eq(#list2.items, 2, "fake dex list has both species")
T.eq(list2.items[1].value, "ALF", "num mode cursor starts on ZETA")
pressed2 = "select"
list2:update(0)
T.eq(list2.title, "POKéDEX A-Z", "SELECT switches to alpha mode")
T.eq(list2.items[1].value, "ZED", "alpha sorts ALPHA first")
T.eq(list2.index, 2, "cursor follows the species to its new row")
pressed2 = nil

run.release()
T.finish("useful_dex")
