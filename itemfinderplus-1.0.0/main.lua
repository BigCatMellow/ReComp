-- ItemFinderPlus
--
-- While the ITEMFINDER is in your bag, tiles that hide items twinkle a
-- gentle sparkle every 2 seconds, whether you're inside the vanilla
-- detection radius or not (the same rectangle the original Item Finder
-- checks, so "close" means the same thing it always did). Close
-- sparkles are larger and brighter; distant ones are smaller and
-- subtler. The sparkle lives in the world canvas, so it stays glued to
-- its tile under zoom, tilt and wide view, and it vanishes the moment
-- the item is picked up.
--
-- No engine fork, no save changes: reads Game.data.field.hiddenItems
-- (the table the vanilla itemfinder checks), gates on
-- save.inventory.ITEMFINDER, and draws through the render.compose hook
-- before the engine composites the frame. The sparkle sprite is
-- sparkle.png -- a white 4-point star with a soft glow, tinted by
-- love.graphics.setColor so the twinkle is pure alpha modulation.

local FAR_ALPHA, NEAR_ALPHA = 0.5, 0.85
local FAR_SIZE, NEAR_SIZE = 7, 11 -- star width in pixels (sprite units)

return function(mod)
  -- logic.lua is loaded through the mod API, not require(): the mod dir
  -- is not mounted into love.filesystem, so a bare require("logic")
  -- would kill the whole mod at load time.
  local source = assert(mod:read("logic.lua"), "missing logic.lua")
  local chunk, err = (loadstring or load)(source, "=logic.lua")
  assert(chunk, err)
  local Logic = chunk()

  -- sparkle sprite (base for user edits)
  local sparkleImg = mod.assets:image("sparkle.png")
  local SW, SH = sparkleImg:getDimensions()

  local gameRef
  local state = {} -- Logic.tick state, keyed "<x>,<y>"

  -- The render.compose callback only receives (renderer, ctx); cache the
  -- game instance from the documented per-tick hook.
  mod.hooks:wrap("input.step", function(next, game, dt)
    gameRef = game
    return next(game, dt)
  end)

  local function sparklesEnabled()
    return mod.options:get("enabled") ~= "off"
  end

  local function drawStar(cx, cy, size, alpha, rot)
    love.graphics.setColor(1, 1, 1, alpha)
    local scale = size / SW
    love.graphics.draw(sparkleImg, cx, cy, rot, scale, scale, SW / 2, SH / 2)
  end

  mod.hooks:wrap("render.compose", function(next, renderer, ctx)
    if sparklesEnabled() and gameRef and ctx.worldActive
        and ctx.worldCanvas and not ctx.worldOverride then
      local save = gameRef.save
      local inv = save and save.inventory
      if inv and (inv.ITEMFINDER or 0) > 0 then
        local ow = gameRef.overworld
        local map = ow and ow.map
        local player = ow and ow.player
        local cam = ow and ow.camera
        if map and map.id and player and cam then
          local field = gameRef.data and gameRef.data.field
          local items = Logic.unfoundItems(
            field and field.hiddenItems, save.hiddenTaken, map.id)
          Logic.cleanup(state, items)
          if #items > 0 then
            local now = love.timer.getTime()
            local px, py = player.cellX, player.cellY
            local bursts = Logic.tick(items, state, px, py, now)
            if #bursts > 0 then
              local bgY = cam.y + (ow.bgShakeY or 0)
              local vw, vh = renderer:worldViewSize()
              local prev = love.graphics.getCanvas()
              love.graphics.setCanvas(ctx.worldCanvas)
              local ok, err = pcall(function()
                for _, b in ipairs(bursts) do
                  local sx = b.x * 16 + 8 - cam.x
                  local sy = b.y * 16 + 8 - bgY
                  if sx >= -24 and sx <= vw + 24
                      and sy >= -24 and sy <= vh + 24 then
                    local near = b.mode == "near"
                    local alpha = Logic.burstAlpha(now - b.startedAt)
                              * (near and NEAR_ALPHA or FAR_ALPHA)
                    if alpha > 0.02 then
                      drawStar(sx, sy,
                        Logic.burstSize(now - b.startedAt,
                          near and NEAR_SIZE or FAR_SIZE),
                        alpha, now * 0.6 + b.phase * 6.28)
                    end
                  end
                end
              end)
              love.graphics.setCanvas(prev)
              if not ok then error(err, 0) end
            end
          end
        end
      end
    end
    return next(renderer, ctx)
  end)

  -- ============= Voxel overworld adapter (DRAMATIC_SHAPE) =============
  -- Under the voxel pipeline the engine never runs render.compose with a
  -- composable world canvas: the pipeline owns the world pass and draws
  -- overlay FX itself via ctx.drawFx(project, scale), projected into the
  -- 3D view. So we wrap the voxel pipeline's drawWorld and swap ctx.drawFx:
  -- engine FX first (realDrawFx), then our sparkles at the same projected
  -- coordinates. Same interception the Wilds of Kanto spawn mod ships
  -- (lib/voxel_adapter.lua); zero patches to DRAMATIC_SHAPE. Fires only on
  -- voxel frames -- the engine itself never calls ctx.drawFx, and flat
  -- frames keep the render.compose path above.
  local voxelHooked, voxelDead = false, false

  local function drawSparklesProjected(project, scale)
    if not sparklesEnabled() or not gameRef then return end
    local save = gameRef.save
    local inv = save and save.inventory
    if not (inv and (inv.ITEMFINDER or 0) > 0) then return end
    local ow = gameRef.overworld
    local map = ow and ow.map
    local player = ow and ow.player
    if not (map and map.id and player) then return end
    local field = gameRef.data and gameRef.data.field
    local items = Logic.unfoundItems(
      field and field.hiddenItems, save.hiddenTaken, map.id)
    Logic.cleanup(state, items)
    if #items == 0 then return end
    local now = love.timer.getTime()
    local ok, err = pcall(function()
      for _, b in ipairs(Logic.tick(
          items, state, player.cellX, player.cellY, now)) do
        local sx, sy = project(b.x * 16 + 8, b.y * 16 + 8)
        if sx then -- nil = behind camera: free culling
          local near = b.mode == "near"
          local alpha = Logic.burstAlpha(now - b.startedAt)
                    * (near and NEAR_ALPHA or FAR_ALPHA)
          if alpha > 0.02 then
            drawStar(sx, sy,
              Logic.burstSize(now - b.startedAt,
                near and NEAR_SIZE or FAR_SIZE) * (scale or 1),
              alpha, now * 0.6 + b.phase * 6.28)
          end
        end
      end
    end)
    if not ok then error(err, 0) end
  end

  local function hookVoxelPipeline()
    if voxelDead then return false end
    local ok, Pipelines = pcall(require, "src.render.Pipelines")
    if not ok or type(Pipelines) ~= "table"
        or type(Pipelines.get) ~= "function" then
      voxelDead = true -- engine layout moved; sparkles stay flat-only
      return false
    end
    local def = Pipelines.get("voxel")
    if not def or type(def.drawWorld) ~= "function" then
      return false -- voxel pipeline not registered yet; retry next tick
    end
    local origDrawWorld = def.drawWorld
    def.drawWorld = function(ctx)
      local realDrawFx = ctx and ctx.drawFx
      if realDrawFx then
        ctx.drawFx = function(project, scale)
          realDrawFx(project, scale)
          drawSparklesProjected(project, scale)
        end
      end
      return origDrawWorld(ctx)
    end
    return true
  end

  -- DRAMATIC_SHAPE may load before or after us; install lazily from the
  -- per-tick hook until the voxel pipeline exists, then stop retrying.
  mod.hooks:wrap("input.step", function(next, game, dt)
    if not voxelHooked then
      voxelHooked = hookVoxelPipeline()
    end
    return next(game, dt)
  end)

  mod.options:define({
    {
      key = "enabled",
      type = "choice",
      label = "ITEMFINDER PLUS",
      choices = {
        { "ON", "on" },
        { "OFF", "off" },
      },
      default = "on",
    },
  })
end
