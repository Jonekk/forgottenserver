-- ingredient.lua
-- Defines Ingredient and IngredientDef classes for alchemy system


-- IngredientDef: defines behavior, triggers, and combine rules.
IngredientDef = {}
IngredientDef.__index = IngredientDef

function IngredientDef.new(itemId, name, def)
  local self = setmetatable({}, IngredientDef)
  self.name = name
  self.triggers = {
    left        = (def.triggers and def.triggers.left)        or function() end,
    right       = (def.triggers and def.triggers.right)       or function() end,
    boil_low    = (def.triggers and def.triggers.boil_low)    or function() end,
    boil_medium = (def.triggers and def.triggers.boil_medium) or function() end,
    boil_high   = (def.triggers and def.triggers.boil_high)   or function() end,
  }
  self.combine = def.combine or {}

  if itemId > 0 then
    local it = ItemType(itemId)
    local clientId = it:getClientId()
    self.itemId = itemId
    self.clientId = clientId
  end
  return self
end

Ingredient = {}
Ingredient.__index = Ingredient

local function clamp(n, lo, hi)
  if n < lo then return lo end
  if n > hi then return hi end
  return n
end

function Ingredient.new(def, quality, purity)
  local self = setmetatable({}, Ingredient)
  self.def = def
  self.name = def.name
  self.quality = quality
  self.purity  = purity
  self.state   = {}   -- <=== per-instance state lives here (counters, flags, etc.)
  return self
end

function Ingredient:get_state(key)
  return self.state[key]
end

function Ingredient:set_state(key, value)
  self.state[key] = value
end
  
function Ingredient:change_state_number(key, delta)
  local v = self.state[key] or 0
  if not v then
    v = 0
  end
  if not type(v) == "number" then
    return false
  end
  v = v + delta
  self.state[key] = v
  return tru
end

function Ingredient:trigger(event, kettle)
  local fn = self.def.triggers[event]
  if fn then fn(self, kettle) end
end

function Ingredient:changeQuality(q)
  if q then self.quality = clamp(self.quality + q, 0, 300) end
end

function Ingredient:changePurity(p)
  if p then self.purity  = clamp(self.purity  + p, 0, 100) end
end

function Ingredient:transform(name)
  local def = AlchemyBackend.getIngredientDef(name)
  self.def = def
  self.name = def.name
  self.state = {}
end

---------------------------------------------------------------------