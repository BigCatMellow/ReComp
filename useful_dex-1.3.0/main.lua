-- Dex Info Pages: on the Pokédex species data page, A cycles between a
-- combined data/base-stat page and the full movelist (learned first, then
-- TM/HM).  B closes, and UP/DOWN pages the movelist when it runs long.
--
-- Dex List Views: SELECT on the Pokédex list cycles the view between the
-- standard numbered list, alphabetical (seen/owned only) and caught only.
--
-- Implemented as registered replacements for the "DexEntryMenu" and
-- "PokedexMenu" screens: Screens.resolve prefers the screens registry over
-- the builtin module, so a mod-free boot is untouched, and a throwing
-- factory degrades to the builtin (src/ui/Screens.lua).  The vanilla pages
-- delegate to real DexEntryMenu/PokedexMenu instances.
local Font = require("src.render.Font")
local Strings = require("src.core.Strings")
local TypeChart = require("src.battle.TypeChart")
local Sound = require("src.core.Sound")

local CRYSTAL_MOD = "crystal_animated_sprites_with_shiny_visuals"
local usefulMod

-- Crystal does not export its battle animation renderer, but its packaged
-- assets are addressable through the engine's virtual filesystem.  Use the
-- national Dex number and probe the numbered frame files, keeping this path
-- optional so a missing Crystal mod never breaks the Dex screen.
local function crystalIntegration(mod)
  local crystal = mod and mod:find(CRYSTAL_MOD)
  if not crystal then return nil end
  return { prefix = "mods/" .. CRYSTAL_MOD .. "/assets/front/normal" }
end

local function crystalFramePath(crystal, dex, frame)
  return ("%s/%d/%03d.png"):format(crystal.prefix, dex, frame)
end

local function crystalFrameCount(crystal, dex)
  if not love.filesystem or not love.filesystem.getInfo then return 0 end
  local count = 0
  while count < 100 do
    local path = crystalFramePath(crystal, dex, count + 1)
    if not love.filesystem.getInfo(path) then break end
    count = count + 1
  end
  return count
end

local Movelist = {}

-- Pure builder (published as mod.exports.buildMoves for headless tests).
-- learned: learnset in ROM order, one entry per move, { level, move, name }.
-- machines: the species' tmhm list mapped to item machine numbers, sorted
-- TM1..TM50 then HM1..HM5, { kind, number, move, name }.
function Movelist.build(data, def)
  local learned = {}
  local seen = {}
  for _, entry in ipairs(def.learnset or {}) do
    if not seen[entry.move] then
      seen[entry.move] = true
      local mdef = data.moves and data.moves[entry.move]
      local moveType = mdef and (mdef.type or mdef.typeId)
      local stab = false
      for _, speciesType in ipairs(def.types or {}) do
        if speciesType == moveType then stab = true break end
      end
      learned[#learned + 1] = {
        level = entry.level,
        move = entry.move,
        name = (mdef and mdef.name) or entry.move,
        type = moveType,
        stab = stab,
      }
    end
  end

  local machineByMove = {}
  for _, item in pairs(data.items or {}) do
    local m = item.machine
    if m and m.kind and m.number and m.move and not machineByMove[m.move] then
      machineByMove[m.move] = m
    end
  end

  local machines = {}
  for _, moveId in ipairs(def.tmhm or {}) do
    local m = machineByMove[moveId]
    if m then
      local mdef = data.moves and data.moves[moveId]
      local moveType = mdef and (mdef.type or mdef.typeId)
      local stab = false
      for _, speciesType in ipairs(def.types or {}) do
        if speciesType == moveType then stab = true break end
      end
      machines[#machines + 1] = {
        kind = m.kind,
        number = m.number,
        move = moveId,
        name = (mdef and mdef.name) or moveId,
        type = moveType,
        stab = stab,
      }
    end
  end
  table.sort(machines, function(a, b)
    local ka = a.kind == "HM" and 1 or 0
    local kb = b.kind == "HM" and 1 or 0
    if ka ~= kb then return ka < kb end
    return a.number < b.number
  end)

  return { learned = learned, machines = machines }
end

local StatsPage = {}

