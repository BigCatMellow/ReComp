-- effective-markers: a small icon showing how the selected move matches up
-- against the current opponent, anchored in the TYPE/PP info panel instead
-- of next to the move name -- that panel has real blank space regardless of
-- how long the move's name is, where the name column does not (see the
-- README for the exact pixel accounting). Neutral matchups draw nothing,
-- matching how the games themselves only ever announce a matchup that
-- isn't neutral.
return function(mod)
  local activeBattle = nil

  mod.events:on("battle.started", function(e) activeBattle = e.battle end)
  mod.events:on("battle.ended", function() activeBattle = nil end)

  -- Mirrors src/battle/TypeChart.lua's own effectiveness() -- x10 fixed
  -- point, floored after every row -- using only the public type_chart
  -- registry. Two 0.5x rows floor to a "0.2x" 2, not the algebraic 0.25x;
  -- that is a real Gen 1 damage-engine quirk, not a bug here, so it is
  -- left alone rather than "fixed".
  local function effectiveness(moveType, defenderTypes)
    local mult = 10
    for _, dt in ipairs(defenderTypes or {}) do
      local row = mod.content.type_chart:get(moveType .. ">" .. dt)
      if row and row.multiplier then
        mult = math.floor(mult * row.multiplier / 10)
      end
    end
    return mult
  end

  -- BattleState.lua moveSelect: TYPE/PP box is Font.drawBox(0,8,11,5) --
  -- x 0-88, interior x 8-80. "TYPE/" prints at (8,72), five characters
  -- (40px) into a 72px-wide row, leaving x 48-80 blank on that same row.
  -- The row is skipped entirely (blank) while the move is Disabled, so
  -- match that rather than float an icon over nothing.
  local function classicSlot(battle)
    local sel = battle.player and battle.player.curMoves and
      battle.player.curMoves[battle.moveIndex]
    if not sel then return nil end
    if battle.player.disabledSlot == battle.moveIndex then return nil end
    return sel, 72, 72 -- right-justified in the TYPE/ row, one 8px tile
  end

  -- WideBattle.lua drawMoveDetails: Font.drawBox(28,13,10,5) -- x 224-304,
  -- interior x 232-296. "PP xx/xx" prints at y=112, type at y=128; y=120
  -- is unused.
  local function wideSlot(battle)
    local sel = battle.player and battle.player.curMoves and
      battle.player.curMoves[battle.moveIndex]
    if not sel then return nil end
    return sel, 288, 120
  end

  -- The engine's own font glyphs (charmap.asm), reached through mod.ui.Font
  -- -- the documented stable mod-facing surface (src/ui/ModUI.lua) -- rather
  -- than a hand-drawn vector shape, so the marker reads as part of the game's
  -- own art instead of a foreign overlay. moreArrow ($EE) is the "more text
  -- below" prompt's down-triangle; rotated 180 about its own center it
  -- doubles as an up-triangle, so both directions come from one asset. $F1
  -- is the ROM's multiplication sign, an exact fit for "no effect". Both are
  -- black-on-transparent, tinted through setColor exactly like every other
  -- Font.drawCode call in the engine.
  local NO_EFFECT_GLYPH = 0xF1

  -- viewport is window space; battle content is laid out in its own
  -- 160x144 (or 304x144 wide) surface, so map through gameX/gameY/scale
  -- the way docs/modding.md's render.hud section spells out. Translating
  -- and scaling once up front lets the rest of this function work in the
  -- same game-pixel coordinates BattleState/WideBattle use.
  -- font.png bakes the glyphs as opaque black ink on a transparent field,
  -- not a white/alpha mask -- every setColor(0,0,0,1) before a Font.drawCode
  -- elsewhere in the engine is resetting alpha, not tinting from white, and
  -- black multiplied by any tint is still black. So color comes from a
  -- solid chip drawn behind the glyph instead of trying to tint the ink.
  local function drawMarker(viewport, x, y, mult)
    if mult == 10 then return end
    local Font = mod.ui.Font
    local moreArrow = mod.ui.Theme.moreArrow or 0xEE
    love.graphics.push()
    love.graphics.translate(viewport.gameX, viewport.gameY)
    love.graphics.scale(viewport.scale, viewport.scale)

    if mult == 0 then
      love.graphics.setColor(0.55, 0.55, 0.6, 1)
    elseif mult > 10 then
      love.graphics.setColor(0x00 / 255, 0xBD / 255, 0x00 / 255, 1) -- #00BD00
    else
      love.graphics.setColor(0xF7 / 255, 0x00 / 255, 0x00 / 255, 1) -- #F70000
    end
    love.graphics.rectangle("fill", x, y, 8, 8)

    love.graphics.setColor(0, 0, 0, 1)
    if mult == 0 then
      Font.drawCode(NO_EFFECT_GLYPH, x, y)
    elseif mult > 10 then
      love.graphics.translate(x + 4, y + 4) -- glyph's own center (8x8)
      love.graphics.rotate(math.pi)
      Font.drawCode(moreArrow, -4, -4)
    else
      Font.drawCode(moreArrow, x, y)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
  end

  mod.hooks:wrap("render.hud", function(next, game, viewport)
    next(game, viewport)
    if not viewport then return end
    if not activeBattle then return end
    if activeBattle.phase ~= "moveSelect" then return end

    local slot = activeBattle:isWideBattleLayout() and wideSlot or classicSlot
    local sel, x, y = slot(activeBattle)
    if not sel then return end

    local def = mod.content.moves:get(sel.id)
    if not def then return end
    if not def.power or def.power == 0 then return end -- status moves stay silent, like the games

    local defTypes = activeBattle.enemy and activeBattle.enemy.curTypes
    if not defTypes then return end

    local mult = effectiveness(def.type, defTypes)
    drawMarker(viewport, x, y, mult)
  end)
end