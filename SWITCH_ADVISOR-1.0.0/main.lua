-- Switch Advisor -- two switching-related quality-of-life seams, in one
-- file.
--
--   1. PARTY GRADES  In the battle party menu (a voluntary PKMN switch, the
--      SHIFT prompt, or ChooseNextMon after a faint) every party member is
--      graded A / B / D / E against the foe that is on the field right now,
--      with an optional "!" danger flag.
--
--   2. SKIP NICKNAME  A caught POKeMON goes straight into the party or the
--      box, with no "Do you want to give a nickname?" prompt.
--
-- Both features are switches in the mod's options pane and both default to
-- on.  The switches are consulted per call, so flipping one takes effect
-- without leaving the battle.
--
--
-- WHY ONE FILE
--
-- Two features do not earn a plugin loader.  Everything the mod needs is
-- here, the pure decision functions are published on `mod.exports` so the
-- test suite can drive them without a graphics context, and there is no
-- runtime chunk-loading path that can half-fail.
--
--
-- WHERE THE GRADE IS DRAWN, AND WHY THERE
--
-- Every party row is two 8px lines (PartyMenu.entryY(i) = (i-1)*16):
--
--   line 1 (y+0)   x=0..8   nothing (the cursor is on the OTHER line)
--                  x=8..24  the 16x16 mon icon
--                  x=24..   nickname (up to 10 glyphs -> 104)
--                  x=104    <LV> tile, x=112 the level digits
--                  x=136    status / FNT
--   line 2 (y+8)   x=0..8   the selection cursor and the hollow swap arrow
--                  x=8..24  the icon again (it is 16 px tall)
--                  x=24..40 EMPTY -- nothing in PartyMenu:draw writes here
--                  x=40..   HudTiles.drawHPBar: tile column 5 is x=40
--                  x=104    ("%3d/%3d"):format(...)
--
-- So the only free space on a party row is x=24..40 of the HP line:
-- exactly TWO 8px glyphs, between the icon and the "HP:[" of the bar.  The
-- marker goes at (24, y+8) and is hard-capped at two characters, so it can
-- never cover the nickname, the level, the status or the bar, and it sits
-- on the line the cursor is on, where the eye already is.
--
--
-- WHY LETTERS AND NOT ARROWS
--
-- The obvious marker was ">>" / ">" / "<".  It cannot be used: the Gen 1
-- font has no "<" and no ">" glyph.  The charmap carries only
--   ! " ' ( ) , - . / : ; ? [ ]
-- as punctuation, plus the triangles at $EC/$ED/$EE -- and $ED IS the party
-- cursor and $EC the swap arrow, so painting either one next to six rows
-- would read as six cursors.  Font.encode silently turns an unknown
-- character into a space and logs it, so ">>" would have shipped as a blank
-- marker and a log flood.  A letter grade needs no colour, survives a
-- monochrome palette, is one glyph, and ranks the six candidates -- which
-- is the decision actually being made on this screen.
--
--
-- WHY THE DRAW WRAPS PartyMenu:draw AND NOT THE battle.overlay HOOK
--
-- battle.overlay runs after the engine has torn the palette step down; text
-- drawn from there comes out with the wrong shades and no setColor fixes
-- it.  The marker therefore goes inside the screen's own draw pass, by
-- wrapping PartyMenu.draw.
--
-- The colour is not a choice, it is a restatement: PartyMenu:draw sets
-- (0,0,0,1) before every Font.draw it makes, and its LAST statement is
-- setColor(1,1,1,1).  Drawing after it returns, with the colour it left,
-- would paint white glyphs onto the white background it filled -- an
-- invisible marker.  So the wrap restates the screen's own text colour and
-- puts back exactly what the original left behind.  Same pass, same canvas,
-- same colour every other glyph on the screen used.

local mod = ...

local MOD_ID = "SWITCH_ADVISOR"
local VERSION = "1.0.0"

-- ------------------------------------------------------------------ options

local OPTIONS = {
  {
    key = "partyGrades", type = "toggle", label = "PARTY GRADES",
    default = true,
    help = "Grade each party mon against the foe when switching in battle.",
  },
  {
    key = "dangerFlag", type = "toggle", label = "  DANGER FLAG",
    default = true,
    help = "Add ! to mons the foe's types hit super effectively.",
  },
  {
    key = "skipNickname", type = "toggle", label = "SKIP NICKNAME",
    default = true,
    help = "Caught POKeMON keep their species name, with no prompt.",
  },
}

