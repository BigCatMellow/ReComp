-- Overworld Encounters - Combat & AI Module
-- Detaches active follower Pokémon to chase nearest wild Pokémon, stop 1 tile away, and perform overworld battle animations.

local CombatModule = {}

local PikachuFollower = pcall(require, "src.world.PikachuFollower") and require("src.world.PikachuFollower") or nil
local BattleState = require("src.battle.BattleState")
local TextBox = require("src.render.TextBox")

local activeBattleChase = nil
local floatingDamageTexts = {}
local attackEffects = {}

-- Helper to get current follower entity from PokePCFollowers or ow.entities
local function getFollowerEntity(ow)
  if PikachuFollower and PikachuFollower.current then
    local f = PikachuFollower.current(ow)
    if f then return f end
  end
  if ow and ow.entities then
    for _, ent in ipairs(ow.entities) do
      if ent.id == "pikachu" or ent.isFollower or ent.isLeadPokemon then
        return ent
      end
    end
  end
  return nil
end

function CombatModule.commandFollowerAttack(game, ow, uiModule)
  if not game or not ow or not ow.player then return false end

  local follower = getFollowerEntity(ow)
  if not follower then
    if game.stack and TextBox then
      game.stack:push(TextBox.new(game, "No follower POKéMON\nfound!"))
    end
    return false
  end

  local player = ow.player
  local px, py = player.cellX, player.cellY

  -- Find nearest wild mon NPC
  local targetNpc = nil
  local minDist = 999

  for _, npc in ipairs(ow.npcs or {}) do
    if npc.isOverworldWildPokemon and not npc.isFainting and not npc.isBeingCaught then
      local dist = math.abs(npc.cellX - px) + math.abs(npc.cellY - py)
      if dist <= 10 and dist < minDist then
        minDist = dist
        targetNpc = npc
      end
    end
  end

  if not targetNpc then
    if game.stack and TextBox then
      game.stack:push(TextBox.new(game, "There's no wild\nPOKéMON nearby!"))
    end
    return false
  end

  -- Determine 1-tile adjacent target position (1 space away)
  local tx, ty = targetNpc.cellX, targetNpc.cellY
  local fx, fy = follower.cellX, follower.cellY

  local attackStandX, attackStandY = tx, ty
  if fx < tx then attackStandX = tx - 1 attackStandY = ty
  elseif fx > tx then attackStandX = tx + 1 attackStandY = ty
  elseif fy < ty then attackStandX = tx attackStandY = ty - 1
  elseif fy > ty then attackStandX = tx attackStandY = ty + 1
  else attackStandX = tx - 1 end

  activeBattleChase = {
    follower = follower,
    targetNpc = targetNpc,
    standX = attackStandX,
    standY = attackStandY,
    state = "CHASE", -- "CHASE", "ATTACK", "DONE"
    timer = 0,
    game = game,
    ow = ow,
  }

  return true
end

