-- Overworld Encounters – Expanded Version with Overworld Battles & Catching
-- Visible wild Pokémon spawns, 1-6 tile Pokéball throwing physics, delayed mon removal on impact,
-- pure left-right 3D wobble physics, vanilla encounters active with caught cell suppression,
-- follower battle chase, 1-tile gap attack animations, 160x144 UI overlays, and 100% PokePCFollowers compatibility.

return function(mod)
  print("[OverworldEncounters] Initializing expanded version with Battles & Catching...")

  -- Core dependencies
  local Game = require("src.core.Game")
  local BattleState = require("src.battle.BattleState")
  local OverworldController = require("src.world.OverworldController")
  local NPC = require("src.world.NPC")
  local Collision = require("src.world.Collision")

  -- Custom species database
  local modRequirePrefix = mod.path:gsub("[/\\]", ".")
  local Database = require(modRequirePrefix .. ".spawns.species_database")

  -- Require expanded submodules
  local CatchingModule = require(modRequirePrefix .. ".src.catching")
  local CombatModule = require(modRequirePrefix .. ".src.combat")
  local UIModule = require(modRequirePrefix .. ".src.ui")

  UIModule.setCatchingModule(CatchingModule)

  ---------------------------------------------------------------------------
  -- Vanilla grass encounter hook: allow encounters EXCEPT on caught cells
  ---------------------------------------------------------------------------

  if not OverworldController.__overworldEncountersRollWrapped then
    OverworldController.__overworldEncountersRollWrapped = true

    local origRollEncounter = OverworldController.rollEncounter
    OverworldController.rollEncounter = function(self, encDef, terrain)
      if self and self.map and self.player then
        if CatchingModule.isCellSuppressed(self.map.id, self.player.cellX, self.player.cellY) then
          return nil
        end
      end
      if origRollEncounter then
        return origRollEncounter(self, encDef, terrain)
      end
    end
  end

  mod.hooks:wrap("encounter.roll", function(next, encDef, ctx)
    if ctx and ctx.mapId and Game and Game.overworld and Game.overworld.player then
      local p = Game.overworld.player
      if CatchingModule.isCellSuppressed(ctx.mapId, p.cellX, p.cellY) then
        return nil
      end
    end
    return next(encDef, ctx)
  end)

  ---------------------------------------------------------------------------
  -- Native encounter table support
  ---------------------------------------------------------------------------

  local ENCOUNTER_WEIGHTS = { 20, 20, 15, 10, 10, 10, 5, 5, 4, 1 }

  local function getNativeLevelForMap(game, mapId)
    local encounters = game and game.data and game.data.encounters
    local mapEncounter = encounters and encounters[mapId]
    local grass = mapEncounter and mapEncounter.grass
    local slots = grass and grass.slots

    if not slots or #slots == 0 then return nil end

    local candidates = {}
    local totalWeight = 0

    for index, slot in ipairs(slots) do
      local weight = ENCOUNTER_WEIGHTS[index]
      if weight and slot.level then
        totalWeight = totalWeight + weight
        candidates[#candidates + 1] = {
          level = slot.level,
          cumulativeWeight = totalWeight,
        }
      end
    end

    if totalWeight == 0 then return nil end

    local roll = math.random(1, totalWeight)
    for _, candidate in ipairs(candidates) do
      if roll <= candidate.cumulativeWeight then
        return candidate.level
      end
    end

    return nil
  end

  ---------------------------------------------------------------------------
  -- Time-of-day encounter selection
  ---------------------------------------------------------------------------

  local function hourToPeriod(hour)
    if hour >= 5 and hour < 9 then return "MORN"
    elseif hour >= 9 and hour < 18 then return "DAY"
    else return "NITE" end
  end

  local function getActiveTimePeriod()
    local override = _G.YELLOW_CRYSTAL_TIME_OVERRIDE
    if override ~= nil then return hourToPeriod(override) end

    if _G.DRAMATIC_SHAPE and _G.DRAMATIC_SHAPE.DayNight and _G.DRAMATIC_SHAPE.DayNight.time then
      local timeValue = (_G.DRAMATIC_SHAPE.DayNight.time() or 300) % 1200
      if timeValue < 200 then return "MORN"
      elseif timeValue < 550 then return "DAY"
      else return "NITE" end
    end

    local date = os.date("*t")
    local hour = (date and date.hour) or 12
    return hourToPeriod(hour)
  end

  local function chooseEncounter(game, mapId, period)
    local pool = Database.getPoolForMap(mapId, period, game)
    if not pool or #pool == 0 then return nil end

    local species
    for _ = 1, 5 do
      local candidate = pool[math.random(1, #pool)]
      if candidate and not Database.EXCLUDED_LEGENDARIES[candidate] then
        species = candidate
        break
      end
    end
    if not species then return nil end

    local level = getNativeLevelForMap(game, mapId) or math.random(3, 15)
    return { species = species, level = level, source = "timed" }
  end

  ---------------------------------------------------------------------------
  -- Sprite registration
  ---------------------------------------------------------------------------

  local ALL_GEN1_SPECIES = {
    "BULBASAUR", "IVYSAUR", "VENUSAUR", "CHARMANDER", "CHARMELEON", "CHARIZARD",
    "SQUIRTLE", "WARTORTLE", "BLASTOISE", "CATERPIE", "METAPOD", "BUTTERFREE",
    "WEEDLE", "KAKUNA", "BEEDRILL", "PIDGEY", "PIDGEOTTO", "PIDGEOT",
    "RATTATA", "RATICATE", "SPEAROW", "FEAROW", "EKANS", "ARBOK",
    "PIKACHU", "RAICHU", "SANDSHREW", "SANDSLASH", "NIDORAN_F", "NIDORINA",
    "NIDOQUEEN", "NIDORAN_M", "NIDORINO", "NIDOKING", "CLEFAIRY", "CLEFABLE",
    "VULPIX", "NINETALES", "JIGGLYPUFF", "WIGGLYTUFF", "ZUBAT", "GOLBAT",
    "ODDISH", "GLOOM", "VILEPLUME", "PARAS", "PARASECT", "VENONAT",
    "VENOMOTH", "DIGLETT", "DUGTRIO", "MEOWTH", "PERSIAN", "PSYDUCK",
    "GOLDUCK", "MANKEY", "PRIMEAPE", "GROWLITHE", "ARCANINE", "POLIWAG",
    "POLIWHIRL", "POLIWRATH", "ABRA", "KADABRA", "ALAKAZAM", "MACHOP",
    "MACHOKE", "MACHAMP", "BELLSPROUT", "WEEPINBELL", "VICTREEBEL", "TENTACOOL",
    "TENTACRUEL", "GEODUDE", "GRAVELER", "GOLEM", "PONYTA", "RAPIDASH",
    "SLOWPOKE", "SLOWBRO", "MAGNEMITE", "MAGNETON", "FARFETCHD", "DODUO",
    "DODRIO", "SEEL", "DEWGONG", "GRIMER", "MUK", "SHELLDER",
    "CLOYSTER", "GASTLY", "HAUNTER", "GENGAR", "ONIX", "DROWZEE",
    "HYPNO", "KRABBY", "KINGLER", "VOLTORB", "ELECTRODE", "EXEGGCUTE",
    "EXEGGUTOR", "CUBONE", "MAROWAK", "HITMONLEE", "HITMONCHAN", "LICKITUNG",
    "KOFFING", "WEEZING", "RHYHORN", "RHYDON", "CHANSEY", "TANGELA",
    "KANGASKHAN", "HORSEA", "SEADRA", "GOLDEEN", "SEAKING", "STARYU",
    "STARMIE", "MR_MIME", "SCYTHER", "JYNX", "ELECTABUZZ", "MAGMAR",
    "PINSIR", "TAUROS", "MAGIKARP", "GYARADOS", "LAPRAS", "DITTO",
    "EEVEE", "VAPOREON", "JOLTEON", "FLAREON", "PORYGON", "OMANYTE",
    "OMASTAR", "KABUTO", "KABUTOPS", "AERODACTYL", "SNORLAX", "ARTICUNO",
    "ZAPDOS", "MOLTRES", "DRATINI", "DRAGONAIR", "DRAGONITE", "MEWTWO", "MEW"
  }

  local function spriteIdFor(species) return "SPRITE_WILD_" .. species end
  local function spritePathFor(species) return mod.path .. "/assets/sprites/follower_" .. species .. ".png" end

  for _, species in ipairs(ALL_GEN1_SPECIES) do
    pcall(function()
      mod.content.sprites:register(spriteIdFor(species), {
        image = spritePathFor(species),
        frames = 6,
        walker = true,
        trueColor = true,
      })
    end)
  end

  local BALL_TYPES = { "POKE_BALL", "GREAT_BALL", "ULTRA_BALL", "MASTER_BALL", "SAFARI_BALL" }
  for _, bType in ipairs(BALL_TYPES) do
    pcall(function()
      mod.content.sprites:register("SPRITE_BALL_" .. bType, {
        image = mod.path .. "/assets/sprites/ball_" .. bType:lower() .. ".png",
        frames = 1,
        walker = false,
        trueColor = true,
      })
    end)
  end

  ---------------------------------------------------------------------------
  -- Active wild NPC management & spawning
  ---------------------------------------------------------------------------

  local activeWildNpcs = {}
  local lastSpawnTime = 0
  local currentPeriod = "DAY"

  local function removeFromArray(array, target)
    if not array then return end
    for i = #array, 1, -1 do
      if array[i] == target then table.remove(array, i) return end
    end
  end

  local function removeWildNpc(ow, wildNpc)
    if not ow or not wildNpc then return end
    removeFromArray(ow.npcs, wildNpc)
    removeFromArray(ow.entities, wildNpc)
    activeWildNpcs[wildNpc] = nil
  end

  local function clearAllWildNpcs(ow)
    if not ow then return end
    local pending = {}
    for wildNpc in pairs(activeWildNpcs) do pending[#pending + 1] = wildNpc end
    for _, wildNpc in ipairs(pending) do removeWildNpc(ow, wildNpc) end
    activeWildNpcs = {}
  end

  local function ensureSpriteDefinition(game, species)
    if not game or not game.data or not game.data.sprites then return end
    local id = spriteIdFor(species)
    if game.data.sprites[id] then return end
    game.data.sprites[id] = {
      id = id,
      image = spritePathFor(species),
      frames = 6,
      walker = true,
      trueColor = true,
    }
  end

  local function findSpawnCell(ow, map)
    local player = ow.player
    local px = player and player.cellX or 5
    local py = player and player.cellY or 5

    local width = map.widthCells or (map.width and map.width * 2) or 20
    local height = map.heightCells or (map.height and map.height * 2) or 20

    for _ = 1, 100 do
      local x = math.random(0, math.max(0, width - 1))
      local y = math.random(0, math.max(0, height - 1))
      local dist = math.abs(x - px) + math.abs(y - py)
      if dist >= 3 and dist <= 12 and map:inBounds(x, y) and (map:isWalkableCell(x, y) or map:isGrassCell(x, y)) then
        if not Collision.occupied(ow.entities, x, y, nil) then
          return x, y
        end
      end
    end
    return nil, nil
  end

  local function spawnWildPokemon(game, ow)
    if not game or not ow or not ow.map then return end
    local map = ow.map
    local mapId = map.id

    if not Database.isWildMap(mapId) then return end

    local period = getActiveTimePeriod()
    local encounter = chooseEncounter(game, mapId, period)
    if not encounter then return end

    local spawnX, spawnY = findSpawnCell(ow, map)
    if not spawnX or not spawnY then return end

    ensureSpriteDefinition(game, encounter.species)

    local wildNpc = NPC.new(game.data, mapId, {
      index = 200 + math.random(1, 50),
      name = "WILD_" .. encounter.species,
      sprite = spriteIdFor(encounter.species),
      movement = "WALK",
      range = "ANY",
      x = spawnX,
      y = spawnY,
    })

    wildNpc.isOverworldWildPokemon = true
    wildNpc.mapId = mapId
    wildNpc.wildSpecies = encounter.species
    wildNpc.wildLevel = encounter.level
    wildNpc.maxHp = math.floor(encounter.level * 2.5 + 10)
    wildNpc.currentHp = wildNpc.maxHp
    wildNpc.passable = true
    wildNpc.lifespan = 35 + math.random(0, 15)

    table.insert(ow.npcs, wildNpc)
    table.insert(ow.entities, wildNpc)
    activeWildNpcs[wildNpc] = true
  end

  local function updateWildSpawns(game, ow)
    if not ow or not ow.map then return end
    local mapId = ow.map.id

    if not Database.isWildMap(mapId) then
      clearAllWildNpcs(ow)
      return
    end

    local period = getActiveTimePeriod()
    if period ~= currentPeriod then
      currentPeriod = period
      clearAllWildNpcs(ow)
    end

    local targetCount = Database.getTargetCount(mapId) or 3
    local activeCount = 0
    local staleNpcs = {}

    for wildNpc in pairs(activeWildNpcs) do
      if wildNpc.mapId == mapId then
        activeCount = activeCount + 1
      else
        staleNpcs[#staleNpcs + 1] = wildNpc
      end
    end

    for _, wildNpc in ipairs(staleNpcs) do removeWildNpc(ow, wildNpc) end

    local now = love.timer and love.timer.getTime() or os.time()
    if activeCount < targetCount and (now - lastSpawnTime) >= 2.0 then
      lastSpawnTime = now
      spawnWildPokemon(game, ow)
    end
  end

  ---------------------------------------------------------------------------
  -- Engine hooks (OverworldController update, drawUI, and inputs)
  ---------------------------------------------------------------------------

  if not OverworldController.__overworldEncountersWrapped then
    OverworldController.__overworldEncountersWrapped = true

    local origOverworldUpdate = OverworldController.update
    OverworldController.update = function(self, dt)
      if origOverworldUpdate then origOverworldUpdate(self, dt) end

      OverworldController.currentActive = self

      local player = self.player
      if not player then return end

      pcall(updateWildSpawns, Game, self)

      local elapsed = dt or 0.016
      local pendingRemoval = {}
      local collidedNpc

      for wildNpc in pairs(activeWildNpcs) do
        wildNpc.lifespan = (wildNpc.lifespan or 35) - elapsed

        local dist = math.abs(wildNpc.cellX - player.cellX) + math.abs(wildNpc.cellY - player.cellY)

        if wildNpc.lifespan <= 0 or dist > 18 then
          pendingRemoval[#pendingRemoval + 1] = wildNpc
        elseif wildNpc.cellX == player.cellX and wildNpc.cellY == player.cellY and not wildNpc.isBeingCaught then
          collidedNpc = wildNpc
          break
        end
      end

      for _, wildNpc in ipairs(pendingRemoval) do removeWildNpc(self, wildNpc) end

      if collidedNpc then
        local species = collidedNpc.wildSpecies or "PIDGEY"
        local level = collidedNpc.wildLevel or 5
        removeWildNpc(self, collidedNpc)

        if BattleState and BattleState.newWild then
          local battle = BattleState.newWild(Game, species, level)
          if battle then Game.stack:push(battle) end
        end
      end

      -- Update Submodules
      pcall(CatchingModule.update, Game, self, dt, UIModule)
      pcall(CombatModule.update, Game, self, dt, UIModule)
      pcall(UIModule.update, dt)
    end
  end

  -- Screen-space UI draw hook (160x144 canvas for Poké Ball selector and notification banners)
  if not OverworldController.__overworldEncountersDrawUIWrapped then
    OverworldController.__overworldEncountersDrawUIWrapped = true

    local origDrawUI = OverworldController.drawUI
    OverworldController.drawUI = function(self, ...)
      if origDrawUI then origDrawUI(self, ...) end
      pcall(UIModule.drawScreen, Game, self)
    end
  end

  ---------------------------------------------------------------------------
  -- Keybindings Hook
  ---------------------------------------------------------------------------

  if love and not _G.__overworldEncountersKeyWrapped then
    _G.__overworldEncountersKeyWrapped = true
    local origKeypressed = love.keypressed

    love.keypressed = function(key, scancode, isrepeat)
      if origKeypressed then origKeypressed(key, scancode, isrepeat) end

      local ow = OverworldController.currentActive
      if not ow then return end

      -- Safety: Only process inputs when active in overworld (not in menus, dialogs, or battles)
      if Game.stack and Game.stack:top() ~= ow then return end
      if ow.textbox and ow.textbox:active() then return end

      key = string.lower(tostring(key))
      if key == "c" or key == "r" then
        CatchingModule.throwBall(Game, ow, UIModule)
      elseif key == "q" then
        CatchingModule.cycleSelectedBall(Game, -1)
      elseif key == "e" then
        CatchingModule.cycleSelectedBall(Game, 1)
      elseif key == "v" or key == "f" then
        CombatModule.commandFollowerAttack(Game, ow, UIModule)
      end
    end
  end

  if mod.log then
    mod.log:info("Overworld Encounters – expanded version with battles & catching loaded successfully.")
  else
    print("[OverworldEncounters] Mod initialized successfully.")
  end
end