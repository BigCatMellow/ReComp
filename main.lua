-- Definitive Gen 1
-- Cohesive modernization layer for Gen1Recomp.
-- Target baseline: Gen1Recomp 0.1.75 / Mod API 2.

return function(mod)
  local cache = {}
  local compiler = loadstring or load

  local function loadModule(path)
    if cache[path] ~= nil then return cache[path] end
    local source, readErr = mod:read(path)
    assert(source, ("could not read %s: %s"):format(path, tostring(readErr)))
    local chunk, compileErr = compiler(source, "@" .. mod.path .. "/" .. path)
    assert(chunk, ("could not compile %s: %s"):format(path, tostring(compileErr)))
    local value = chunk()
    cache[path] = value
    return value
  end

  local Colors = loadModule("lib/colors.lua")
  local Engine = loadModule("lib/engine_bridge.lua")

  local ctx = {
    mod = mod,
    colors = Colors,
    engine = Engine,
    load = loadModule,
  }

  local FEATURES = {
    "features/physical_special.lua",
    "features/damage_numbers.lua",
  }

  for _, path in ipairs(FEATURES) do
    local feature = loadModule(path)
    assert(type(feature) == "table" and type(feature.install) == "function",
      path .. " must return a feature table with install(ctx)")
    feature.install(ctx)
  end

  mod.exports.version = 1
  mod.exports.colors = Colors
  mod.exports.typeColor = Colors.type
  mod.exports.features = {
    physicalSpecial = true,
    damageNumbers = true,
  }

  mod.log:info("Definitive Gen 1 v%s loaded", tostring(mod.version or "0.1.0"))
end
