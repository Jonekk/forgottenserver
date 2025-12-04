-- alchemy.lua
-- Core engine only: kettle, registry, resolve. No ingredient/recipe data here.

--local IngredientModule = require("ingredient")
--local Ingredient = IngredientModule.Ingredient
--local IngredientDef = IngredientModule.IngredientDef

local function clamp(n, lo, hi)
  if n < lo then return lo end
  if n > hi then return hi end
  return n
end

AlchemyBackend = {
  INGREDIENTS = {},      -- name -> IngredientDef
  COMBINE_RULES = {},    -- list of fn(kettle)
  RESULTS = {
    potion = {},         -- { id,name,result_match(kettle,snap)->0..100, result_brew(kettle,snap)->string }
    mishap = {},         -- same
  }
}

-- ====== Kettle ======
local Kettle = {}
Kettle.__index = Kettle

AlchemyBackend.Kettle = Kettle

function Kettle.new(pos, player)
  local self = setmetatable({}, Kettle)
  self.steps = {}                -- action history
  self.items = {}                -- list of Ingredient instances
  self.max_actions = 20
  self.resolved = false
  self._resolve_result = nil
  self.pos = pos
  self.player = player
  return self
end

function Kettle:log(action, data)
  table.insert(self.steps, {action = action, ts = os.time(), data = data})
end

function Kettle:_apply_triggers(trigger_key)
  -- copy to allow removal during iteration
  local snapshot = {}
  print("applying triggers")
  for i, it in ipairs(self.items) do snapshot[i] = it end
  for _, it in ipairs(snapshot) do
    it:trigger(trigger_key, self)
  end
  self:_apply_combine_rules()
end

function Kettle:_apply_combine_rules()
  -- global rules first
  for _, fn in ipairs(AlchemyBackend.COMBINE_RULES) do
    fn(self)
  end
  -- per-ingredient rules
  for _, it in ipairs(self.items) do
    for _, fn in ipairs(it.def.combine or {}) do
      fn(self)
    end
  end
end

function Kettle:add_ingredient(ingredient)
  if #self.steps >= self.max_actions then
    return false
  end
  table.insert(self.items, ingredient)
  self:log("add", {ingredient=ingredient})
  return true
end

function Kettle:add_virtual(name, overrides)
  return self:add_ingredient(name, overrides)
end

function Kettle:stir(direction)
  if #self.steps >= self.max_actions then
    return false
  end
  assert(direction == "left" or direction == "right", "stir: left|right")
  self:log("stir", direction)
  self:_apply_triggers(direction)
  return true
end

function Kettle:boil(temp)
  if #self.steps >= self.max_actions then
    return false
  end
  self:log("boil", temp)
  local key = ""
  temp = "boil_" .. temp
  self:_apply_triggers(temp)
  return true
end

-- Helpers
function Kettle:has(name)
  for _, it in ipairs(self.items) do
    if it.name == name then return true end
  end
  return false
end

function Kettle:get(name)
  for _, it in ipairs(self.items) do
    if it.name == name then return it end
  end
  return nil
end

function Kettle:ingredientCount(name)
  local c = 0
  for _, it in ipairs(self.items) do
    if it.name == name then c = c + 1 end
  end
  return c
end

function Kettle:totalIngredientsCount()
    return #self.items
end

function Kettle:getIngredientsStats(filters)
  local filterSet = nil
  if filters then
    filterSet = {}
    for _, f in ipairs(filters) do filterSet[f] = true end
  end

  local quality_sum = 0
  local purity_sum = 0
  local quality_count = 0
  local purity_count = 0
  for _, it in ipairs(self.items) do
    if not filterSet or filterSet[it.name] then
      if it.quality then quality_sum = quality_sum + it.quality quality_count = quality_count + 1 end
      if it.purity then purity_sum = purity_sum + it.purity purity_count = purity_count + 1 end
    end
  end
  local avg_quality = quality_sum / quality_count
  local avg_purity = purity_sum / purity_count
  return avg_quality, avg_purity
end

function Kettle:remove(name, count)
  local toRemove = count or 1
  local i = 1
  while i <= #self.items and toRemove > 0 do
    if self.items[i].name == name then
      table.remove(self.items, i)
      toRemove = toRemove - 1
    else
      i = i + 1
    end
  end
end

function Kettle:compose_state_snapshot()
  local idx = {}
  for _, it in ipairs(self.items) do
    idx[it.name] = (idx[it.name] or 0) + 1
  end
  return {
    items = self.items,
    index = idx,
    steps = self.steps,
  }
end

function Kettle:remove_instance(instance)
  for i, it in ipairs(self.items) do
    if it == instance then
      table.remove(self.items, i)
      return true
    end
  end
  return false
end
 
function Kettle:end_brew(opts)
  print("Kettle:end_brew 1")
  if self.resolved then return self._resolve_result end
  opts = opts or {}
  local snap = self:compose_state_snapshot()

  print("items in kettle")
  for _, item in ipairs(self.items) do
    print("===", item.name, item.quality)
  end

  print("Kettle:end_brew 2")
  -- step one - potion brew
  local best = {score=-1, def=nil}
  for _, def in ipairs(AlchemyBackend.RESULTS.potion) do
    local score = clamp(def.result_match(self, snap) or 0, 0, 100)
    print("--- ", def.id, score)
    if score > best.score then best = {score=score, def=def} end
  end
  if best.def and best.score >= (opts.potion_threshold or 60) then
    return best.def.result_brew(self, snap)
  end

  print("Kettle:end_brew 3")
  -- step two - failure type
  local mish = {score=-1, def=nil}
  for _, def in ipairs(AlchemyBackend.RESULTS.mishap) do
    local score = clamp(def.result_match(self, snap) or 0, 0, 100)
    if score > mish.score then mish = {score=score, def=def} end
  end
  print("Kettle:end_brew 4")
  if mish.def then
    print("Kettle:end_brew 5")
    return mish.def.result_brew(self, snap)
  end

  print("Kettle:end_brew 6")
  return self._resolve_result
end

-- ====== Registry API ======
function AlchemyBackend.register_ingredients()
  Ingredients.registerIngredients()
end

function AlchemyBackend.register_ingredient(itemId, name, def)
  local idef = IngredientDef.new(itemId, name, def)
  AlchemyBackend.INGREDIENTS[name] = idef
end

function AlchemyBackend.getIngredientDef(name)
  return AlchemyBackend.INGREDIENTS[name]
end

function AlchemyBackend.createItem(name, quality, purity)
    local def = AlchemyBackend.INGREDIENTS[name]
    if def then
        return Ingredient.new(def, quality, purity)
    end
    return nil
end

function AlchemyBackend.add_combine_rule(fn)
  table.insert(AlchemyBackend.COMBINE_RULES, fn)
end

function AlchemyBackend.register_result(kind, def)
  assert(kind == "potion" or kind == "mishap", "kind must be potion|mishap")
  assert(type(def)=="table" and def.result_match and def.result_brew, "result needs result_match & result_brew")
  table.insert(AlchemyBackend.RESULTS[kind], def)
end
