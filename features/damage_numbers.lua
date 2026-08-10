local Feature = { id = "damage_numbers" }

function Feature.install(ctx)
  local mod = ctx.mod
  local Colors = ctx.colors
  local Engine = ctx.engine
  local Font = mod.ui and mod.ui.Font
  if not Font then
    mod.log:warn("damage numbers disabled: mod.ui.Font unavailable")
    return
  end

  mod.options:define({
    { key = "damage_numbers", label = "DAMAGE NUMBERS", type = "choice",
      default = "on", choices = { { "ON", "on" }, { "OFF", "off" } } },
    { key = "damage_number_size", label = "DAMAGE NUMBER SIZE", type = "choice",
      default = "2x", choices = { { "1X", "1x" }, { "2X", "2x" } } },
    { key = "damage_number_passive", label = "STATUS DAMAGE NUMBERS", type = "choice",
      default = "on", choices = { { "ON", "on" }, { "OFF", "off" } } },
    { key = "damage_number_heals", label = "HEAL NUMBERS", type = "choice",
      default = "on", choices = { { "ON", "on" }, { "OFF", "off" } } },
  })

  local getTime = love.timer and love.timer.getTime
  local function now() return getTime and getTime() or 0 end

  local LIFE, FADE, RISE, STALE = 0.95, 0.30, 16, 3.0
  local TEXT_H = 8

  local CLASSIC = {
    foe = { x = 120, y = 34 },
    player = { x = 44, y = 66 },
  }
  local WIDE = {
    foe = { x = 256, y = 34 },
    player = { x = 64, y = 74 },
  }

  local numberShader
  if love.graphics and love.graphics.newShader then
    local ok, shader = pcall(love.graphics.newShader, [[
      extern vec4 numberColor;
      vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
        vec4 px = Texel(texture, tc);
        return vec4(numberColor.rgb, numberColor.a * px.a * color.a);
      }
    ]])
    if ok then numberShader = shader end
  end

  local moveQueue = { foe = {}, player = {} }
  local track = { foe = {}, player = {} }
  local floats = {}
  local curBattle
  local lastMove = { user = nil, at = 0 }

  local function sideOf(battle, battler)
    if battler == battle.player then return "player" end
    if battler == battle.enemy then return "foe" end
  end

  local function passiveStyle(battler, t0)
    local status = battler and battler.mon and battler.mon.status
    if status == "PSN" then return Colors.semantic("poison") end
    if status == "BRN" then return Colors.semantic("burn") end
    if battler and battler.leechSeeded then return Colors.semantic("leech") end
    if battler == lastMove.user and t0 - lastMove.at < 1.5 then
      return Colors.semantic("recoil")
    end
    return Colors.semantic("neutralDamage")
  end

  local function resetFor(battle)
    curBattle = battle
    moveQueue = { foe = {}, player = {} }
    track = { foe = {}, player = {} }
    floats = {}
    lastMove = { user = nil, at = 0 }
  end

  mod.events:on("battle.started", function(e)
    if e and e.battle then resetFor(e.battle) end
  end)

  mod.events:on("battle.damage_dealt", function(e)
    if not (e and e.battle and e.target) then return end
    local side = sideOf(e.battle, e.target)
    if not side then return end
    local amount = math.floor((e.damage or 0) + 0.5)
    if amount <= 0 then return end

    lastMove = { user = e.user, at = now() }
    local q = moveQueue[side]
    q[#q + 1] = {
      amount = amount,
      type = e.move and e.move.type or nil,
      crit = e.crit and true or false,
      born = now(),
    }
  end)

  local function spawn(side, amount, color, t0, heal, crit)
    floats[#floats + 1] = {
      side = side, amount = amount, color = color,
      born = t0, heal = heal or false, crit = crit or false,
    }
    if #floats > 24 then table.remove(floats, 1) end
  end

  local function drawPlus(x, y, color, alpha)
    local g = love.graphics
    g.setShader()
    g.setColor(color[1], color[2], color[3], alpha)
    g.rectangle("fill", x, y + 2, 5, 1)
    g.rectangle("fill", x + 2, y, 1, 5)
  end

  local function drawText(text, x, y, color, alpha)
    local g = love.graphics
    if numberShader then
      g.setShader(numberShader)
      numberShader:send("numberColor", { color[1], color[2], color[3], alpha })
      g.setColor(1, 1, 1, 1)
    else
      g.setShader()
      g.setColor(color[1], color[2], color[3], alpha)
    end
    Font.draw(text, x, y)
  end

  local function anchors()
    local w = love.graphics and love.graphics.getWidth and love.graphics.getWidth() or 160
    return w > 200 and WIDE or CLASSIC
  end

  local function drawFloat(f, scale, t0)
    local text = tostring(f.amount)
    local width = Font.width(text) + (f.heal and 6 or 0)
    local age = t0 - f.born
    local t = math.max(0, math.min(1, age / LIFE))
    local anchor = anchors()[f.side]
    local y = anchor.y - RISE * (1 - (1 - t) * (1 - t))
    local alpha = 1
    if age > LIFE - FADE then
      alpha = math.max(0, (LIFE - age) / FADE)
    end

    if f.crit then y = y - 2 end

    local x0 = math.floor(-width / 2)
    local y0 = math.floor(-TEXT_H / 2)
    local plusW = f.heal and 6 or 0
    local g = love.graphics
    g.push("all")
    g.translate(anchor.x, y)
    g.scale(scale, scale)

    if f.heal then drawPlus(x0 + 1, y0 + 3, Colors.semantic("shadow"), alpha * 0.8) end
    drawText(text, x0 + plusW + 1, y0 + 1, Colors.semantic("shadow"), alpha * 0.8)

    if f.heal then drawPlus(x0, y0 + 2, f.color, alpha) end
    drawText(text, x0 + plusW, y0, f.color, alpha)
    g.pop()

    Engine.markTrueColor(
      math.floor(anchor.x - width * scale / 2) - 4,
      math.floor(y - TEXT_H * scale / 2) - 4,
      math.ceil(width * scale) + 8,
      math.ceil(TEXT_H * scale) + 8)
  end

  mod.hooks:wrap("battle.overlay", function(next, battle)
    local result = next()
    if not battle then return result end
    if battle ~= curBattle then resetFor(battle) end

    local t0 = now()
    local passive = mod.options:get("damage_number_passive") == "on"
    local heals = mod.options:get("damage_number_heals") == "on"
    local sides = { foe = battle.enemy, player = battle.player }

    for side, battler in pairs(sides) do
      local shown = battler and battler.shownHP
      if type(shown) == "number" then
        local tr = track[side]
        local draining = battler.draining and true or false

        if tr.mon ~= battler.mon then
          tr.mon, tr.prevShown, tr.wasDraining = battler.mon, shown, draining
          tr.startHP, tr.kind, tr.move = nil, nil, nil
        elseif draining and not tr.wasDraining then
          local startHP = tr.prevShown or shown
          local goal = battler.mon and battler.mon.hp or shown
          tr.startHP = startHP
          tr.kind, tr.move = nil, nil

          if goal < startHP - 0.001 then
            local q = moveQueue[side]
            if #q > 0 then
              tr.kind = "move"
              tr.move = table.remove(q, 1)
              spawn(side, tr.move.amount, Colors.type(tr.move.type), t0, false, tr.move.crit)
            else
              tr.kind = "passive"
            end
          elseif goal > startHP + 0.001 then
            tr.kind = "heal"
          end
          tr.wasDraining = true

        elseif (not draining) and tr.wasDraining then
          if tr.kind == "passive" and passive then
            local amount = math.floor((tr.startHP or shown) - shown + 0.5)
            if amount > 0 then
              spawn(side, amount, passiveStyle(battler, t0), t0, false, false)
            end
          elseif tr.kind == "heal" and heals then
            local amount = math.floor(shown - (tr.startHP or shown) + 0.5)
            if amount > 0 then
              spawn(side, amount, Colors.semantic("heal"), t0, true, false)
            end
          end
          tr.kind, tr.startHP, tr.move, tr.wasDraining = nil, nil, nil, false
        end
        tr.prevShown = shown
      end
    end

    for _, side in ipairs({ "foe", "player" }) do
      local q = moveQueue[side]
      local i = 1
      while i <= #q do
        if t0 - (q[i].born or t0) > STALE then table.remove(q, i) else i = i + 1 end
      end
    end

    if mod.options:get("damage_numbers") == "on" then
      local scale = mod.options:get("damage_number_size") == "1x" and 1 or 2
      for i = #floats, 1, -1 do
        if t0 - floats[i].born >= LIFE then
          table.remove(floats, i)
        else
          drawFloat(floats[i], scale, t0)
        end
      end
    end

    return result
  end)

  mod.exports.damageNumbers = { version = 1 }
  mod.log:info("damage numbers: clean type-color presentation installed")
end

return Feature
