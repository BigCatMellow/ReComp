-- Useful Move Info: pressing Start -- or Q on a keyboard -- while a move
-- is highlighted in battle opens an info box with the move's type, power,
-- accuracy and effect. The box is a TextBox, so the battle is frozen
-- underneath (the state stack updates only its top state) and A/B closes
-- it.
--
-- For damaging moves the box also appends a type-effectiveness line
-- against the foe's current types (SUPER EFFECTIVE / NOT VERY EFFECTIVE /
-- NO EFFECT), resolved through the engine's TypeChart.
--
-- The same Start/Q shortcut works on the "which move should be forgotten?"
-- list when a Pokémon learns a new move: it inspects the highlighted
-- current move, and a dedicated NEW MOVE row (before CANCEL) lets you read
-- the move being learned before deciding what to forget.
--
-- Start is a Game Boy button, but the battle's move-select phase never
-- reads it (no vanilla shortcut), so the mod steals its raw gamepad edge:
-- Input.gamepadpressed fires before Input:step promotes the press into
-- the fixed-step bindings, and tryOpen consumes the edge inside a wrapped
-- BattleState.update, where phase and moveIndex are current. Keyboard
-- stays Q (Input.keypressed/keyreleased for "q"). A held latch stops
-- auto-repeat from re-triggering while the box is open.
local EFFECTS = {
  NO_ADDITIONAL_EFFECT = "No extra effect",
  EFFECT_01 = "No extra effect",
  EFFECT_1E = "No extra effect",
  UNUSED = "No extra effect",
  POISON_SIDE_EFFECT1 = "20% poison chance",
  POISON_SIDE_EFFECT2 = "40% poison chance",
  BURN_SIDE_EFFECT1 = "10% burn chance",
  BURN_SIDE_EFFECT2 = "30% burn chance",
  FREEZE_SIDE_EFFECT1 = "10% freeze chance",
  FREEZE_SIDE_EFFECT2 = "30% freeze chance",
  PARALYZE_SIDE_EFFECT1 = "10% paralysis chance",
  PARALYZE_SIDE_EFFECT2 = "30% paralysis chance",
  FLINCH_SIDE_EFFECT1 = "10% flinch chance",
  FLINCH_SIDE_EFFECT2 = "30% flinch chance",
  CONFUSION_SIDE_EFFECT = "10% confusion chance",
  ATTACK_DOWN_SIDE_EFFECT = "10% ATK drop",
  DEFENSE_DOWN_SIDE_EFFECT = "10% DEF drop",
  SPEED_DOWN_SIDE_EFFECT = "10% SPD drop",
  SPECIAL_DOWN_SIDE_EFFECT = "10% SPC drop",
  SLEEP_EFFECT = "Puts the foe to sleep",
  POISON_EFFECT = "May poison the foe",
  PARALYZE_EFFECT = "May paralyze the foe",
  CONFUSION_EFFECT = "Confuses the foe",
  DRAIN_HP_EFFECT = "Drains 50% of damage",
  DREAM_EATER_EFFECT = "Drains HP from sleeping foe",
  EXPLODE_EFFECT = "User faints",
  PAY_DAY_EFFECT = "Scatters money after battle",
  SWIFT_EFFECT = "Never misses",
  CONVERSION_EFFECT = "Changes user's type",
  HAZE_EFFECT = "Resets stat changes",
  BIDE_EFFECT = "Stores damage 2-3 turns",
  THRASH_PETAL_DANCE_EFFECT = "2-3 turns, then confusion",
  SWITCH_AND_TELEPORT_EFFECT = "Switches / escapes battle",
  TWO_TO_FIVE_ATTACKS_EFFECT = "Hits 2-5 times",
  OHKO_EFFECT = "One-hit KO if it lands",
  CHARGE_EFFECT = "Charges up turn 1",
  SUPER_FANG_EFFECT = "Halves the foe's HP",
  SPECIAL_DAMAGE_EFFECT = "Deals fixed damage",
  TRAPPING_EFFECT = "Traps for 2-5 turns",
  FLY_EFFECT = "Flies up on turn 1",
  ATTACK_TWICE_EFFECT = "Hits twice",
  TWINEEDLE_EFFECT = "Hits twice, 20% poison",
  JUMP_KICK_EFFECT = "1/8 crash damage on miss",
  RECOIL_EFFECT = "1/4 of damage as recoil",
  HYPER_BEAM_EFFECT = "Recharge next turn",
  RAGE_EFFECT = "ATK rises when hit",
  MIMIC_EFFECT = "Copies one of the foe's moves",
  METRONOME_EFFECT = "Uses a random move",
  LEECH_SEED_EFFECT = "Seeds the foe",
  SPLASH_EFFECT = "Does nothing",
  DISABLE_EFFECT = "Disables one foe move",
  SUBSTITUTE_EFFECT = "Creates a decoy",
  TRANSFORM_EFFECT = "Copies the foe",
  HEAL_EFFECT = "Restores HP",
  MIST_EFFECT = "Protects stat changes",
  FOCUS_ENERGY_EFFECT = "Boosts crit chance",
  LIGHT_SCREEN_EFFECT = "Halves special damage",
  REFLECT_EFFECT = "Halves physical damage",
  MIRROR_MOVE_EFFECT = "Copies the foe's last move",
  ATTACK_UP1_EFFECT = "Raises user's ATK",
  DEFENSE_UP1_EFFECT = "Raises user's DEF",
  SPEED_UP1_EFFECT = "Raises user's SPD",
  SPECIAL_UP1_EFFECT = "Raises user's SPC",
  ACCURACY_UP1_EFFECT = "Raises user's ACC",
  EVASION_UP1_EFFECT = "Raises user's EVASION",
  ATTACK_UP2_EFFECT = "Sharply raises user's ATK",
  DEFENSE_UP2_EFFECT = "Sharply raises user's DEF",
  SPEED_UP2_EFFECT = "Sharply raises user's SPD",
  SPECIAL_UP2_EFFECT = "Sharply raises user's SPC",
  ACCURACY_UP2_EFFECT = "Sharply raises user's ACC",
  EVASION_UP2_EFFECT = "Sharply raises user's EVASION",
  ATTACK_DOWN1_EFFECT = "Lowers foe's ATK",
  DEFENSE_DOWN1_EFFECT = "Lowers foe's DEF",
  SPEED_DOWN1_EFFECT = "Lowers foe's SPD",
  SPECIAL_DOWN1_EFFECT = "Lowers foe's SPC",
  ACCURACY_DOWN1_EFFECT = "Lowers foe's ACC",
  EVASION_DOWN1_EFFECT = "Lowers foe's EVASION",
  ATTACK_DOWN2_EFFECT = "Sharply lowers foe's ATK",
  DEFENSE_DOWN2_EFFECT = "Sharply lowers foe's DEF",
  SPEED_DOWN2_EFFECT = "Sharply lowers foe's SPD",
  SPECIAL_DOWN2_EFFECT = "Sharply lowers foe's SPC",
  ACCURACY_DOWN2_EFFECT = "Sharply lowers foe's ACC",
  EVASION_DOWN2_EFFECT = "Sharply lowers foe's EVASION",
}