local DEFAULTS = {}
for _, row in ipairs(OPTIONS) do DEFAULTS[row.key] = row.default end

-- Values are cached because they are read on hot paths (every party frame,
-- every capture); mod.options_changed keeps the cache honest.
local cache = {}

local function opt(key)
  if cache[key] ~= nil then return cache[key] end
  local ok, got = pcall(mod.options.get, mod.options, key)
  if ok and got ~= nil then
    cache[key] = got
  else
    cache[key] = DEFAULTS[key]
  end
  return cache[key]
end

local function enabled(key)
  return opt(key) and true or false
end

mod.events:on("mod.options_changed", function(payload)
  if not payload or payload.mod ~= MOD_ID then return end
  cache[payload.key] = payload.value
end)

mod.options:define(OPTIONS)

-- ------------------------------------------------------------- the scoring
--
-- TypeChart.effectiveness returns integers x10 (10 = neutral) and folds
-- dual types with floor(mult * m / 10), so a double resist lands on 2, not
-- 2.5.  Every comparison below is on that x10 scale.

-- Offence: how much the BEST damaging move this mon carries is worth
-- against the foe's current types.
local function offensePoints(mult)
  if mult >= 40 then return 3 end   -- 4x
  if mult >= 20 then return 2 end   -- 2x
  if mult >= 10 then return 0 end   -- neutral
  if mult >= 1  then return -2 end  -- resisted (5, or 2 for a double resist)
  return -3                         -- nothing this mon has can touch it
end

-- Defence: how hard the foe's own types hit this mon.  The foe's move list
-- is deliberately NOT read: the game knows it, the player does not, and a
-- marker that leaks unrevealed moves is a cheat, not a QoL.  STAB off the
-- foe's types is the same heuristic a human uses.
local function defensePoints(mult)
  if mult >= 40 then return -3 end
  if mult >= 20 then return -2 end
  if mult >= 10 then return 0 end
  if mult >= 1  then return 2 end
  return 3                          -- immune to both of the foe's types
end

-- One glyph, so it fits column x=24 with the danger flag beside it.  "C" is
-- deliberately absent: an average matchup prints nothing, which keeps the
-- screen identical to vanilla until there is something to say.
local function grade(score)
  if score >= 3 then return "A" end
  if score >= 2 then return "B" end
  if score <= -4 then return "E" end
  if score <= -2 then return "D" end
  return nil
end

-- ------------------------------------------------------------- the marker

local TypeChart -- resolved lazily; see requireTypeChart

local function requireTypeChart()
  if TypeChart then return TypeChart end
  local ok, module = pcall(require, "src.battle.TypeChart")
  if ok and type(module) == "table" then TypeChart = module end
  return TypeChart
end

local function effectiveness(moveType, defenderTypes)
  local chart = requireTypeChart()
  if not chart then return nil end
  local ok, mult = pcall(chart.effectiveness, moveType, defenderTypes)
  if ok and type(mult) == "number" then return mult end
  return nil
end

-- Best type multiplier among a move list's DAMAGING moves, or nil when it
-- carries none.  A status-only mon is graded as offensively neutral rather
-- than as "resisted": it has no damage roll to be resisted.
local function bestOffense(moves, registry, foeTypes)
  if type(moves) ~= "table" or type(registry) ~= "table" then return nil end
  local best
  for _, mv in ipairs(moves) do
    local def = mv and mv.id and registry[mv.id]
    -- power 0/nil is a status move: it never runs the damage formula, so
    -- counting it would grade a mon on a hit it cannot land
    if def and def.type and (tonumber(def.power) or 0) > 0 then
      local mult = effectiveness(def.type, foeTypes)
      if mult and (not best or mult > best) then best = mult end
    end
  end
  return best
end

-- Worst case the foe's own types can do to a defender.
local function worstDefense(foeTypes, myTypes)
  local worst = 0
  for _, t in ipairs(foeTypes) do
    local mult = effectiveness(t, myTypes)
    if mult and mult > worst then worst = mult end
  end
  return worst