-- Pure builder (published as mod.exports.buildStats for headless tests).
-- stats: the five base stats in Gen 1 order, { key, value }.
-- bst: their sum.  evolutions: the species' evolutions with the merged
-- evolution_methods describe() label and the target species name.
function StatsPage.build(data, def)
  local bs = def.baseStats or {}
  local stats = {
    { key = "HP", value = bs.hp },
    { key = "ATK", value = bs.attack },
    { key = "DEF", value = bs.defense },
    { key = "SPD", value = bs.speed },
    { key = "SPC", value = bs.special },
  }
  local bst = 0
  for _, s in ipairs(stats) do bst = bst + (s.value or 0) end
  local evolutions = {}
  for _, evo in ipairs(def.evolutions or {}) do
    local method = data.evolution_methods and data.evolution_methods[evo.method]
    local label = method and method.describe and method.describe(evo, data)
      or evo.method
    local target = data.pokemon and data.pokemon[evo.species]
    evolutions[#evolutions + 1] = {
      method = evo.method,
      label = label,
      species = evo.species,
      name = (target and target.name) or evo.species,
    }
  end
  return { stats = stats, bst = bst, evolutions = evolutions }
end

local DexInfoScreen = {}
DexInfoScreen.__index = DexInfoScreen
DexInfoScreen.isOpaque = true

local ROWS_PER_PAGE = 6

-- The lower half of the horizontal learnset layout has room for six rows.
-- Keep the indicator colours vivid but close to the game's type palette.
local TYPE_COLORS = {
  NORMAL = { 0.65, 0.65, 0.55 }, FIGHTING = { 0.85, 0.35, 0.25 },
  FLYING = { 0.45, 0.65, 0.95 }, POISON = { 0.65, 0.35, 0.70 },
  GROUND = { 0.75, 0.55, 0.25 }, ROCK = { 0.55, 0.45, 0.30 },
  BUG = { 0.45, 0.70, 0.20 }, GHOST = { 0.40, 0.30, 0.60 },
  STEEL = { 0.55, 0.60, 0.65 }, FIRE = { 0.95, 0.30, 0.15 },
  WATER = { 0.20, 0.45, 0.90 }, GRASS = { 0.25, 0.75, 0.25 },
  ELECTRIC = { 0.95, 0.75, 0.10 }, PSYCHIC = { 0.90, 0.35, 0.65 },
  ICE = { 0.35, 0.80, 0.90 }, DRAGON = { 0.35, 0.25, 0.80 },
  DARK = { 0.30, 0.25, 0.25 }, FAIRY = { 0.90, 0.50, 0.75 },
}

-- A cycles the combined data/stats page and the movelist.
local NEXT_VIEW = { data = "moves", moves = "data" }

