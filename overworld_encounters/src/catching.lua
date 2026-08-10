-- Overworld Encounters - Catching Module
-- Handles Poké Ball selection, 1-6 tile throwing trajectory physics,
-- delayed wild mon removal when ball impacts, 3D/2.5D left-right wobble physics,
-- authentic vanilla TextBox prompt integration, catch calculations, and escape-to-battle state transitions.

local CatchingModule = {}

local Catching = require("src.battle.Catching")
local Pokemon = require("src.pokemon.Pokemon")
local Party = require("src.pokemon.Party")
local Boxes = require("src.pokemon.Boxes")
local Bag = require("src.inventory.Bag")
local BattleState = require("src.battle.BattleState")
local TextBox = require("src.render.TextBox")
local NPC = require("src.world.NPC")

CatchingModule.BALL_TYPES = {
  "POKE_BALL",
  "GREAT_BALL",
  "ULTRA_BALL",
  "MASTER_BALL",
  "SAFARI_BALL",
}

CatchingModule.BALL_NAMES = {
  POKE_BALL = "Poké Ball",
  GREAT_BALL = "Great Ball",
  ULTRA_BALL = "Ultra Ball",
  MASTER_BALL = "Master Ball",
  SAFARI_BALL = "Safari Ball",
}

local activeProjectiles = {}
local activeWobbles = {}
local selectedBallIndex = 1

-- Recently caught cell tracking to suppress vanilla encounter roll ONLY on caught tiles
local recentlyCaughtCells = {}

function CatchingModule.markCellCaught(mapId, x, y, duration)
  if not mapId or not x or not y then return end
  local key = tostring(mapId) .. "_" .. tostring(x) .. "_" .. tostring(y)
  local now = (love and love.timer and love.timer.getTime() or os.time())
  recentlyCaughtCells[key] = now + (duration or 20)
end

function CatchingModule.isCellSuppressed(mapId, x, y)
  if not mapId or not x or not y then return false end
  local key = tostring(mapId) .. "_" .. tostring(x) .. "_" .. tostring(y)
  local expiry = recentlyCaughtCells[key]
  if not expiry then return false end
  local now = (love and love.timer and love.timer.getTime() or os.time())
  if now < expiry then
    return true
  else
    recentlyCaughtCells[key] = nil
    return false
  end
end

function CatchingModule.getSelectedBall(game)
  local save = game and game.save
  if not save or not save.inventory then
    return CatchingModule.BALL_TYPES[selectedBallIndex]
  end

  local current = CatchingModule.BALL_TYPES[selectedBallIndex]
  if (save.inventory[current] or 0) > 0 then
    return current
  end

  for i, ball in ipairs(CatchingModule.BALL_TYPES) do
    if (save.inventory[ball] or 0) > 0 then
      selectedBallIndex = i
      return ball
    end
  end

  return current
end

function CatchingModule.cycleSelectedBall(game, direction)
  direction = direction or 1
  local total = #CatchingModule.BALL_TYPES
  selectedBallIndex = ((selectedBallIndex - 1 + direction) % total) + 1
  return CatchingModule.getSelectedBall(game)
end

local function ensureBallSpriteDef(game, ballType)
  if not game or not game.data or not game.data.sprites then return end
  local spriteId = "SPRITE_BALL_" .. ballType
  if game.data.sprites[spriteId] then return end
  game.data.sprites[spriteId] = {
    id = spriteId,
    image = "mods/Gen1PC-OverworldEncounters-main/assets/sprites/ball_" .. ballType:lower() .. ".png",
    frames = 1,
    walker = false,
    trueColor = true,
  }
end

