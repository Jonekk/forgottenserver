-- data/scripts/crafting/recipes_loader.lua
CRAFT = CRAFT or { recipes = {}, byCategory = {}, version = 0 }

-- bring in your recipes table; you can split across files and merge if you prefer
--dofile('data/talkactions/scripts/crafting.lua')  -- defines global "craftingRecipes"

-- small helpers
local function addIndex(outId, r)
  local cat = r.category or "misc"
  CRAFT.byCategory[cat] = CRAFT.byCategory[cat] or {}
  table.insert(CRAFT.byCategory[cat], outId)
  print(cat .. " " .. outId)
end

local function hash32(s)
    local h = 0
    for i = 1, #s do
      h = (h + s:byte(i)) % 4294967296
    end
    return h
  end

local function versionString()
  local keys = {}
  for id in pairs(craftingRecipes) do keys[#keys+1] = id end
  table.sort(keys)
  local parts = {}
  for _, id in ipairs(keys) do
    local r = craftingRecipes[id]
    parts[#parts+1] = string.format("%d:%d:%d:%s:%s",
      id,
      r.levelRequired or 0,
      r.staminaRequired or 0,
      r.category or "", r.subcategory or "")
  end
  return table.concat(parts, "|")
end

-- load into CRAFT
CRAFT.recipes = craftingRecipes
for outId, r in pairs(CRAFT.recipes) do addIndex(outId, r) end
CRAFT.version = hash32(versionString())
