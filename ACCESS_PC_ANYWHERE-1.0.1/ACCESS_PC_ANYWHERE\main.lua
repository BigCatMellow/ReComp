-- Access PC Anywhere: Start menu -> PC
return function(mod)
  local Strings = require("src.core.Strings")
  local TextBox = require("src.render.TextBox")
  local Screens = require("src.ui.Screens")
  local Map = require("src.world.Map")
  local FieldDefaults = require("src.world.FieldDefaults")

  mod.options:define({
    {
      key = "overworld_only",
      type = "toggle",
      label = "OVERWORLD ONLY",
      default = true,
      help = "When ON, PC only appears outdoors (not inside buildings).",
    },
  })

  local optCache = {}
  local function optBool(key, default)
    if optCache[key] ~= nil then return optCache[key] end
    local ok, got = pcall(mod.options.get, mod.options, key)
    optCache[key] = (ok and got ~= nil) and (got and true or false) or default
    return optCache[key]
  end

  local function setOpt(key, value, game)
    optCache[key] = value and true or false
    pcall(function() mod.options:set(key, value and true or false) end)
    if game and game.save then
      game.save.options = game.save.options or {}
      game.save.options.modOptions = game.save.options.modOptions or {}
      game.save.options.modOptions[mod.id] =
        game.save.options.modOptions[mod.id] or {}
      game.save.options.modOptions[mod.id][key] = value and true or false
    end
    if game and game.mods then
      game.mods.modOptions = game.mods.modOptions or {}
      game.mods.modOptions[mod.id] = game.mods.modOptions[mod.id] or {}
      game.mods.modOptions[mod.id][key] = value and true or false
    end
    if game and game.writeOptions then pcall(game.writeOptions, game) end
  end

  mod.events:on("mod.options_changed", function(payload)
    if payload and payload.mod == mod.id then
      optCache[payload.key] = payload.value
    end
  end)

  -- True outdoors only (towns/routes/plateau). Buildings/caves fail this.
  local function isOutdoors(game)
    local ow = game and game.overworld
    local def = ow and ow.map and ow.map.def
    if not def then return false end
    local tilesets = FieldDefaults.field(game.data, "outsideTilesets")
    return Map.isOutside(def, tilesets)
  end

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    items = next(game, items) or items
    if optBool("overworld_only", true) and not isOutdoors(game) then
      return items
    end
    table.insert(items, {
      label = Strings("PC"),
      onSelect = function()
        if optBool("overworld_only", true) and not isOutdoors(game) then
          game.stack:push(TextBox.new(game,
            Strings("PC is not\navailable now.")))
          return
        end
        local ow = game.overworld
        if not ow or not ow.openPC then
          game.stack:push(TextBox.new(game,
            Strings("PC is not\navailable now.")))
          return
        end
        pcall(function() ow:openPC() end)
      end,
    })
    return items
  end)

  -- OPTIONS submenu (QoL-style OPEN row)
  local PC_SCREEN = "AccessPcAnywhereOptions"

  local function makePcScreen(game)
    local OptionRows = require("src.ui.OptionRows")
    local rows = {
      {
        label = "OVERWORLD ONLY",
        value = function()
          return optBool("overworld_only", true) and "ON" or "OFF"
        end,
        step = function(g)
          setOpt("overworld_only", not optBool("overworld_only", true), g)
        end,
      },
    }
    local screen = {
      game = game, rows = rows, index = 1, scroll = 0, isOpaque = true,
    }
    function screen:sgbPalettes(g)
      return require("src.render.PaletteFX").wholeNamed(g.data, "MEWMON")
    end
    function screen:update()
      local input = self.game.input
      if input:wasPressed("up") then
        self.index = (self.index - 2) % #self.rows + 1
      elseif input:wasPressed("down") then
        self.index = self.index % #self.rows + 1
      elseif input:wasPressed("left") or input:wasPressed("right")
          or input:wasPressed("a") then
        local row = self.rows[self.index]
        if row and row.step then row.step(self.game) end
      elseif input:wasPressed("b") then
        self.game.stack:pop()
      end
      self.scroll = OptionRows.clampScroll(
        self.index, self.scroll, #self.rows, nil)
    end
    function screen:draw()
      OptionRows.draw(self.game, self.rows, self.index, self.scroll,
                      "A/◀▶:CHANGE B:DONE")
    end
    return screen
  end

  mod.content.screens:register(PC_SCREEN, { new = makePcScreen })

  mod.events:once("mods.loaded", function()
    local ManagerState = require("src.mods.ManagerState")
    local routes = rawget(ManagerState, "__modOptionScreenRoutes")
    if not routes then
      routes = {}
      local openOptions = ManagerState.openOptions
      ManagerState.openOptions = function(self, manifest)
        local screenId = manifest and routes[manifest.id]
        if screenId then
          return Screens.push(self.game, screenId)
        end
        return openOptions(self, manifest)
      end
      ManagerState.__modOptionScreenRoutes = routes
    end
    routes[mod.id] = PC_SCREEN
  end)

  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) ~= "table" then return out end
    local row = {
      id = mod.id .. ":open",
      label = "ACCESS PC",
      value = function() return "OPEN" end,
      activate = function(g)
        Screens.push(g, PC_SCREEN)
      end,
    }
    if mod.ui and type(mod.ui.insertBefore) == "function" then
      return mod.ui.insertBefore(out, "MODS", row)
    end
    out[#out + 1] = row
    return out
  end)

  mod.exports.version = "1.0.1"
  mod.log:info("ACCESS_PC_ANYWHERE 1.0.1")
end