local function humanize(id)
  local s = id:gsub("_", " "):lower()
  return s:gsub("(%a)([%w]*)", function(a, rest)
    return a:upper() .. rest
  end)
end

-- Display text for an effect id: curated description, else a readable
-- version of the id (covers mod-added effects and unknown ids).
local function effectText(id)
  if id == nil then return "Unknown" end
  return EFFECTS[id] or humanize(id)
end

-- x10 multiplier -> compact "x2"/"x0.5"/"x0" text (TypeChart multiplies
-- per row with a floor, so 2x2 matchups can land on non-tenths).
local function multText(mult)
  if mult == 0 then return "x0" end
  if mult % 10 == 0 then return ("x%d"):format(mult / 10) end
  return ("x%.1f"):format(mult / 10)
end

-- Human effectiveness readout for a move against a defender's types.
-- Returns nil when the chart is unavailable or no types were given (the
-- learn-move screen has no foe, so its boxes skip the line).
local function effectivenessLabel(data, moveType, defenderTypes)
  if not (data and data.type_chart and data.type_chart.matchups
          and moveType and defenderTypes and #defenderTypes > 0) then
    return nil
  end
  local TypeChart = require("src.battle.TypeChart")
  TypeChart.load(data)
  local mult = TypeChart.effectiveness(moveType, defenderTypes)
  local label
  if mult == 0 then
    label = "NO EFFECT"
  elseif mult >= 20 then
    label = "SUPER EFFECTIVE"
  elseif mult < 10 then
    label = "NOT VERY EFFECTIVE"
  else
    label = "NEUTRAL"
  end
  local names = {}
  for _, t in ipairs(defenderTypes) do
    table.insert(names, TypeChart.displayName(t))
  end
  return ("VS %s: %s (%s)"):format(table.concat(names, "/"), label, multText(mult))
end

-- Pure builder (published as mod.exports.infoText for headless tests).
-- Lines are joined with \v (ContText), so TextBox waits for an A/B press
-- between every line instead of flowing straight through the box.
-- `defenderTypes` (a list of type ids, e.g. a battler's curTypes) adds a
-- type-effectiveness line for damaging moves; status and fixed-damage
-- moves (power 0) never use the type chart, so they omit it.
local function infoText(data, moveDef, defenderTypes)
  local power = (moveDef.power or 0) > 0 and tostring(moveDef.power) or "--"
  local acc = (moveDef.accuracy or 0) > 0 and tostring(moveDef.accuracy) or "--"
  local lines = {
    moveDef.name or moveDef.id,
    "TYPE: " .. (moveDef.type or "?"),
    "PWR: " .. power,
    "ACC: " .. acc,
    "EFFECT: " .. effectText(moveDef.effect),
  }
  if (moveDef.power or 0) > 0 then
    local vs = effectivenessLabel(data, moveDef.type, defenderTypes)
    if vs then table.insert(lines, vs) end
  end
  return table.concat(lines, "\v")
end

local state = { padHeld = false, qHeld = false, edge = false, open = false }

local Font = require("src.render.Font")
local Strings = require("src.core.Strings")

-- Consume one press edge; when the battle is on the move-select phase and
-- the highlighted slot holds a known move, hand `push` the info text and
-- mark the box open (presses while open are dropped, and the edge can
-- never survive a box session -- a lingering edge would reopen the box the
-- instant it closed). Returns true (and the text) when it opened.
local function tryOpen(battle, push)
  if not state.edge then return false end
  state.edge = false
  if state.open then return false end
  if not (battle and battle.phase == "moveSelect") then return false end
  local moves = battle.player and battle.player.curMoves
  local mv = moves and moves[battle.moveIndex]
  if not (mv and mv.id) then return false end
  local moveDef = battle.data and battle.data.moves and battle.data.moves[mv.id]
  if not moveDef then return false end
  local text = infoText(battle.data, moveDef,
    battle.enemy and battle.enemy.curTypes)
  state.open = true
  if push then
    if not pcall(push, text) then
      state.open = false
      return false
    end
  end
  return true, text
end

local function installInputWrappers(Input)
  local vanillaPress, vanillaRelease = Input.gamepadpressed, Input.gamepadreleased
  Input.gamepadpressed = function(self, joystick, button)
    if button == "start" then
      -- while the box is open a press is dropped, never queued: the
      -- battle is frozen so the edge would linger and reopen the box
      if not state.padHeld and not state.open then state.edge = true end
      state.padHeld = true
    end
    return vanillaPress(self, joystick, button)
  end
  Input.gamepadreleased = function(self, joystick, button)
    if button == "start" then state.padHeld = false end
    return vanillaRelease(self, joystick, button)
  end
  local vanillaKeyPress, vanillaKeyRelease = Input.keypressed, Input.keyreleased
  Input.keypressed = function(self, key)
    if key == "q" then
      -- the held latch swallows auto-repeat presses
      if not state.qHeld and not state.open then state.edge = true end
      state.qHeld = true
    end
    return vanillaKeyPress(self, key)
  end
  Input.keyreleased = function(self, key)
    if key == "q" then state.qHeld = false end
    return vanillaKeyRelease(self, key)
  end
  local vanillaReset = Input.reset
  Input.reset = function(self)
    state.edge, state.qHeld, state.padHeld, state.open = false, false, false, false
    return vanillaReset(self)
  end
end

local function installBattleWrapper()
  local BattleState = require("src.battle.BattleState")
  local vanillaUpdate = BattleState.update
  BattleState.update = function(self, dt)
    vanillaUpdate(self, dt)
    tryOpen(self, function(text)
      local TextBox = require("src.render.TextBox")
      self.game.stack:push(TextBox.new(self.game, text, function()
        state.open = false
      end))
    end)
  end
end

-- The "which move should be forgotten?" list (learn_move.asm).  The mod
-- registers a MoveLearnMenu screen override so Start/Q inspects a move
-- while deciding: the highlighted current move, or the NEW MOVE row (a
-- dedicated, never-forgettable row before CANCEL) so you can read what
-- the move being learned does before picking what to drop.
local HM_MOVES = {
  CUT = true, FLY = true, SURF = true, STRENGTH = true, FLASH = true,
}
local CURSOR = 0xED

-- Registered at load time (the registries freeze after load); the factory
-- runs when the screen is pushed, so it can require the builtin lazily.
local function installLearnMenuWrapper(mod)
  mod.content.screens:register("MoveLearnMenu", {
    new = function(game, mon, newMoveId, onDone)
      local VanillaMenu = require("src.ui.MoveLearnMenu")
      local self = VanillaMenu.new(game, mon, newMoveId, onDone)

      -- update: Start/Q inspection + navigation across moves + NEW + CANCEL
      local vanillaUpdate = self.update
      self.update = function(self, dt)
        -- entering/leaving the forget list: drop a lingering info edge so
        -- a press made during the preamble can't open a box the instant
        -- the list appears
        if self.selecting ~= self.__selecting then
          state.edge = false
          self.__selecting = self.selecting
        end
        if not self.selecting then
          return vanillaUpdate(self, dt)
        end
        -- Start / Q: inspect the highlighted move (current moves or NEW)
        if state.edge then
          state.edge = false
          local n = #self.mon.moves
          local mdef
          if self.index <= n then
            local mv = self.mon.moves[self.index]
            mdef = self.game.data.moves[mv.id]
          elseif self.index == n + 1 then
            mdef = self.game.data.moves[self.newMoveId]
          end
          if mdef then
            state.open = true
            local TextBox = require("src.render.TextBox")
            self.game.stack:push(TextBox.new(self.game,
              infoText(self.game.data, mdef), function()
                state.open = false
              end))
            return
          end
        end
        -- rows: the current moves, the NEW move, then CANCEL
        local input = self.game.input
        local n = #self.mon.moves + 2
        if input:wasPressed("up") then
          self.index = self.index > 1 and self.index - 1 or n
        elseif input:wasPressed("down") then
          self.index = self.index < n and self.index + 1 or 1
        elseif input:wasPressed("b") then
          self:confirmAbandon()
        elseif input:wasPressed("a") then
          if self.index > #self.mon.moves then
            -- the NEW move row is inspect-only; CANCEL abandons
            if self.index == n then self:confirmAbandon() end
          else
            local old = self.mon.moves[self.index]
            if HM_MOVES[old.id] then
              local TextBox = require("src.render.TextBox")
              self.game.stack:push(TextBox.new(self.game,
                Strings("HM techniques\ncan't be deleted!")))
              return
            end
            local mdef = self.game.data.moves[self.newMoveId]
            self.mon.moves[self.index] = { id = self.newMoveId, pp = mdef.pp }
            self.forgot = self.game.data.moves[old.id].name
            self:finish(true)
          end
        end
      end

      -- draw: the same list plus the NEW MOVE row (box grows one row up)
      local vanillaDraw = self.draw
      self.draw = function(self)
        if not self.selecting then return end
        Font.drawBox(4, 4, 16, 8)
        love.graphics.setColor(0, 0, 0, 1)
        for i, mv in ipairs(self.mon.moves) do
          Font.draw(self.game.data.moves[mv.id].name, 48, (4 + i) * 8)
        end
        local nm = self.game.data.moves[self.newMoveId]
        local label = nm and nm.name or self.newMoveId
        if Font.width(label) + Font.width(" NEW") <= 100 then
          label = label .. " NEW"
        end
        Font.draw(label, 48, (4 + #self.mon.moves + 1) * 8)
        Font.draw(Strings("CANCEL"), 48, (4 + #self.mon.moves + 2) * 8)
        Font.drawCode(CURSOR, 40, (4 + self.index) * 8)
        Font.drawBox(0, 12, 20, 6)
        Font.draw(Strings("Which move should"), 8, 14 * 8)
        Font.draw(Strings("be forgotten?"), 8, 16 * 8)
        love.graphics.setColor(1, 1, 1, 1)
      end

      return self
    end,
  })
end

return function(mod)
  -- the MoveLearnMenu override is registered at load time (registries
  -- freeze after load); the battle/input wrappers need the live game
  installLearnMenuWrapper(mod)
  mod.events:on("game.ready", function()
    installInputWrappers(require("src.core.Input"))
    installBattleWrapper()
  end)

  mod.exports = {
    infoText = infoText,
    effectivenessLabel = effectivenessLabel,
    effectText = effectText,
    state = state,
    tryOpen = tryOpen,
  }
end