function CatchingModule.throwBall(game, ow, uiModule)
  if not game or not ow or not ow.player then return false end

  local save = game.save
  if not save or not save.inventory then return false end

  local ballType = CatchingModule.getSelectedBall(game)
  local count = save.inventory[ballType] or 0

  if count <= 0 then
    local ballName = CatchingModule.BALL_NAMES[ballType] or ballType
    if game.stack and TextBox then
      game.stack:push(TextBox.new(game, "You don't have any\n" .. ballName .. "s!"))
    end
    return false
  end

  local player = ow.player
  local px, py = player.cellX, player.cellY
  local pdir = player.facing or player.dir or "down"

  -- Calculate target tile 1-6 steps in player facing direction
  local dx, dy = 0, 0
  if pdir == "up" then dy = -1
  elseif pdir == "down" then dy = 1
  elseif pdir == "left" then dx = -1
  elseif pdir == "right" then dx = 1 end

  local targetNpc = nil
  local targetTileX, targetTileY = px, py

  -- Check cells 1 to 6 tiles ahead
  for step = 1, 6 do
    local tx = px + (dx * step)
    local ty = py + (dy * step)
    for _, npc in ipairs(ow.npcs or {}) do
      if npc.isOverworldWildPokemon and not npc.isBeingCaught and npc.cellX == tx and npc.cellY == ty then
        targetNpc = npc
        targetTileX, targetTileY = tx, ty
        break
      end
    end
    if targetNpc then break end
  end

  -- Fallback: closest wild mon 1-6 tiles in facing direction cone
  if not targetNpc then
    local minDist = 999
    for _, npc in ipairs(ow.npcs or {}) do
      if npc.isOverworldWildPokemon and not npc.isBeingCaught then
        local dist = math.abs(npc.cellX - px) + math.abs(npc.cellY - py)
        if dist >= 1 and dist <= 6 then
          local inCone = false
          if pdir == "up" and npc.cellY < py then inCone = true end
          if pdir == "down" and npc.cellY > py then inCone = true end
          if pdir == "left" and npc.cellX < px then inCone = true end
          if pdir == "right" and npc.cellX > px then inCone = true end
          if inCone and dist < minDist then
            minDist = dist
            targetNpc = npc
            targetTileX, targetTileY = npc.cellX, npc.cellY
          end
        end
      end
    end
  end

  if not targetNpc then
    if game.stack and TextBox then
      game.stack:push(TextBox.new(game, "There's no wild\nPOKéMON nearby!"))
    end
    return false
  end

  targetNpc.isBeingCaught = true

  -- Consume 1 Poké Ball
  Bag.remove(save, ballType, 1)

  -- Create 3D Voxel / 2.5D tracking Ball Entity
  ensureBallSpriteDef(game, ballType)

  local spriteId = "SPRITE_BALL_" .. ballType
  local ballEntity = NPC.new(game.data, ow.map and ow.map.id or 1, {
    index = 450 + math.random(1, 40),
    name = "BALL_" .. ballType,
    sprite = spriteId,
    movement = "NONE",
    x = px,
    y = py,
  })

  ballEntity.isPokeBallEntity = true
  ballEntity.passable = true

  table.insert(ow.entities, ballEntity)

  local totalDist = math.max(1, math.abs(targetTileX - px) + math.abs(targetTileY - py))
  local speed = math.max(2.0, 4.0 / (totalDist * 0.4))

  table.insert(activeProjectiles, {
    startX = px,
    startY = py,
    currentX = px,
    currentY = py,
    targetX = targetTileX,
    targetY = targetTileY,
    progress = 0,
    speed = speed,
    ballType = ballType,
    ballEntity = ballEntity,
    targetNpc = targetNpc,
    totalDist = totalDist,
  })

  pcall(function()
    if game.audio and game.audio.playSfx then
      game.audio:playSfx("SFX_BALL_TOSS")
    end
  end)

  return true
end

local function executeCatchAttempt(game, ow, proj, uiModule)
  local npc = proj.targetNpc

  -- Remove wild Pokémon from overworld right when ball impacts
  local species = (npc and npc.wildSpecies) or "PIDGEY"
  local level = (npc and npc.wildLevel) or 5
  local currentHp = (npc and npc.currentHp) or math.floor(level * 2.5 + 10)
  local maxHp = (npc and npc.maxHp) or currentHp

  if npc then
    if ow.npcs then
      for idx = #ow.npcs, 1, -1 do
        if ow.npcs[idx] == npc then table.remove(ow.npcs, idx) break end
      end
    end
    if ow.entities then
      for idx = #ow.entities, 1, -1 do
        if ow.entities[idx] == npc then table.remove(ow.entities, idx) break end
      end
    end
  end

  -- Mark tile as caught to suppress vanilla encounters ONLY on this cell
  if ow and ow.map then
    CatchingModule.markCellCaught(ow.map.id, proj.targetX, proj.targetY, 25)
  end

  local targetDef = (game.data and game.data.pokemon and game.data.pokemon[species]) or { catchRate = 255 }

  local tempMon = {
    species = species,
    hp = currentHp,
    stats = { hp = maxHp },
  }

  local rng = love and love.math and love.math.random or math.random
  local caught, shakes = Catching.attempt(proj.ballType, tempMon, targetDef, rng)

  table.insert(activeWobbles, {
    x = proj.targetX,
    y = proj.targetY,
    species = species,
    level = level,
    ballType = proj.ballType,
    ballEntity = proj.ballEntity,
    caught = caught,
    totalShakes = shakes,
    currentShake = 0,
    timer = 0,
    phase = "WOBBLE",
    ow = ow,
    game = game,
  })