local function seenSpecies(data, save)
  local seen = save and save.pokedex and save.pokedex.seen or {}
  local species = {}
  for id, def in pairs(data.pokemon or {}) do
    if seen[id] and def.dex then species[#species + 1] = id end
  end
  table.sort(species, function(a, b)
    return data.pokemon[a].dex < data.pokemon[b].dex
  end)
  return species
end

function DexInfoScreen.new(game, speciesOrOpts)
  local Vanilla = require("src.ui.DexEntryMenu")
  local vanilla = Vanilla.new(game, speciesOrOpts)
  local self = setmetatable({
    game = game,
    vanilla = vanilla,
    def = vanilla.def,
    view = "data",   -- "data" (combined) | "moves"
    stats = StatsPage.build(game.data, vanilla.def),
    page = 1,
    crystal = crystalIntegration(usefulMod),
    crystalAnimation = nil,
  }, DexInfoScreen)
  -- Resolve through the battle kind as well, so sprite replacement hooks from
  -- animation/skin mods apply to the first entry and subsequent entries.
  self:setSpecies(vanilla.def.id, false)
  return self
end

function DexInfoScreen:setSpecies(species, playCry)
  local Sprites = require("src.pokemon.Sprites")
  local def = self.game.data.pokemon[species]
  local path, trueColor = Sprites.path(self.game.data, species, "front",
    { kind = "battle" })
  local ok, sprite = false, nil
  if path then ok, sprite = pcall(love.graphics.newImage, path) end
  self.def = def
  self.vanilla.def = def
  self.vanilla.sprite = ok and sprite or nil
  self.vanilla.spriteTrueColor = ok and trueColor or false
  self.crystalAnimation = nil
  self:setupCrystalAnimation()
  self.stats = StatsPage.build(self.game.data, def)
  self.list = nil
  self.page = 1
  if playCry then Sound.playCry(self.game.data, species) end
end

function DexInfoScreen:setupCrystalAnimation()
  local c = self.crystal
  local dex = c and tonumber(self.def.dex)
  local frames = dex and crystalFrameCount(c, dex) or 0
  if frames == 0 then return end
  self.crystalAnimation = { dex = dex, frame = 1, elapsed = 0,
    frames = frames }
  local ok, image = pcall(love.graphics.newImage,
    crystalFramePath(c, dex, 1))
  if ok and image then
    image:setFilter("nearest", "nearest")
    self.vanilla.sprite = image
    self.vanilla.spriteTrueColor = true
  end
end

function DexInfoScreen:updateCrystalAnimation(dt)
  local state = self.crystalAnimation
  if not state then return end
  state.elapsed = state.elapsed + (tonumber(dt) or 0) * 1000
  if state.elapsed < 100 then return end
  state.elapsed = state.elapsed - 100
  state.frame = state.frame + 1
  if state.frame > state.frames then state.frame = 1 end
  local ok, image = pcall(love.graphics.newImage,
    crystalFramePath(self.crystal, state.dex, state.frame))
  if ok and image then
    image:setFilter("nearest", "nearest")
    self.vanilla.sprite = image
  end
end

function DexInfoScreen:moveSeen(delta)
  local species = seenSpecies(self.game.data, self.game.save)
  if #species < 2 then return end
  local current
  for i, id in ipairs(species) do
    if id == self.def.id then current = i break end
  end
  if not current then return end
  local nextIndex = (current - 1 + delta) % #species + 1
  self:setSpecies(species[nextIndex], true)
end

function DexInfoScreen:sgbPalettes(game)
  return self.vanilla:sgbPalettes(game)
end

function DexInfoScreen:rows()
  local rows = {}
  local list = self.list or { learned = {}, machines = {} }
  if #list.learned > 0 then
    rows[#rows + 1] = "LEARNED"
    for _, e in ipairs(list.learned) do
      rows[#rows + 1] = ("LV %2d %s"):format(e.level, e.name)
    end
  end
  if #list.machines > 0 then
    rows[#rows + 1] = "TM/HM"
    for _, m in ipairs(list.machines) do
      rows[#rows + 1] = ("%s%02d %s"):format(m.kind, m.number, m.name)
    end
  end
  if #rows == 0 then rows[1] = "No moves known." end
  return rows
end

function DexInfoScreen:pages()
  return math.max(1, math.ceil(#self:rows() / ROWS_PER_PAGE))
end

function DexInfoScreen:rowMove(row)
  local list = self.list or { learned = {}, machines = {} }
  for _, move in ipairs(list.learned) do
    if row == ("LV %2d %s"):format(move.level, move.name) then return move end
  end
  for _, move in ipairs(list.machines) do
    if row == ("%s%02d %s"):format(move.kind, move.number, move.name) then
      return move
    end
  end
  return nil
end

-- The rows visible on the current page (ROWS_PER_PAGE per page).
function DexInfoScreen:pageRows()
  local rows = self:rows()
  local start = (self.page - 1) * ROWS_PER_PAGE
  local last = math.min(#rows, start + ROWS_PER_PAGE)
  local page = {}
  for i = start + 1, last do
    page[#page + 1] = rows[i]
  end
  return page
end

-- A cycles the combined data/stats page and moves, building moves on entry.
function DexInfoScreen:advance()
  self.view = NEXT_VIEW[self.view]
  if self.view == "moves" then
    self.list = Movelist.build(self.game.data, self.def)
    self.page = 1
  end
end

function DexInfoScreen:update(dt)
  self:updateCrystalAnimation(dt)
  local input = self.game.input
  if input:wasPressed("b") then
    self.game.stack:pop()
    return
  end
  if input:wasPressed("a") then
    self:advance()
    return
  end
  if self.view == "moves" then
    if input:wasPressed("up") then
      self:stepPage(-1)
    elseif input:wasPressed("down") then
      self:stepPage(1)
    end
  elseif input:wasPressed("up") then
    self:moveSeen(-1)
  elseif input:wasPressed("down") then
    self:moveSeen(1)
  end
end

-- Move the movelist one page, clamped to [1, pages()].
function DexInfoScreen:stepPage(delta)
  self.page = math.min(math.max(1, self.page + delta), self:pages())
end

function DexInfoScreen:draw()
  if self.view == "data" then
    self:drawData()
  else
    self:drawMoves()
  end
end

local function startFrame()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("fill", 0, 0, 160, 144)
  love.graphics.setColor(0, 0, 0, 1)
end

local function endFrame()
  love.graphics.setColor(1, 1, 1, 1)
end

function DexInfoScreen:drawData()
  startFrame()

  -- Keep the vanilla entry details in the top half, then use the lower half
  -- for the base stats, matching the compact printed dex layout.
  local sprite = self.vanilla.sprite
  if sprite then
    -- startFrame leaves drawing black for text; restore white before drawing
    -- the sprite or its transparent pixels become a solid silhouette.
    love.graphics.setColor(1, 1, 1, 1)
    local y = math.max(0, 48 - sprite:getHeight())
    love.graphics.draw(sprite, 8, y)
    love.graphics.setColor(0, 0, 0, 1)
    if self.vanilla.spriteTrueColor then
      require("src.render.PaletteFX").markTrueColor(8, y, sprite:getDimensions())
    end
  end

  local e = self.def.dexEntry or {}
  Font.draw(self.def.name, 72, 8)
  Font.draw(e.kind or "?", 72, 20)
  local digits = (self.game.data.constants or {}).dexDigits or 3
  Font.draw(("No.%0" .. digits .. "d"):format(self.def.dex or 0), 8, 54)

  local owned = self.vanilla.forceOwned
    or (self.game.save and self.game.save.pokedex
      and self.game.save.pokedex.owned[self.def.id])
  if owned and e.heightFt then
    if e.heightM then
      Font.draw((("GR. %.1fm"):format(e.heightM):gsub("(%d)%.(%d)", "%1,%2")), 72, 32)
      Font.draw((("GEW. %.1fkg"):format(e.weightKg or 0):gsub("(%d)%.(%d)", "%1,%2")), 72, 42)
    else
      Font.draw(Strings("HT %d′%02d″", e.heightFt, e.heightIn or 0), 72, 32)
      Font.draw(Strings("WT %.1flb", (e.weight or 0) / 10), 72, 42)
    end
  end

  love.graphics.rectangle("fill", 0, 64, 160, 1)
  local types = self.def.types or {}
  Font.draw("TYPE1/", 8, 76)
  Font.draw(TypeChart.displayName(types[1] or "?"), 8, 86)
  if types[2] then
    Font.draw("TYPE2/", 8, 96)
    Font.draw(TypeChart.displayName(types[2]), 8, 106)
  end

  Font.draw("BASE STATS", 72, 68)
  local y = 78
  for _, s in ipairs(self.stats.stats) do
    Font.draw(s.key, 72, y)
    local value = tostring(s.value or 0)
    Font.draw(value, 152 - Font.width(value), y)
    y = y + 10
  end
  Font.draw("TOTAL", 72, 128)
  local bst = tostring(self.stats.bst)
  Font.draw(bst, 152 - Font.width(bst), 128)
  endFrame()
end

function DexInfoScreen:drawMoves()
  startFrame()

  -- Keep the same horizontal split as the combined page: identity and the
  -- Crystal/battle sprite occupy the top half, while the learnset is below.
  local sprite = self.vanilla.sprite
  if sprite then
    love.graphics.setColor(1, 1, 1, 1)
    local x = 8
    local y = math.max(0, 48 - sprite:getHeight())
    love.graphics.draw(sprite, x, y)
    love.graphics.setColor(0, 0, 0, 1)
    if self.vanilla.spriteTrueColor then
      require("src.render.PaletteFX").markTrueColor(x, y, sprite:getDimensions())
    end
  end

  local e = self.def.dexEntry or {}
  Font.draw(self.def.name, 72, 8)
  Font.draw(e.kind or "?", 72, 20)
  local digits = (self.game.data.constants or {}).dexDigits or 3
  Font.draw(("No.%0" .. digits .. "d"):format(self.def.dex or 0), 8, 54)

  love.graphics.rectangle("fill", 0, 64, 160, 1)
  Font.draw("LEARNSET", 8, 68)
  local y = 78
  for _, row in ipairs(self:pageRows()) do
    local move = self:rowMove(row)
    if move and move.stab and move.type then
      local color = TYPE_COLORS[tostring(move.type):upper()]
      if color then
        love.graphics.setColor(color[1], color[2], color[3], 1)
        love.graphics.rectangle("fill", 8, y + 2, 5, 5)
        love.graphics.setColor(0, 0, 0, 1)
      end
    end
    Font.draw(row, 16, y)
    y = y + 10
  end
  if self:pages() > 1 then
    Font.draw(("PAGE %d/%d"):format(self.page, self:pages()), 112, 136)
  end
  endFrame()
end

-- ---------- Dex list views (SELECT cycles num / alpha / caught) ----------

local DexList = {}

local MODE_LABELS = {
  num = "POKéDEX",
  alpha = "POKéDEX A-Z",
  caught = "POKéDEX CAUGHT",
}
local NEXT_MODE = { num = "alpha", alpha = "caught", caught = "num" }

-- Pure builder (published as mod.exports.buildList for headless tests).
-- mode "num": every dex slot in dex order, unseen slots as "-----".
-- mode "alpha": only seen/owned, sorted by name, dex number kept.
-- mode "caught": only owned, in dex order.
-- Returns { items, seen, owned }; items are { label, ball, value } like the
-- vanilla list so the side menu and cursor logic are untouched.
function DexList.build(data, save, mode)
  save = save or { seen = {}, owned = {} }
  local byDex = {}
  for species, def in pairs(data.pokemon) do
    if def.dex then byDex[def.dex] = def end
  end
  local constants = data.constants or {}
  local numFmt = ("%%0%dd"):format(constants.dexDigits or 3)
  local entries = {}
  local seen, owned = 0, 0
  for n = 1, constants.dexSize or 151 do
    local def = byDex[n]
    if def then
      local has = save.owned[def.id] or save.seen[def.id]
      if has then
        if save.owned[def.id] then owned = owned + 1 end
        seen = seen + 1
      end
      if mode == "num"
          or (mode == "alpha" and has)
          or (mode == "caught" and save.owned[def.id]) then
        entries[#entries + 1] = { def = def, n = n, has = has }
      end
    end
  end
  if mode == "alpha" then
    table.sort(entries, function(a, b)
      return a.def.name < b.def.name
    end)
  end
  local items = {}
  for _, e in ipairs(entries) do
    items[#items + 1] = {
      label = (numFmt .. " %s"):format(e.n, e.has and e.def.name or "-----"),
      ball = save.owned[e.def.id] or nil,
      value = e.has and e.def.id or nil,
    }
  end
  return { items = items, seen = seen, owned = owned }
end

-- Index of the first item whose value matches, or nil. Used to keep the
-- cursor on the same species across a view switch when it survives.
local function indexOfValue(items, value)
  for i, item in ipairs(items) do
    if item.value == value then return i end
  end
end

-- Registered replacement for the "PokedexMenu" screen: builds the vanilla
-- list, then hooks SELECT (ListMenu's onSelectKey) to rebuild it in the
-- next view, keeping the cursor on the same species when it survives.
function DexList.new(game, opts)
  local Vanilla = require("src.ui.PokedexMenu")
  local list = Vanilla.new(game, opts)
  list.wrap = true -- Up on the first row / Down on the last wraps around
  local mode = "num"
  local function rebuild(prebuilt)
    local build = prebuilt or DexList.build(game.data, game.save.pokedex, mode)
    local current = list.items[list.index] and list.items[list.index].value
    list.title = MODE_LABELS[mode]
    -- fixed three-digit fields keep the footer at 17 glyphs, under the
    -- 18-column wrap the vanilla footer already learned the hard way (#639)
    list.footer = Strings("SEEN %3d  OWN %3d", build.seen, build.owned)
    list.items = build.items
    list.index = 1
    list.scroll = 0
    if current then
      local i = indexOfValue(build.items, current)
      if i then list.index = i end
    end
    -- the restored cursor can sit past the visible rows; clamp the scroll
    -- now so the frame that draws right after update() shows the right page
    if list.index - list.scroll > list.rows then
      list.scroll = list.index - list.rows
    end
  end
  list.onSelectKey = function()
    local nextMode = NEXT_MODE[mode]
    local build = DexList.build(game.data, game.save.pokedex, nextMode)
    -- an empty filtered view (nothing seen/owned) strands SELECT: ListMenu
    -- returns before onSelectKey when the list is empty, so stay put
    if #build.items == 0 then return end
    mode = nextMode
    rebuild(build)
  end
  return list
end

return function(mod)
  usefulMod = mod
  mod.content.screens:register("DexEntryMenu", { new = DexInfoScreen.new })
  mod.content.screens:register("PokedexMenu", { new = DexList.new })
  mod.exports = {
    buildMoves = Movelist.build,
    buildStats = StatsPage.build,
    buildList = DexList.build,
  }
end
