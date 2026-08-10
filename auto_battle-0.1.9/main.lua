-- Auto Battle
-- ---------------------------------------------------------------------------
-- When enabled, the player's move is chosen automatically each turn instead of
-- opening the FIGHT menu. A small "AUTO" badge shows the feature is active,
-- since the menu no longer appears.
--
-- How it works (see the gen1recomp engine source, src/battle/BattleState.lua):
--   * BattleState:update runs a phase state machine; phase == "menu" is the
--     point where the engine waits for the player to choose FIGHT/PKMN/ITEM/RUN.
--   * Every menu choice ultimately commits through BattleState:resolveTurn(action),
--     where `action` is an entry of battle.player.curMoves (or a Struggle table).
--   * The overlay hook (battle.overlay) runs once per drawn frame with the live
--     BattleState. When it sees phase == "menu" and no one has taken manual
--     control, it picks a move and calls battle:resolveTurn(action) directly,
--     bypassing the menu UI. resolveTurn immediately sets phase = "messages",
--     so this fires exactly once per turn.
--
-- Move choice:
--   1. Score every usable damaging move as power * type-effectiveness * STAB
--      (TypeChart.effectiveness vs the foe's curTypes) and take the best.
--   2. If nothing damaging lands (only status moves, or the foe is immune),
--      fall back to the game's own NPC picker, TrainerAI.chooseMove.
--   3. Locked actions (recharge / thrash / trap / Bide) and the no-PP Struggle
--      case are replicated exactly from the engine's own FIGHT handling.
--
-- Manual override: touching the D-pad (moving the battle cursor) during the
-- short pre-commit window hands that turn back to you, so switching Pokemon,
-- using items, running, or catching still work.
-- ---------------------------------------------------------------------------

return function(mod)
  local ok_font, Font = pcall(require, "src.render.Font")
  if not ok_font then Font = nil end
  local ok_pfx, PaletteFX = pcall(require, "src.render.PaletteFX")
  if not ok_pfx then PaletteFX = nil end
  local ok_tc, TypeChart = pcall(require, "src.battle.TypeChart")
  if not ok_tc then TypeChart = nil end
  local ok_ai, TrainerAI = pcall(require, "src.battle.TrainerAI")
  if not ok_ai then TrainerAI = nil end
  local ok_ie, ItemEffects = pcall(require, "src.inventory.ItemEffects")
  if not ok_ie then ItemEffects = nil end
  local ok_bag, Bag = pcall(require, "src.inventory.Bag")
  if not ok_bag then Bag = nil end
  local ok_dmg, Damage = pcall(require, "src.battle.Damage")
  if not ok_dmg then Damage = nil end

  local getTime = (love.timer and love.timer.getTime) or nil
  local function now() return getTime and getTime() or 0 end

  ----------------------------------------------------------------------------
  -- Options
  ----------------------------------------------------------------------------
  mod.options:define({
    { key = "enabled", label = "AUTO BATTLE", type = "choice",
      default = "off", choices = { { "ON", "on" }, { "OFF", "off" } } },
    { key = "speed", label = "TAKEOVER WINDOW", type = "choice",
      default = "fast",
      choices = { { "INSTANT", "instant" }, { "FAST", "fast" }, { "RELAXED", "relaxed" } } },
    { key = "skip", label = "SKIP DIALOGS", type = "choice",
      default = "off", choices = { { "ON", "on" }, { "OFF", "off" } } },
    { key = "heal", label = "HEAL ITEMS", type = "choice",
      default = "off", choices = { { "ON", "on" }, { "OFF", "off" } } },
    { key = "heal_at", label = "HEAL BELOW", type = "choice",
      default = "half", choices = { { "1/2 HP", "half" }, { "1/4 HP", "quarter" } } },
    { key = "cure", label = "CURE STATUS", type = "choice",
      default = "off", choices = { { "ON", "on" }, { "OFF", "off" } } },
    { key = "catch", label = "AUTO CATCH", type = "choice",
      default = "off", choices = { { "ON", "on" }, { "OFF", "off" } } },
    { key = "switch", label = "SWITCH MATCHUP", type = "choice",
      default = "off", choices = { { "ON", "on" }, { "OFF", "off" } } },
    { key = "setup", label = "USE BUFF/DEBUFF", type = "choice",
      default = "off", choices = { { "ON", "on" }, { "OFF", "off" } } },
    { key = "size", label = "BADGE SIZE", type = "choice",
      default = "1x", choices = { { "1X", "1x" }, { "2X", "2x" } } },
  })

  local DELAYS = { instant = 0.0, fast = 0.35, relaxed = 0.9 }

  local function optionValue(game, key)
    local opts = game and game.save and game.save.options
    local bucket = opts and opts.modOptions and opts.modOptions[mod.id]
    local v = bucket and bucket[key]
    if v == nil then v = mod.options:get(key) end
    return v
  end

  ----------------------------------------------------------------------------
  -- Per-decision state (one battle-menu instance at a time)
  ----------------------------------------------------------------------------
  local st = {
    turnKey = nil,     -- battle.turnCount identifying the current decision
    graceStart = 0,    -- real time the menu opened
    suppressed = false,-- player took manual control this turn
    baseMenu = nil,    -- menuIndex when the menu opened (moving it = manual)
    lastName = nil,    -- last auto-picked move name (for the subtitle)
    lastAt = 0,
    lastSwitchEnemy = nil, -- foe instance we already switched against (anti-loop)
  }

  ----------------------------------------------------------------------------
  -- Move picking
  ----------------------------------------------------------------------------
  local STRUGGLE = function() return { id = "STRUGGLE", pp = 1, struggle = true } end

  local function moveDef(battle, id)
    local moves = battle.data and battle.data.moves
    return moves and moves[id] or nil
  end

  -- Returns action, displayName. Mirrors the engine's FIGHT handling for the
  -- locked / no-PP cases, then scores by type effectiveness.
  local function pickAction(battle)
    local player, enemy = battle.player, battle.enemy

    -- Own trapping / Bide forces the move (engine core.asm:320-329).
    if battle.fightLockedAction then
      local locked = battle:fightLockedAction(player)
      if locked then return locked, nil end
    end
    -- No usable PP anywhere -> Struggle.
    if battle.playerHasPP and not battle:playerHasPP() then
      return STRUGGLE(), "STRUGGLE"
    end

    local usable = {}
    for i, mv in ipairs(player.curMoves or {}) do
      if player.disabledSlot ~= i and (mv.pp or 0) > 0 then
        usable[#usable + 1] = mv
      end
    end
    if #usable == 0 then return STRUGGLE(), "STRUGGLE" end

    local pTypes = player.curTypes or {}
    local eTypes = (enemy and enemy.curTypes) or {}

    local best, bestScore = nil, 0
    for _, mv in ipairs(usable) do
      local def = moveDef(battle, mv.id)
      if def and (def.power or 0) > 0 and def.category ~= "status" then
        local mult = 1
        if TypeChart and TypeChart.effectiveness then
          local ok, m = pcall(TypeChart.effectiveness, def.type, eTypes)
          if ok and type(m) == "number" then mult = m end
        end
        local stab = 1
        for _, t in ipairs(pTypes) do
          if t == def.type then stab = 1.5 break end
        end
        local score = (def.power) * mult * stab
        if score > bestScore then bestScore = score; best = mv end
      end
    end

    if best and bestScore > 0 then
      local def = moveDef(battle, best.id)
      return best, def and def.name or nil
    end

    -- No damaging move connects (every damaging move is immune here, e.g. only
    -- Normal moves vs a Ghost). A status / utility move at least DOES something;
    -- hammering an immune attack does nothing. (SWITCH MATCHUP is the real fix
    -- for being walled, and runs before this.)
    for _, mv in ipairs(usable) do
      local def = moveDef(battle, mv.id)
      if def and ((def.power or 0) == 0 or def.category == "status") then
        return mv, def.name
      end
    end

    -- Only immune damaging moves remain: pick the strongest deterministically
    -- (nothing can connect; this is a "please switch or take over" state).
    local strong, sp
    for _, mv in ipairs(usable) do
      local def = moveDef(battle, mv.id)
      local p = (def and def.power) or 0
      if not sp or p > sp then strong, sp = mv, p end
    end
    local sdef = strong and moveDef(battle, strong.id)
    return strong or usable[1], sdef and sdef.name or nil
  end

  ----------------------------------------------------------------------------
  -- Consumables: heal / cure with a bag item (spends the turn, same path the
  -- in-battle bag uses: ItemEffects.use -> Bag.remove -> BattleState:itemUsed).
  ----------------------------------------------------------------------------
  -- Canonical Gen 1 HP-heal amounts (MAX_POTION / FULL_RESTORE = full heal).
  local HP_HEAL = {
    POTION = 20, SUPER_POTION = 50, HYPER_POTION = 200,
    FRESH_WATER = 50, SODA_POP = 60, LEMONADE = 80,
  }
  local FULL_HP = { MAX_POTION = true, FULL_RESTORE = true }
  local STATUS_CURE = {
    ANTIDOTE = { PSN = true }, BURN_HEAL = { BRN = true },
    ICE_HEAL = { FRZ = true }, AWAKENING = { SLP = true },
    PARLYZ_HEAL = { PAR = true },
    FULL_HEAL = { PSN = true, BRN = true, FRZ = true, SLP = true, PAR = true },
    FULL_RESTORE = { PSN = true, BRN = true, FRZ = true, SLP = true, PAR = true },
  }

  local function bagQty(save, id)
    return (save and save.inventory and save.inventory[id]) or 0
  end

  -- Smallest heal that covers `missing`; else the largest available.
  local function pickHpHeal(save, missing)
    if not (Bag and save) then return nil end
    local best, bestAmt, fallback, fallbackAmt = nil, nil, nil, -1
    for _, id in ipairs(Bag.order(save)) do
      if bagQty(save, id) > 0 then
        local amt = HP_HEAL[id] or (FULL_HP[id] and math.huge or nil)
        if amt then
          if amt > fallbackAmt then fallback, fallbackAmt = id, amt end
          if amt >= missing and (bestAmt == nil or amt < bestAmt) then
            best, bestAmt = id, amt
          end
        end
      end
    end
    return best or fallback
  end

  -- A cure for `status`; prefer a single-status item over the versatile ones.
  local function pickStatusCure(save, status)
    if not (Bag and save and status) then return nil end
    local specific, broad
    for _, id in ipairs(Bag.order(save)) do
      if bagQty(save, id) > 0 then
        local cure = STATUS_CURE[id]
        if cure and cure[status] then
          if id == "FULL_HEAL" or id == "FULL_RESTORE" then
            broad = broad or id
          else
            specific = specific or id
          end
        end
      end
    end
    return specific or broad
  end

  -- Use `id` on the active mon, consume it, and spend the turn. Returns true
  -- on success. battle.player.mon IS the party mon, so the heal persists.
  local function useItem(battle, id)
    if not (ItemEffects and Bag) then return false end
    local game = battle.game
    local ok, result, msgs =
      pcall(ItemEffects.use, game.data, game.save, id, battle.player.mon, battle)
    if not ok or result ~= "consumed" then return false end
    Bag.remove(game.save, id, 1)
    local def = game.data and game.data.items and game.data.items[id]
    st.lastName, st.lastAt = (def and def.name) or id, now()
    battle.phase = "messages"
    battle.afterQueue = "menu"
    pcall(function() battle:itemUsed(msgs or {}) end)
    return true
  end

  -- HP heal (below threshold) takes priority, then a status cure. Returns true
  -- if an item was used this turn (so no attack is committed).
  local function tryConsumables(battle)
    if not (ItemEffects and Bag) then return false end
    local game, mon = battle.game, battle.player.mon
    if not (mon and mon.stats and mon.stats.hp) then return false end

    if optionValue(game, "heal") == "on" then
      local maxhp, hp = mon.stats.hp, mon.hp or 0
      local threshold = (optionValue(game, "heal_at") == "quarter") and 0.25 or 0.5
      local missing = maxhp - hp
      if hp > 0 and (hp / maxhp) <= threshold and missing > 0 then
        local id = pickHpHeal(game.save, missing)
        if id and useItem(battle, id) then return true end
      end
    end

    if optionValue(game, "cure") == "on" and mon.status then
      local id = pickStatusCure(game.save, mon.status)
      if id and useItem(battle, id) then return true end
    end

    return false
  end

  ----------------------------------------------------------------------------
  -- Auto catch (wild only): weaken safely, sleep/paralyse, then throw a ball.
  -- The sensitive one: killing the target defeats the purpose, so KO risk is
  -- estimated with a FORCED-CRIT damage roll and we bail to a throw whenever a
  -- move might KO. Never spends a Master or Safari Ball.
  ----------------------------------------------------------------------------
  local CATCH_BALLS = { "POKE_BALL", "GREAT_BALL", "ULTRA_BALL" } -- cheapest first
  local CATCH_HP = 0.5   -- stop weakening once the foe is at/below half
  local BIG_STATUS = { SLP = true, FRZ = true } -- big Gen 1 catch bonus -> throw now

  local function firstBall(save)
    if not (Bag and save) then return nil end
    for _, id in ipairs(CATCH_BALLS) do
      if bagQty(save, id) > 0 then return id end
    end
    return nil
  end

  local function canCatch(battle)
    if optionValue(battle.game, "catch") ~= "on" then return false end
    if battle.kind ~= "wild" then return false end
    if battle.ghost or battle.noCatch then return false end
    local enemy = battle.enemy
    if not (enemy and enemy.mon and (enemy.mon.hp or 0) > 0) then return false end
    local dex = battle.game.save and battle.game.save.pokedex
    local species = enemy.mon.species
    if dex and species and dex.owned and dex.owned[species] then return false end -- already caught
    return firstBall(battle.game.save) ~= nil
  end

  -- A status move's type must not be immune vs the foe (Thunder Wave, an
  -- Electric move, does nothing to a Ground type like Rhyhorn).
  local function typeConnects(battle, def)
    if not (TypeChart and TypeChart.effectiveness and def and def.type) then return true end
    local ok, m = pcall(TypeChart.effectiveness, def.type, battle.enemy.curTypes or {})
    return not (ok and m == 0)
  end

  -- A primary sleep move (best), else a primary paralysis move, with PP, whose
  -- type actually affects the foe.
  local function pickStatusMove(battle)
    local player = battle.player
    local sleep, para
    for i, mv in ipairs(player.curMoves or {}) do
      if player.disabledSlot ~= i and (mv.pp or 0) > 0 then
        local def = moveDef(battle, mv.id)
        if def and typeConnects(battle, def) then
          if def.effect == "SLEEP_EFFECT" then sleep = sleep or mv
          elseif def.effect == "PARALYZE_EFFECT" then para = para or mv end
        end
      end
    end
    return sleep or para
  end

  -- Worst-case (forced crit, max of a few rolls) damage of `mv` vs the foe.
  local function worstCaseDamage(battle, mv)
    local def = moveDef(battle, mv.id)
    if not (Damage and def) then return nil end
    local worst
    for _ = 1, 4 do
      local ok, dmg = pcall(Damage.compute, battle.ruleset,
                            battle.player, battle.enemy, def, { forceCrit = true })
      if ok and type(dmg) == "number" then worst = math.max(worst or 0, dmg) end
    end
    return worst
  end

  -- Gentlest move that actually damages the foe without KO'ing it (nil = none).
  -- Must CONNECT (worst > 0): an immune move (Electric vs Ground/Rhyhorn) does
  -- 0 damage, so it can never weaken and must not be chosen. Picks the move with
  -- the lowest real damage, not the lowest raw power.
  local function pickWeakestSafeMove(battle)
    local player = battle.player
    local hp = battle.enemy.mon.hp
    local best, bestWorst
    for i, mv in ipairs(player.curMoves or {}) do
      if player.disabledSlot ~= i and (mv.pp or 0) > 0 then
        local def = moveDef(battle, mv.id)
        if def and (def.power or 0) > 0 and def.category ~= "status" then
          local worst = worstCaseDamage(battle, mv)
          -- connects (>0) AND provably won't KO (<hp)
          if worst and worst > 0 and worst < hp then
            if not bestWorst or worst < bestWorst then best, bestWorst = mv, worst end
          end
        end
      end
    end
    return best
  end

  local function ballName(battle, id)
    local def = battle.game.data and battle.game.data.items and battle.game.data.items[id]
    return (def and def.name) or id
  end

  -- Returns true if it committed a catch-related action this turn.
  local function tryCatch(battle)
    if not canCatch(battle) then return false end
    local game, enemy = battle.game, battle.enemy
    local maxhp = enemy.mon.stats and enemy.mon.stats.hp or enemy.mon.hp
    local ehp = (enemy.mon.hp or 0) / math.max(1, maxhp)
    local status = enemy.mon.status

    -- 1) Put it to sleep / paralyse first (unstatused only).
    if not status then
      local sm = pickStatusMove(battle)
      if sm then
        local def = moveDef(battle, sm.id)
        st.lastName, st.lastAt = "CATCH: " .. ((def and def.name) or "STATUS"), now()
        pcall(function() battle:resolveTurn(sm) end)
        return true
      end
    end

    -- 2) Weaken until half HP, unless a big-bonus status is already up.
    if ehp > CATCH_HP and not (status and BIG_STATUS[status]) then
      local weak = pickWeakestSafeMove(battle)
      if weak then
        st.lastName, st.lastAt = "CATCH: WEAKEN", now()
        pcall(function() battle:resolveTurn(weak) end)
        return true
      end
      -- no move we can prove is safe: fall through and just throw
    end

    -- 3) Throw a ball (cheapest available; never Master/Safari).
    local ball = firstBall(game.save)
    if ball then
      Bag.remove(game.save, ball, 1)
      st.lastName, st.lastAt = "THROW " .. ballName(battle, ball), now()
      battle.phase = "messages"
      battle.afterQueue = "menu"
      pcall(function() battle:throwBall(ball) end)
      return true
    end
    return false
  end

  ----------------------------------------------------------------------------
  -- Switch to a better type matchup. Scores both directions with the REAL
  -- movesets (enemy.curMoves vs a candidate's types, the candidate's moves vs
  -- the enemy's types). Guards against loops and against sending a mon into a
  -- super-effective free hit (a switch always costs the enemy a free move).
  ----------------------------------------------------------------------------
  local SWITCH_MARGIN = 1.5   -- a candidate must clear the active by this much

  local function effMax(attackType, defTypes)
    if not (TypeChart and TypeChart.effectiveness) then return 1 end
    local ok, m = pcall(TypeChart.effectiveness, attackType, defTypes)
    return (ok and type(m) == "number") and m or 1
  end

  -- Best type-effectiveness of `moves`' damaging entries vs `defTypes`. With no
  -- damaging moves, approximates from `stabTypes` (STAB) instead.
  local function bestOffense(battle, moves, defTypes, stabTypes)
    local best, any = 0, false
    for _, mv in ipairs(moves or {}) do
      local def = moveDef(battle, mv.id)
      if def and (def.power or 0) > 0 and def.category ~= "status" then
        any = true
        local e = effMax(def.type, defTypes)
        if e > best then best = e end
      end
    end
    if not any then
      for _, t in ipairs(stabTypes or {}) do
        local e = effMax(t, defTypes)
        if e > best then best = e end
      end
    end
    return best
  end

  -- offVal = how hard C hits the foe; defRisk = how hard the foe hits C.
  local function evalMatchup(battle, cTypes, cMoves)
    local enemy = battle.enemy
    local eTypes = enemy.curTypes or {}
    local offVal = bestOffense(battle, cMoves, eTypes, cTypes)
    local defRisk = bestOffense(battle, enemy.curMoves, cTypes, eTypes)
    return offVal, defRisk, offVal - defRisk
  end

  local function monTypes(battle, mon)
    local def = battle.data and battle.data.pokemon and battle.data.pokemon[mon.species]
    return def and def.types or {}
  end

  local function trySwitch(battle)
    if optionValue(battle.game, "switch") ~= "on" then return false end
    local enemy = battle.enemy
    if not (enemy and enemy.mon) then return false end
    local save = battle.game.save
    local party = save and save.party
    if not party then return false end
    -- Anti-loop: never switch twice against the same foe instance.
    if st.lastSwitchEnemy == enemy.mon then return false end

    local active = battle.player.mon
    local aOff, aDef, aScore =
      evalMatchup(battle, battle.player.curTypes, battle.player.curMoves)
    -- Active already dominates (super-effective and not threatened): stay.
    if aOff >= 2 and aDef < 2 then return false end

    -- Track two candidates (both must survive the free hit, drisk < 2):
    --   best      = highest matchup score          (for the margin case)
    --   bestHit   = highest score that can DAMAGE  (for escaping a wall)
    local best, bestScore, bestHit, bestHitScore
    for _, mon in ipairs(party) do
      if mon ~= active and (mon.hp or 0) > 0 then
        local off, drisk, score = evalMatchup(battle, monTypes(battle, mon), mon.moves)
        if drisk < 2 then
          if not bestScore or score > bestScore then best, bestScore = mon, score end
          if (off or 0) > 0 and (not bestHitScore or score > bestHitScore) then
            bestHit, bestHitScore = mon, score
          end
        end
      end
    end

    -- "Walled": the active mon can't damage the foe AT ALL (Normal vs Ghost,
    -- etc.). Escaping that is worth a switch regardless of margin -- but only to
    -- a mon that can actually hit. Otherwise use the margin rule.
    local target
    if aOff <= 0 and bestHit then
      target = bestHit
    elseif best and (bestScore - aScore) >= SWITCH_MARGIN then
      target = best
    end

    if target then
      st.lastSwitchEnemy = enemy.mon
      local pdef = battle.data.pokemon and battle.data.pokemon[target.species]
      st.lastName = "SWITCH " .. (target.nickname or (pdef and pdef.name) or "?")
      st.lastAt = now()
      pcall(function() battle:resolveSwitch(target) end) -- sets phase itself
      return true
    end
    return false
  end

  ----------------------------------------------------------------------------
  -- Buff / debuff (setup). Only when it's SAFE and WORTH it: we can damage but
  -- can't OHKO, the foe is still healthy, and we survive its worst hit. Capped
  -- by stat stage so it never sets up forever.
  ----------------------------------------------------------------------------
  local BUFF_MOVES = {   -- effect id -> the stat it raises on us
    ATTACK_UP1_EFFECT = "attack",  ATTACK_UP2_EFFECT = "attack",
    DEFENSE_UP1_EFFECT = "defense", DEFENSE_UP2_EFFECT = "defense",
    SPEED_UP2_EFFECT = "speed",
    SPECIAL_UP1_EFFECT = "special", SPECIAL_UP2_EFFECT = "special",
    EVASION_UP1_EFFECT = "evasion",
  }
  local DEBUFF_MOVES = {  -- effect id -> the stat it lowers on the foe
    ATTACK_DOWN1_EFFECT = "attack", DEFENSE_DOWN1_EFFECT = "defense",
    DEFENSE_DOWN2_EFFECT = "defense", SPEED_DOWN1_EFFECT = "speed",
    ACCURACY_DOWN1_EFFECT = "accuracy",
  }
  local STAGE_CAP = 2      -- don't push a stat past +/- this
  local SETUP_MIN_EHP = 0.6 -- only set up while the foe is still healthy

  -- Worst/expected damage of `def` from attacker to defender (max of a few
  -- rolls; forceCrit for a worst case).
  local function estDamage(battle, attacker, defender, def, forceCrit)
    if not (Damage and def) then return nil end
    local worst
    for _ = 1, 4 do
      local ok, d = pcall(Damage.compute, battle.ruleset, attacker, defender, def,
                          { forceCrit = forceCrit or nil })
      if ok and type(d) == "number" then worst = math.max(worst or 0, d) end
    end
    return worst
  end

  local function ourBestDamage(battle) -- best expected damaging hit vs the foe
    local best = 0
    for i, mv in ipairs(battle.player.curMoves or {}) do
      if battle.player.disabledSlot ~= i and (mv.pp or 0) > 0 then
        local def = moveDef(battle, mv.id)
        if def and (def.power or 0) > 0 and def.category ~= "status" then
          local d = estDamage(battle, battle.player, battle.enemy, def, false)
          if d and d > best then best = d end
        end
      end
    end
    return best
  end

  local function enemyWorstHit(battle) -- forced-crit worst enemy damaging hit
    local worst = 0
    for _, mv in ipairs(battle.enemy.curMoves or {}) do
      local def = moveDef(battle, mv.id)
      if def and (def.power or 0) > 0 and def.category ~= "status" then
        local d = estDamage(battle, battle.enemy, battle.player, def, true)
        if d and d > worst then worst = d end
      end
    end
    return worst
  end

  -- Our attacking stat ("attack" or "special") from the strongest damaging move.
  local function attackStyle(battle)
    local bestPow, cat = -1, nil
    for i, mv in ipairs(battle.player.curMoves or {}) do
      if battle.player.disabledSlot ~= i and (mv.pp or 0) > 0 then
        local def = moveDef(battle, mv.id)
        if def and (def.power or 0) > bestPow and def.category ~= "status" then
          bestPow = def.power
          cat = def.category or (TypeChart and TypeChart.category and TypeChart.category(def.type))
        end
      end
    end
    return (cat == "special") and "special" or "attack"
  end

  -- Prefer an offensive buff matching our style; then any buff under cap; then a
  -- debuff of the foe that isn't already bottomed out.
  local function pickSetupMove(battle)
    local player, enemy = battle.player, battle.enemy
    local style = attackStyle(battle)
    local styleBuff, anyBuff, debuff
    for i, mv in ipairs(player.curMoves or {}) do
      if player.disabledSlot ~= i and (mv.pp or 0) > 0 then
        local def = moveDef(battle, mv.id)
        local eff = def and def.effect
        local bstat = eff and BUFF_MOVES[eff]
        local dstat = eff and DEBUFF_MOVES[eff]
        if bstat and (player.stages[bstat] or 0) < STAGE_CAP then
          if bstat == style then styleBuff = styleBuff or { mv = mv, def = def } end
          anyBuff = anyBuff or { mv = mv, def = def }
        elseif dstat and (enemy.stages[dstat] or 0) > -STAGE_CAP then
          debuff = debuff or { mv = mv, def = def }
        end
      end
    end
    return styleBuff or anyBuff or debuff
  end

  local function trySetup(battle)
    if optionValue(battle.game, "setup") ~= "on" then return false end
    if not Damage then return false end
    local enemy = battle.enemy
    if not (enemy and enemy.mon) then return false end
    local emax = (enemy.mon.stats and enemy.mon.stats.hp) or enemy.mon.hp
    if (enemy.mon.hp or 0) / math.max(1, emax) < SETUP_MIN_EHP then return false end

    local ourDmg = ourBestDamage(battle)
    if ourDmg <= 0 then return false end                 -- can't damage -> not our job
    if ourDmg >= (enemy.mon.hp or 0) then return false end -- can OHKO -> just attack
    if enemyWorstHit(battle) >= (battle.player.mon.hp or 0) then return false end -- unsafe

    local cand = pickSetupMove(battle)
    if cand then
      st.lastName = "SETUP: " .. ((cand.def and cand.def.name) or "?")
      st.lastAt = now()
      pcall(function() battle:resolveTurn(cand.mv) end)
      return true
    end
    return false
  end

  ----------------------------------------------------------------------------
  -- Decide + commit
  ----------------------------------------------------------------------------
  local function isNormalMenu(battle)
    if battle.phase ~= "menu" then return false end
    if battle.demo or battle.safari or battle.ghost then return false end
    local p = battle.player
    if not (p and p.mon and (p.mon.hp or 0) > 0) then return false end
    -- Forced multi-turn moves are auto-resolved by the engine's own update
    -- before this draw runs; guard anyway so we never override them.
    if battle.menuLockedAction and battle:menuLockedAction(p) then return false end
    return true
  end

  local function tick(battle)
    local tk = battle.turnCount or 0

    if isNormalMenu(battle) then
      if st.turnKey ~= tk then
        st.turnKey = tk
        st.graceStart = now()
        st.suppressed = false
        st.baseMenu = battle.menuIndex
      end
      -- Player moved the cursor -> they want the menu this turn.
      if battle.menuIndex ~= st.baseMenu then st.suppressed = true end

      local delay = DELAYS[optionValue(battle.game, "speed")] or DELAYS.fast
      if not st.suppressed and (now() - st.graceStart) >= delay then
        local committed = false
        -- Priority: heal/cure -> catch -> switch matchup -> set up -> attack.
        if tryConsumables(battle) then
          committed = true
        elseif tryCatch(battle) then
          committed = true
        elseif trySwitch(battle) then
          committed = true
        elseif trySetup(battle) then
          committed = true
        else
          local action, name = pickAction(battle)
          if action then
            if name then st.lastName = name; st.lastAt = now() end
            pcall(function() battle:resolveTurn(action) end)
            committed = true
          end
        end
        -- Both resolveTurn and itemUsed flip phase off "menu"; clearing the
        -- key gives the NEXT auto-action (even after a heal) a fresh takeover
        -- window instead of firing instantly.
        if committed then st.turnKey = nil end
      end
    else
      -- Player advanced past the menu (moveSelect / party / bag) this turn:
      -- keep it manual even if they back out to the menu.
      if battle.phase ~= "menu" and st.turnKey == tk then st.suppressed = true end
    end
  end

  ----------------------------------------------------------------------------
  -- Badge UI (native 160x144 coords). GB font tiles render dark, so the
  -- boxes are light for contrast.
  ----------------------------------------------------------------------------
  local PADX = 3

  local function drawBox(x, y, w, h, fill, border, a)
    local g = love.graphics
    g.setColor(fill[1], fill[2], fill[3], (fill[4] or 1) * a)
    g.rectangle("fill", x, y, w, h)
    if border then
      g.setColor(border[1], border[2], border[3], a)
      g.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1)
    end
  end

  -- Right-aligned tags in the top-right corner. Same approach as the
  -- damage_numbers mod: draw the GB font at an INTEGER scale (1x or 2x) so the
  -- pixels stay perfectly crisp (nearest-neighbour only chops at fractional
  -- scales). `scale` is 1 or 2 from the BADGE SIZE option.
  local MARGIN = 0      -- px from the screen edge (flush to the right)
  local GAP    = 1      -- px between stacked tags

  -- One right-aligned tag; returns the native y below it.
  local function tag(label, ny, fill, border, a, scale)
    local lw, lh = Font.width(label) + PADX * 2, 9   -- logical (font px)
    local nw, nh = lw * scale, lh * scale            -- native px (integer)
    local nx = (160 - MARGIN) - nw
    local g = love.graphics
    g.push("all")
    g.setShader()
    g.translate(nx, ny)
    g.scale(scale, scale)
    drawBox(0, 0, lw, lh, fill, border, a)
    g.setColor(1, 1, 1, a)
    Font.draw(label, PADX, 1)
    g.pop()
    if PaletteFX and PaletteFX.markTrueColor then
      PaletteFX.markTrueColor(nx - 1, ny - 1, nw + 2, nh + 2)
    end
    return ny + nh + GAP
  end

  local function drawBadges(battle, autoOn, skipOn)
    if not Font or not (autoOn or skipOn) then return end
    local g = love.graphics
    g.push("all")
    g.setShader()

    local y = MARGIN
    local scale = (optionValue(battle.game, "size") == "2x") and 2 or 1
    local pulse = 0.72 + 0.28 * math.sin(now() * 4)

    if autoOn then
      local tk = battle.turnCount or 0
      local manual = battle.phase == "menu" and st.suppressed and st.turnKey == tk
      if manual then
        y = tag("AUTO", y, { 0.82, 0.82, 0.82 }, { 0.45, 0.45, 0.45 }, 0.8, scale)
      else
        y = tag("AUTO", y, { 0.58, 0.92, 0.55 }, { 0.15, 0.55, 0.20 }, pulse, scale)
      end
    end

    if skipOn then
      -- brighter while it is actually fast-forwarding a message page
      local a = (battle.phase == "messages") and pulse or 0.75
      y = tag("SKIP", y, { 0.62, 0.85, 0.98 }, { 0.15, 0.40, 0.65 }, a, scale)
    end

    -- Subtitle: the move we just auto-picked, fading out.
    if autoOn and st.lastName and (now() - st.lastAt) < 1.4 then
      local fade = math.max(0, 1 - (now() - st.lastAt) / 1.4)
      tag(tostring(st.lastName), y, { 0.96, 0.93, 0.80 }, { 0.55, 0.45, 0.15 }, fade, scale)
    end

    g.pop()
  end

  ----------------------------------------------------------------------------
  -- Skip dialogs: auto-advance the battle message queue by tapping A. Only
  -- while the battle owns the screen, so pushed YES/NO boxes, the party menu,
  -- the bag, move-learn and evolution prompts are never auto-confirmed.
  ----------------------------------------------------------------------------
  local function canTap(battle)
    if battle.waitingUI then return false end
    local stack = battle.game and battle.game.stack
    if stack and stack.top then
      local ok, top = pcall(function() return stack:top() end)
      if ok and top ~= nil and top ~= battle then return false end
    end
    return true
  end

  local function skipDialogs(battle)
    if battle.phase ~= "messages" then return end
    if not canTap(battle) then return end
    pcall(function() mod.input:tap(battle.game, "a") end)
  end

  -- Fresh state each battle so a previous fight's timers never carry over.
  mod.events:on("battle.started", function()
    st.turnKey = nil
    st.suppressed = false
    st.baseMenu = nil
    st.lastName = nil
    st.lastAt = 0
    st.lastSwitchEnemy = nil
  end)

  ----------------------------------------------------------------------------
  -- Overlay hook: decide the turn, then draw the badge.
  ----------------------------------------------------------------------------
  mod.hooks:wrap("battle.overlay", function(next, battle)
    local result = next()
    if not battle or not battle.game then return result end
    local autoOn = optionValue(battle.game, "enabled") == "on"
    local skipOn = optionValue(battle.game, "skip") == "on"
    if not autoOn and not skipOn then return result end

    if autoOn then tick(battle) end
    if skipOn then skipDialogs(battle) end
    drawBadges(battle, autoOn, skipOn)
    return result
  end)

  if mod.log and mod.log.info then
    mod.log:info("Auto Battle v0.1.9 loaded")
  end
end
