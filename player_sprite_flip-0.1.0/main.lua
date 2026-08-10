-- Player Sprite Flip
-- ---------------------------------------------------------------------------
-- In the Dramatic Shape voxel mode a staged battle stands both Pokemon on the
-- map as camera-facing cards, using their FRONT pics. The mod flips your own
-- card horizontally so it "faces the foe" (BattleScene.monCards:
-- `mirror = side=="player" and not tex.trainer`). Depending on how the shot
-- lands that flip can leave your Pokemon looking the wrong way.
--
-- This companion mod flips the player's card back. It does NOT touch Dramatic
-- Shape's file layout: that mod exports its whole module namespace as
-- `exports.lib`, so we borrow its OverworldBattle module and wrap the one
-- function that hands the player's pic to the billboard --
-- OverworldBattle.sideTexture -- and return a horizontally-mirrored copy of
-- that pic. Since the billboard then mirrors it AGAIN, the two flips compose
-- to the opposite on-screen facing from the default: exactly a left/right
-- flip of what you currently see.
--
-- It only ever touches the PLAYER side, only its Pokemon pic (never the intro
-- trainer back), and only while a card is actually being stood on the map --
-- so BACK SPRITES mode (where your mon stays flat on the menu) is untouched,
-- and so is every non-voxel battle.
-- ---------------------------------------------------------------------------

return function(mod)
  local DS_ID = "DRAMATIC_SHAPE"

  ----------------------------------------------------------------------------
  -- Options
  ----------------------------------------------------------------------------
  mod.options:define({
    { key = "enabled", label = "FLIP MY POKEMON", type = "choice",
      default = "on", choices = { { "ON", "on" }, { "OFF", "off" } } },
  })

  -- Read the live value the player set, falling back to the default. The bucket
  -- is where the mod manager persists a choice; :get is the schema default.
  local Game
  local function game()
    if Game == nil then
      local ok, g = pcall(require, "src.core.Game")
      Game = (ok and g) or false
    end
    return Game or nil
  end

  local function isOn()
    local g = game()
    local opts = g and g.save and g.save.options
    local bucket = opts and opts.modOptions and opts.modOptions[mod.id]
    local v = bucket and bucket.enabled
    if v == nil then v = mod.options:get("enabled") end
    return v ~= "off"
  end

  ----------------------------------------------------------------------------
  -- The mirrored copy
  ----------------------------------------------------------------------------
  -- One canvas, reused: sideTexture is called every frame of every battle, so
  -- allocating here would churn a 160x144 texture sixty times a second. Sized
  -- to whatever the source pic canvas is; rebuilt only if that size changes.
  local flipCanvas = nil

  local function canvasFor(w, h)
    if flipCanvas then
      local cw, ch = flipCanvas:getDimensions()
      if cw == w and ch == h then return flipCanvas end
    end
    local ok, c = pcall(love.graphics.newCanvas, w, h, { dpiscale = 1 })
    if not (ok and c) then return nil end
    c:setFilter("nearest", "nearest")
    flipCanvas = c
    return c
  end

  -- A left/right mirror of `src` about the column `ax` (the pic's own centre
  -- column, which the billboard hangs the card from). Flipping about that same
  -- column keeps the reported anchor exact, so the feet stay on the tile.
  local function mirrored(src, ax)
    local w, h = src:getDimensions()
    if not (w > 0 and h > 0) then return nil end
    local dst = canvasFor(w, h)
    if not dst then return nil end
    local g = love.graphics
    local prevCanvas = g.getCanvas()
    local pr, pg, pb, pa = g.getColor()
    local pbm, pab = g.getBlendMode()
    local ok = pcall(function()
      g.setCanvas(dst)
      g.clear(0, 0, 0, 0)
      -- replace, not blend: copy the pic's exact pixels (colour AND alpha)
      -- rather than compositing it over the cleared canvas
      g.setBlendMode("replace")
      g.setColor(1, 1, 1, 1)
      -- sx = -1 anchored at x = 2*ax mirrors the image about the line x = ax:
      -- column u lands at 2*ax - u, so ax maps to itself.
      g.draw(src, 2 * ax, 0, 0, -1, 1)
    end)
    if prevCanvas then g.setCanvas(prevCanvas) else g.setCanvas() end
    g.setColor(pr, pg, pb, pa)
    g.setBlendMode(pbm, pab)
    return ok and dst or nil
  end

  ----------------------------------------------------------------------------
  -- The wrap
  ----------------------------------------------------------------------------
  -- Borrow Dramatic Shape's own OverworldBattle module (it exports its whole
  -- lib namespace) and wrap sideTexture in place. Idempotent -- a flag on the
  -- module means a hot reload, or a second copy of this mod, cannot stack it.
  local installed = false

  local function install()
    if installed then return true end
    local handle = mod.find(DS_ID)
    local lib = handle and handle.exports and handle.exports.lib
    if not (lib and lib.require) then return false end

    local ok, OB = pcall(lib.require, "OverworldBattle")
    if not (ok and type(OB) == "table" and OB.sideTexture) then return false end

    if OB.playerSpriteFlipHook then
      installed = true
      return true
    end

    local inner = OB.sideTexture
    OB.sideTexture = function(battle, side, ...)
      local res = inner(battle, side, ...)
      -- only the player's own Pokemon pic standing on the map, and only while
      -- the option is on; everything else (the foe, the intro trainer back,
      -- a nil side) passes straight through
      if not (res and res.canvas and side == "player" and not res.trainer
              and isOn()) then
        return res
      end
      local flip = mirrored(res.canvas, res.ax or 80)
      if not flip then return res end
      return { canvas = flip, ax = res.ax, ay = res.ay, trainer = res.trainer }
    end

    OB.playerSpriteFlipHook = true
    installed = true
    pcall(function() mod.log:info("hooked Dramatic Shape battle pics") end)
    return true
  end

  -- Try at load (if Dramatic Shape is already up), and again the moment a
  -- battle starts -- by then every mod is loaded, which covers any load order.
  pcall(install)
  mod.events:on("battle.started", function()
    pcall(install)
  end)
end
