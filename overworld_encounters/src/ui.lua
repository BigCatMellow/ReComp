-- Overworld Encounters - UI & HUD Module
-- Renders a small, compact, natural Gen 1 7x2 tile UI box with true RGBA Poké Ball sprite rendering and clean pixel font counts.

local UIModule = {}

local CatchingModule = nil
local Font = require("src.render.Font")
local ballImageCache = {}

function UIModule.setCatchingModule(mod)
  CatchingModule = mod
end

local function getBallImage(ballType)
  local key = tostring(ballType or "POKE_BALL"):lower()
  if ballImageCache[key] == nil then
    local path = "mods/Gen1PC-OverworldEncounters-main/assets/sprites/ball_" .. key .. ".png"
    local ok, img = pcall(love.graphics.newImage, path)
    ballImageCache[key] = ok and img or false
  end
  return ballImageCache[key]
end

-- Screen-space UI draw (160x144 Game Boy canvas)
function UIModule.drawScreen(game, ow)
  if not love or not love.graphics then return end
  local lg = love.graphics

  local selectedBall = CatchingModule and CatchingModule.getSelectedBall(game) or "POKE_BALL"
  local save = game and game.save
  local count = (save and save.inventory and save.inventory[selectedBall]) or 0

  -- Push full graphics state
  lg.push("all")

  -- Explicitly reset shader to nil to guarantee TRUE COLOR rendering for ball PNGs (prevents map palette override)
  if lg.setShader then
    pcall(lg.setShader)
  end

  -- 1. Draw small, compact Gen 1 bordered box (Columns 13-19, Rows 16-17 -> 56x16px at bottom right)
  Font.drawBox(13, 16, 7, 2)

  -- 2. Draw true RGBA Poké Ball sprite PNG (16x16 frame containing centered 8x8 ball)
  local ballImg = getBallImage(selectedBall)
  if ballImg then
    lg.setColor(1, 1, 1, 1)
    lg.draw(ballImg, 105, 128)
  end

  -- 3. Draw clean, compact count text using native Gen 1 Font.draw
  lg.setColor(0, 0, 0, 1)
  Font.draw("× " .. tostring(count), 125, 132)

  lg.pop()
end

return UIModule