end

function CatchingModule.update(game, ow, dt, uiModule)
  local elapsed = dt or 0.016

  -- 1. Update Poké Ball Projectile Flying Arc
  for i = #activeProjectiles, 1, -1 do
    local proj = activeProjectiles[i]
    proj.progress = proj.progress + proj.speed * elapsed

    local p = math.min(1, proj.progress)
    proj.currentX = proj.startX + (proj.targetX - proj.startX) * p
    proj.currentY = proj.startY + (proj.targetY - proj.startY) * p

    local arcHeight = 14 + math.min(16, proj.totalDist * 3)
    local arcY = math.sin(p * math.pi) * arcHeight

    if proj.ballEntity then
      proj.ballEntity.cellX = math.floor(proj.currentX + 0.5)
      proj.ballEntity.cellY = math.floor(proj.currentY + 0.5)
      proj.ballEntity.px = proj.currentX * 16
      proj.ballEntity.py = (proj.currentY * 16) - arcY
    end

    if proj.progress >= 1.0 then
      table.remove(activeProjectiles, i)
      executeCatchAttempt(game, ow, proj, uiModule)
    end
  end

  -- 2. Update Wobble & Capture Animations on Target Tile
  for i = #activeWobbles, 1, -1 do
    local wob = activeWobbles[i]
    wob.timer = wob.timer + elapsed

    local ballEntity = wob.ballEntity

    if wob.phase == "WOBBLE" then
      if wob.timer >= 0.6 then
        wob.timer = 0
        wob.currentShake = wob.currentShake + 1

        pcall(function()
          if game.audio and game.audio.playSfx then
            game.audio:playSfx("SFX_BALL_POOP")
          end
        end)

        if wob.currentShake >= wob.totalShakes then
          wob.phase = "RESOLVE"
          wob.timer = 0
        end
      else
        -- Left-Right X-axis wobble only (py stays strictly constant)
        local nudgeX = math.sin(wob.timer * 22) * 2.5
        if ballEntity then
          ballEntity.px = wob.x * 16 + nudgeX
          ballEntity.py = wob.y * 16
        end
      end
    elseif wob.phase == "RESOLVE" then
      if wob.timer >= 0.4 then
        table.remove(activeWobbles, i)

        if ow and ow.entities and ballEntity then
          for idx = #ow.entities, 1, -1 do
            if ow.entities[idx] == ballEntity then table.remove(ow.entities, idx) break end
          end
        end

        local speciesDef = game.data and game.data.pokemon and game.data.pokemon[wob.species]
        local speciesName = (speciesDef and speciesDef.name) or wob.species

        if wob.caught then
          local newMon = Pokemon.new(game.data, wob.species, wob.level)
          local added = Party.add(game.save.party, newMon)

          pcall(function()
            if game.audio and game.audio.playSfx then
              game.audio:playSfx("SFX_CAUGHT_MON")
            end
          end)

          -- Authentic Vanilla Gen 1 Text Box
          local catchMsg = "All right!\n" .. speciesName .. " was caught!"
          if not added then
            local boxNum = Boxes.deposit(game.save, newMon)
            if boxNum then
              catchMsg = catchMsg .. "\fTransferred to\nBox " .. tostring(boxNum) .. "."
            else
              catchMsg = catchMsg .. "\fBox is full!"
            end
          end

          if game.stack and TextBox then
            game.stack:push(TextBox.new(game, catchMsg))
          end
        else
          -- Authentic Vanilla Break-Free Message & Battle State Transition
          local freeMsg = "Oh no!\n" .. speciesName .. " broke free!"

          if game.stack and TextBox then
            game.stack:push(TextBox.new(game, freeMsg, function()
              if BattleState and BattleState.newWild then
                local battle = BattleState.newWild(game, wob.species, wob.level)
                if battle then game.stack:push(battle) end
              end
            end))
          end
        end
      end
    end
  end
end

return CatchingModule