function CombatModule.update(game, ow, dt, uiModule)
  local elapsed = dt or 0.016
  local player = ow and ow.player
  if not player then return end

  -- 1. Update Follower Battle Chase & Attack Sequence
  if activeBattleChase then
    local chase = activeBattleChase
    chase.timer = chase.timer + elapsed

    local follower = chase.follower
    local targetNpc = chase.targetNpc

    if chase.state == "CHASE" then
      -- Move follower step-by-step toward 1-tile stand position
      if math.abs(follower.cellX - chase.standX) > 0 or math.abs(follower.cellY - chase.standY) > 0 then
        if chase.timer >= 0.08 then
          chase.timer = 0
          if follower.cellX < chase.standX then follower.cellX = follower.cellX + 1 follower.facing = "right"
          elseif follower.cellX > chase.standX then follower.cellX = follower.cellX - 1 follower.facing = "left"
          elseif follower.cellY < chase.standY then follower.cellY = follower.cellY + 1 follower.facing = "down"
          elseif follower.cellY > chase.standY then follower.cellY = follower.cellY - 1 follower.facing = "up"
          end
          follower.px = follower.cellX * 16
          follower.py = follower.cellY * 16
        end
      else
        -- Arrived at 1-tile space away! Begin Battle Attack Animation
        chase.state = "ATTACK"
        chase.timer = 0

        -- Face each other across 1 tile gap
        if follower.cellX < targetNpc.cellX then follower.facing = "right" targetNpc.dir = "left"
        elseif follower.cellX > targetNpc.cellX then follower.facing = "left" targetNpc.dir = "right"
        elseif follower.cellY < targetNpc.cellY then follower.facing = "down" targetNpc.dir = "up"
        elseif follower.cellY > targetNpc.cellY then follower.facing = "up" targetNpc.dir = "down"
        end

        -- Calculate Damage & Slash Animation
        local party = game.save and game.save.party
        local leadMon = party and party[1]
        local leadLevel = leadMon and leadMon.level or 10
        local wildLevel = targetNpc.wildLevel or 5
        targetNpc.maxHp = targetNpc.maxHp or math.floor(wildLevel * 2.5 + 10)
        targetNpc.currentHp = targetNpc.currentHp or targetNpc.maxHp

        local dmg = math.floor((2 * leadLevel / 5 + 2) * 35 / 50) + math.random(5, 12)
        targetNpc.currentHp = math.max(0, targetNpc.currentHp - dmg)

        table.insert(attackEffects, {
          x = targetNpc.cellX,
          y = targetNpc.cellY,
          timer = 0,
          maxTime = 0.4,
        })

        table.insert(floatingDamageTexts, {
          x = targetNpc.cellX,
          y = targetNpc.cellY,
          text = "-" .. tostring(dmg),
          timer = 0,
          maxTime = 0.9,
        })

        pcall(function()
          if game.audio and game.audio.playSfx then
            game.audio:playSfx("SFX_DAMAGE")
          end
        end)
      end
    elseif chase.state == "ATTACK" then
      if chase.timer >= 0.5 then
        chase.state = "DONE"
        local targetNpc = chase.targetNpc

        if targetNpc and targetNpc.currentHp and targetNpc.currentHp <= 0 then
          -- Fainted: despawn wild mon & award EXP
          targetNpc.isFainting = true
          local speciesDef = game.data and game.data.pokemon and game.data.pokemon[targetNpc.wildSpecies]
          local speciesName = (speciesDef and speciesDef.name) or (targetNpc.wildSpecies or "wild mon")
          local wildLevel = targetNpc.wildLevel or 5
          local exp = wildLevel * 15

          if game.stack and TextBox then
            game.stack:push(TextBox.new(game, "Enemy " .. speciesName .. "\nfainted! (+" .. exp .. " EXP)"))
          end

          if ow.npcs then
            for idx = #ow.npcs, 1, -1 do
              if ow.npcs[idx] == targetNpc then table.remove(ow.npcs, idx) break end
            end
          end
          if ow.entities then
            for idx = #ow.entities, 1, -1 do
              if ow.entities[idx] == targetNpc then table.remove(ow.entities, idx) break end
            end
          end
        else
          -- Survived: Transition seamlessly to standard battle!
          if targetNpc and BattleState and BattleState.newWild then
            local species = targetNpc.wildSpecies or "PIDGEY"
            local level = targetNpc.wildLevel or 5
            if ow.npcs then
              for idx = #ow.npcs, 1, -1 do
                if ow.npcs[idx] == targetNpc then table.remove(ow.npcs, idx) break end
              end
            end
            local battle = BattleState.newWild(game, species, level)
            if battle then game.stack:push(battle) end
          end
        end

        activeBattleChase = nil
      end
    end
  end

  -- 2. Update Attack FX
  for i = #attackEffects, 1, -1 do
    local fx = attackEffects[i]
    fx.timer = fx.timer + elapsed
    if fx.timer >= fx.maxTime then table.remove(attackEffects, i) end
  end

  -- 3. Update Damage Texts
  for i = #floatingDamageTexts, 1, -1 do
    local txt = floatingDamageTexts[i]
    txt.timer = txt.timer + elapsed
    if txt.timer >= txt.maxTime then table.remove(floatingDamageTexts, i) end
  end
end

-- World-space draw: uses camera offsets (cam.x, cam.y)
function CombatModule.drawWorld(game, ow)
  if not love or not love.graphics or not ow or not ow.camera then return end
  local lg = love.graphics
  local camX = ow.camera.x or 0
  local camY = ow.camera.y or 0

  -- Draw Attack Slash FX
  for _, fx in ipairs(attackEffects) do
    local fxX = (fx.x * 16) - camX + 8
    local fxY = (fx.y * 16) - camY + 8
    lg.push()
    lg.setColor(1, 0.9, 0.2, 0.9)
    lg.setLineWidth(2)
    lg.line(fxX - 8, fxY - 8, fxX + 8, fxY + 8)
    lg.line(fxX + 8, fxY - 8, fxX - 8, fxY + 8)
    lg.setLineWidth(1)
    lg.pop()
  end

  -- Draw Floating Damage Numbers
  for _, txt in ipairs(floatingDamageTexts) do
    local txX = (txt.x * 16) - camX + 8
    local txY = (txt.y * 16) - camY + 8 - (txt.timer * 22)
    lg.push()
    lg.setColor(1, 0.2, 0.2, 1 - (txt.timer / txt.maxTime))
    lg.print(txt.text, txX - 6, txY - 10)
    lg.pop()
  end
end

return CombatModule
