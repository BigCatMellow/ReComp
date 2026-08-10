-- Controller Rumble: Gen 1 screen-shake sync + modern haptic extras.
--
-- Faithful layer: BattleState.fx / ElevatorShake amplitude -> motors.
-- Modern layer: damage/crit/faint/status/ball, catch/level-up/evolve,
-- trainer engage, blackout, footsteps, low-HP heartbeat.

local mod = ...

local V = { mod = mod, path = mod.path }

local function chunkFor(rel)
  local source = mod:read(rel)
  if not source then
    error(("CONTROLLER_RUMBLE: %s is missing -- reinstall the mod"):format(rel), 0)
  end
  local chunk, err = load(source, "@" .. mod.path .. "/" .. rel)
  if not chunk then
    error(("CONTROLLER_RUMBLE: %s did not compile: %s"):format(rel, tostring(err)), 0)
  end
  return chunk
end

local modules = {}
function V.require(name)
  local hit = modules[name]
  if hit ~= nil then return hit end
  local value = chunkFor("lib/" .. name .. ".lua")(V)
  modules[name] = value
  return value
end

local Settings = V.require("Settings")
local Rumble = V.require("Rumble")
local ShakeSync = V.require("ShakeSync")
local Extras = V.require("Extras")
local MenuRumble = V.require("MenuRumble")
local HpRumble = V.require("HpRumble")
local ExtraEvents = V.require("ExtraEvents")

mod.options:define(Settings.schema())

ShakeSync.install()
Extras.install(mod)
MenuRumble.install(mod)
HpRumble.install(mod)
ExtraEvents.install(mod)
V.require("OptionsScreen").install(mod)

-- Logic-step mixer + heartbeat clock (same ~60Hz clock as battle FX).
do
  local Game = require("src.core.Game")
  local prev = Game.step
  function Game:step(dt)
    prev(self, dt)
    Extras.tick(dt)
    Rumble.tick()
  end
end

mod.events:on("mod.options_changed", function(payload)
  Settings.syncFromPayload(payload)
end)

mod.events:on("battle.ended", function()
  Rumble.clearChannel("ambient")
  Rumble.clearChannel("impact")
end)

mod.log:info("controller rumble ready")