end

-- The two-glyph marker for one party member, or nil for "say nothing".
--
-- `view` is a plain description of the candidate, with nothing engine-shaped
-- in it, which is what makes the whole decision testable:
--
--   { hp = 20, types = { "GRASS" }, moves = { { id = "FIX_TACKLE" } },
--     foeTypes = { "FIRE" }, moves_data = Data.moves, danger = true }
local function markerFor(view)
  if type(view) ~= "table" then return nil end
  local foeTypes = view.foeTypes
  if type(foeTypes) ~= "table" or #foeTypes == 0 then return nil end
  local myTypes = view.types
  if type(myTypes) ~= "table" or #myTypes == 0 then return nil end
  -- a fainted mon cannot be sent out (ChooseNextMon re-prompts) and its row
  -- already says FNT, so grading it is pure noise
  if (tonumber(view.hp) or 0) <= 0 then return nil end

  local off = bestOffense(view.moves, view.moves_data, foeTypes)
  local defence = worstDefense(foeTypes, myTypes)

  local score = defensePoints(defence)
  if off then score = score + offensePoints(off) end

  local text = grade(score) or ""
  if defence >= 20 and view.danger then text = text .. "!" end
  if text == "" then return nil end
  return text:sub(1, 2)
end

-- ------------------------------------------------- reading a live PartyMenu

-- The mon that is out follows the battler, not the species record:
-- Conversion / Transform rewrite curTypes mid-fight.
local function typesOf(menu, battle, mon)
  local player = battle.player
  if player and player.mon == mon and type(player.curTypes) == "table"
     and #player.curTypes > 0 then
    return player.curTypes
  end
  local pokedex = menu.game and menu.game.data and menu.game.data.pokemon
  local def = pokedex and pokedex[mon.species]
  local types = def and def.types
  if type(types) == "table" and #types > 0 then return types end
  return nil
end

-- Same reason as above: Mimic / Transform live in curMoves.
local function movesOf(battle, mon)
  local player = battle.player
  if player and player.mon == mon and type(player.curMoves) == "table" then
    return player.curMoves
  end
  return mon.moves
end

