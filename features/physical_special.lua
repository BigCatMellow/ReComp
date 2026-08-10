local Feature = { id = "physical_special" }

local PHYSICAL = {
  "FIRE_PUNCH", "ICE_PUNCH", "THUNDERPUNCH",
  "CRABHAMMER", "WATERFALL", "CLAMP",
  "RAZOR_LEAF", "VINE_WHIP",
}

local SPECIAL = {
  "GUST", "SWIFT", "TRI_ATTACK", "HYPER_BEAM", "RAZOR_WIND",
  "SONICBOOM", "ACID", "SLUDGE", "SMOG", "NIGHT_SHADE",
}

function Feature.install(ctx)
  local mod = ctx.mod

  mod.options:define({
    { key = "physical_special", label = "PHYSICAL/SPECIAL SPLIT", type = "choice",
      default = "on", choices = { { "ON", "on" }, { "OFF", "off" } } },
  })

  if mod.options:get("physical_special") ~= "on" then return end

  local patched = 0
  local function setCategory(id, category)
    if mod.content.moves:get(id) == nil then
      mod.log:warn("%s absent from merged move registry; category patch skipped", id)
      return
    end
    mod.content.moves:patch(id, { category = category })
    patched = patched + 1
  end

  for _, id in ipairs(PHYSICAL) do setCategory(id, "physical") end
  for _, id in ipairs(SPECIAL) do setCategory(id, "special") end

  mod.exports.physicalSpecial = {
    version = 1,
    physicalMoves = PHYSICAL,
    specialMoves = SPECIAL,
  }

  mod.log:info("physical/special split: patched %d move records", patched)
end

return Feature
