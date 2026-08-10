-- Shared visual language for Definitive Gen 1.
-- Keep these colors stable: every feature should teach the same meaning.

local Colors = {}

Colors.TYPE = {
  NORMAL   = { 0.72, 0.72, 0.64 },
  FIRE     = { 0.94, 0.31, 0.19 },
  WATER    = { 0.39, 0.56, 0.94 },
  ELECTRIC = { 0.97, 0.81, 0.19 },
  GRASS    = { 0.48, 0.78, 0.30 },
  ICE      = { 0.59, 0.85, 0.84 },
  FIGHTING = { 0.76, 0.24, 0.20 },
  POISON   = { 0.64, 0.31, 0.66 },
  GROUND   = { 0.88, 0.75, 0.38 },
  FLYING   = { 0.66, 0.56, 0.94 },
  PSYCHIC  = { 0.98, 0.33, 0.53 },
  BUG      = { 0.65, 0.72, 0.10 },
  ROCK     = { 0.72, 0.63, 0.21 },
  GHOST    = { 0.55, 0.45, 0.75 },
  DRAGON   = { 0.44, 0.22, 0.97 },
  DARK     = { 0.55, 0.45, 0.40 },
  STEEL    = { 0.72, 0.72, 0.82 },
  FAIRY    = { 0.93, 0.60, 0.68 },
}

Colors.SEMANTIC = {
  text = { 1.00, 1.00, 1.00 },
  shadow = { 0.00, 0.00, 0.00 },
  heal = { 0.36, 0.92, 0.34 },
  recoil = { 0.95, 0.30, 0.28 },
  poison = { 0.70, 0.42, 0.82 },
  burn = { 1.00, 0.55, 0.22 },
  leech = { 0.42, 0.82, 0.30 },
  neutralDamage = { 0.82, 0.82, 0.82 },
  physical = { 0.90, 0.55, 0.28 },
  special = { 0.45, 0.68, 0.96 },
  status = { 0.68, 0.68, 0.68 },
}

function Colors.type(id)
  return Colors.TYPE[tostring(id or ""):upper()] or Colors.SEMANTIC.text
end

function Colors.semantic(id)
  return Colors.SEMANTIC[id] or Colors.SEMANTIC.text
end

return Colors