-- Every marker for a live PartyMenu instance, as { { text, slot }, ... }.
-- Returns an empty list whenever the screen has nothing to say -- which is
-- every use of the party menu outside a battle.
local function markersFor(menu)
  local out = {}
  if type(menu) ~= "table" then return out end

  -- THE out-of-battle guard.  opts.battle is set by exactly three call
  -- sites, all of them BattleState (openParty, openReplacementMenu and the
  -- SHIFT prompt), and by nothing else: the START menu, the bag's item/TM
  -- pickers and the link-battle copies all leave it nil.  With no foe on
  -- the field there is nothing to compare against, so the screen stays
  -- vanilla.
  local battle = menu.battle
  if not battle or menu.tmhm then return out end

  -- curTypes, not def.types: the badge has to follow whatever the foe is
  -- right now, after a Transform or a Conversion
  local enemy = battle.enemy
  local foeTypes = enemy and enemy.curTypes
  if type(foeTypes) ~= "table" or #foeTypes == 0 then return out end

  local party = menu.party or (menu.game and menu.game.save
                               and menu.game.save.party)
  if type(party) ~= "table" then return out end

  local registry = (battle.data and battle.data.moves)
                or (menu.game and menu.game.data and menu.game.data.moves)
  local danger = enabled("dangerFlag")

  for i, mon in ipairs(party) do
    if type(mon) == "table" and mon.species then
      local text = markerFor({
        hp = mon.hp,
        types = typesOf(menu, battle, mon),
        moves = movesOf(battle, mon),
        moves_data = registry,
        foeTypes = foeTypes,
        danger = danger,
      })
      if text then out[#out + 1] = { text = text, slot = i } end
    end
  end
  return out
end

-- --------------------------------------------------- feature 1: the grades

do
  local ok, PartyMenu = pcall(require, "src.ui.PartyMenu")
  if not ok or type(PartyMenu) ~= "table" then
    mod.log:warn("src.ui.PartyMenu did not resolve, so party grades are off; "
      .. "this build is older than the mod's game_version floor -- update "
      .. "the game or disable " .. MOD_ID)
  elseif not PartyMenu._switchAdvisorGrades then
    -- Guard flag so a hot reload cannot stack wrappers.
    PartyMenu._switchAdvisorGrades = true

    local Font = require("src.render.Font")
    -- one bad frame must not become a warning per frame forever
    local broken = false

    local function drawMarkers(menu)
      -- every multiplier is resolved BEFORE a single pixel is touched, so
      -- the graphics state is only ever entered and left in one piece
      local marks = markersFor(menu)
      if #marks == 0 then return end
      -- restate the colour PartyMenu:draw uses for its own glyphs
      love.graphics.setColor(0, 0, 0, 1)
      for _, mark in ipairs(marks) do
        Font.draw(mark.text, 24, PartyMenu.entryY(mark.slot) + 8)
      end
      -- put back exactly what the wrapped draw left behind
      love.graphics.setColor(1, 1, 1, 1)
    end

    local vanillaDraw = PartyMenu.draw
    function PartyMenu:draw(...)
      local result = vanillaDraw(self, ...)
      if enabled("partyGrades") and not broken then
        local drawn, err = pcall(drawMarkers, self)
        if not drawn then
          broken = true
          mod.log:warn("party grades disabled for this session after a draw "
            .. "error: %s -- report it with this line and turn PARTY GRADES "
            .. "off to silence it", tostring(err))
        end
      end
      return result
    end
  end
end

-- -------------------------------------------- feature 2: skip the nickname
--
-- The capture sequence queues the prompt with
--   self:uiNext(function() return self:askNicknameUI(caught, name) end)
-- and updateQueue then does `stack:push(item.ui())`, so the factory MUST
-- return something pushable -- returning nil would push nil and strand the
-- battle with waitingUI set.
--
-- So instead of removing the step, we make it evaporate: hand back a state
-- that pops itself on its first update.  StateStack skips states with no
-- draw, and with no isOpaque the battle underneath keeps painting, so the
-- single frame it exists is invisible.  updateQueue clears waitingUI as
-- soon as the battle is back on top and the sequence carries on.
--
-- Renaming later still works: the PC's name screen is untouched.

-- The stand-in state.  `battle` is the BattleState the prompt was queued on.
local function dismissNickname(battle)
  -- the two pieces of state the vanilla path settles on its way out.
  -- blankForAskName blanks the battle scene behind the prompt; with no
  -- prompt it must stay false or the scene would be left blanked.
  battle.lockedBall = nil
  battle.blankForAskName = false
  local game = battle.game
  return {
    update = function()
      if game and game.stack then game.stack:pop() end
    end,
  }
end

do
  local ok, BattleState = pcall(require, "src.battle.BattleState")
  if not ok or type(BattleState) ~= "table" then
    mod.log:warn("src.battle.BattleState did not resolve, so the nickname "
      .. "prompt is untouched; this build is older than the mod's "
      .. "game_version floor -- update the game or disable " .. MOD_ID)
  elseif type(BattleState.askNicknameUI) ~= "function" then
    mod.log:warn("BattleState.askNicknameUI is missing, so the nickname "
      .. "prompt is untouched -- is another mod replacing the capture "
      .. "sequence? load " .. MOD_ID .. " after it, or turn SKIP NICKNAME off")
  elseif not BattleState._switchAdvisorSkipNickname then
    BattleState._switchAdvisorSkipNickname = true
    local vanillaAsk = BattleState.askNicknameUI
    function BattleState:askNicknameUI(mon, displayName)
      if not enabled("skipNickname") then
        return vanillaAsk(self, mon, displayName)
      end
      return dismissNickname(self)
    end
  end
end

-- ------------------------------------------------------------------ exports
--
-- The pure half of the mod, published so the suite in tests/ can drive the
-- decisions with fixture data and no graphics context.

mod.exports = {
  version = VERSION,
  offensePoints = offensePoints,
  defensePoints = defensePoints,
  grade = grade,
  markerFor = markerFor,
  markersFor = markersFor,
  dismissNickname = dismissNickname,
  enabled = enabled,
}

mod.log:info("%s %s ready (party grades + skip nickname)", MOD_ID, VERSION)
