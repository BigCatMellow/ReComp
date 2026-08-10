-- All private-engine access for Definitive Gen 1 belongs here.
-- Features should prefer public mod APIs and come through this adapter only
-- when the public API cannot express the presentation detail.

local Engine = {}

local okPalette, PaletteFX = pcall(require, "src.render.PaletteFX")

function Engine.markTrueColor(x, y, w, h)
  if okPalette and PaletteFX and type(PaletteFX.markTrueColor) == "function" then
    pcall(PaletteFX.markTrueColor, x, y, w, h)
  end
end

function Engine.hasTrueColorMarking()
  return okPalette and PaletteFX and type(PaletteFX.markTrueColor) == "function"
end

return Engine
