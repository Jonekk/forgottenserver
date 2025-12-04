-- recipes.lua
-- Export a function that receives the Alchemy module and registers results.
--[[
return function(Alchemy)
 
    -- POTIONS
    Alchemy.register_result("potion", {
      id="eliksir_witalnosci",
      name="Elixir of Vitality",
      result_match = function(kettle, snap)
        return 0
      end,
      result_brew = function(kettle)
        return {success = true, type="potion", potiontype="vitality", count=1, text="A clear greenish potion that restores vigor."}
      end
    })
  
    Alchemy.register_result("potion", {
      id="syrop_slodkiej_stali",
      name="Syrup of Sweet Steel",
      result_match = function(_, snap)
        return 0
      end,
      result_brew = function()
        return {success = true, type="potion", potiontype="steel", count=1, text="A dense syrup that briefly hardens the skin."}
      end
    })
  
    -- MISHAPS
    Alchemy.register_result("mishap", {
      id="small_explosion",
      result_match = function(kettle, snap)
        local matchScore = 100
        return clamp(matchScore, 0, 100)
      end,
      result_brew = function(kettle)
        return { success = false, type = "explosion", text="The cauldron explodes! Everyone nearby is soot-covered."}
      end
    })

  end
end

]]

local function clamp(n, lo, hi)
  if n < lo then return lo end
  if n > hi then return hi end
  return n
end

ALCHEMY_RESULTS =  {
  {
    type="potion",
    id="potion_vitality",
    result_match = function(kettle, snap)
      local life_essence = kettle:ingredientCount("life_essence")
      local stabilizator_essense_1 = kettle:ingredientCount("stabilizator_essense_1")
      if not life_essence or not stabilizator_essense_1 then return 0 end
      local total_items = kettle:totalIngredientsCount()
      return clamp(((life_essence + stabilizator_essense_1) / total_items) * 100, 0, 100)
    end,
    result_brew = function(kettle)
      local life_essence = kettle:ingredientCount("life_essence")
      local stabilizator_essense_1 = kettle:ingredientCount("stabilizator_essense_1")
      local count=math.min(life_essence, stabilizator_essense_1)
      local other_ingredients = kettle:totalIngredientsCount() - (life_essence + stabilizator_essense_1)
      local quality, purity = kettle:getIngredientsStats({"life_essence", "stabilizator_essense_1"})
      quality = quality / (other_ingredients + 1)
      quality = quality * (purity + 50) / 100
      return {success = true, type="potion", potiontype="vitality", count=count, quality=quality, text="A clear greenish potion that restores health."}
    end
  },
  {
    type="potion",
    id="potion_stamina",
    result_match = function(kettle, snap)
      local stamina_essence = kettle:ingredientCount("stamina_essence")
      local stabilizator_essense_1 = kettle:ingredientCount("stabilizator_essense_1")
      if not stamina_essence or not stabilizator_essense_1 then return 0 end
      local total_items = kettle:totalIngredientsCount()
      return clamp(((stamina_essence + stabilizator_essense_1) / total_items) * 100, 0, 100)
    end,
    result_brew = function(kettle)
      local stamina_essence = kettle:ingredientCount("stamina_essence")
      local stabilizator_essense_1 = kettle:ingredientCount("stabilizator_essense_1")
      local count=math.min(stamina_essence, stabilizator_essense_1)
      local other_ingredients = kettle:totalIngredientsCount() - (stamina_essence + stabilizator_essense_1)
      local quality, purity = kettle:getIngredientsStats({"stamina_essence", "stabilizator_essense_1"})
      quality = quality / (other_ingredients + 1)
      quality = quality * (purity + 50) / 100
      return {success = true, type="potion", potiontype="stamina", count=count, quality=quality, text="Some yellow potion that looks energising."}
    end
  },
  {
    type="potion",
    id="venomsap",
    result_match = function(kettle, snap)
      local poison_essence = kettle:ingredientCount("poison_essence")
      local life_essence = kettle:ingredientCount("life_essence")
      local stabilizator_essense_2 = kettle:ingredientCount("stabilizator_essense_2")
      if not poison_essence or not stabilizator_essense_2 then return 0 end
      local total_items = kettle:totalIngredientsCount()
      return clamp(((poison_essence + stabilizator_essense_2 + life_essence) / total_items) * 100, 0, 100)
    end,
    result_brew = function(kettle)
      local poison_essence = kettle:ingredientCount("poison_essence")
      local life_essence = kettle:ingredientCount("life_essence")
      local stabilizator_essense_2 = kettle:ingredientCount("stabilizator_essense_2")
      local count=math.min(poison_essence, stabilizator_essense_2)
      local other_ingredients = kettle:totalIngredientsCount() - (poison_essence + stabilizator_essense_2 + life_essence)
      local quality, purity = kettle:getIngredientsStats({"poison_essence", "stabilizator_essense_2", "life_essence"})
      quality = quality + math.min(life_essence - count, count) * 10
      quality = quality / (other_ingredients + 1)
      quality = quality * (purity + 50) / 100
      return {success = true, type="potion", potiontype="venomsap", count=count, quality=quality, text="Green, dense fluid with repulsive odor."}
    end
  },
  {
    type="potion",
    id="gorgons_tears",
    result_match = function(kettle, snap)
      local paralyze_essence = kettle:ingredientCount("paralyze_essence")
      local stamina_essence = kettle:ingredientCount("stamina_essence")
      local stabilizator_essense_2 = kettle:ingredientCount("stabilizator_essense_2")
      if not paralyze_essence or not stabilizator_essense_2 then return 0 end
      local total_items = kettle:totalIngredientsCount()
      return clamp(((paralyze_essence + stabilizator_essense_2 + stamina_essence) / total_items) * 100, 0, 100)
    end,
    result_brew = function(kettle)
      local paralyze_essence = kettle:ingredientCount("paralyze_essence")
      local stamina_essence = kettle:ingredientCount("stamina_essence")
      local stabilizator_essense_2 = kettle:ingredientCount("stabilizator_essense_2")
      local count=math.min(paralyze_essence, stabilizator_essense_2)
      local other_ingredients = kettle:totalIngredientsCount() - (paralyze_essence + stabilizator_essense_2 + stamina_essence)
      local quality, purity = kettle:getIngredientsStats({"paralyze_essence", "stabilizator_essense_2", "stamina_essence"})
      quality = quality + math.min(stamina_essence - count, count) * 10
      quality = quality / (other_ingredients + 1)
      quality = quality * (purity + 50) / 100
      return {success = true, type="potion", potiontype="gorgons_tears", count=count, quality=quality, text="This fluid almost doesnt move in the bottle."}
    end
  },
  {
    type="mishap",
    id="small_explosion",
    result_match = function(kettle, snap)
      local matchScore = 0
      return clamp(matchScore, 0, 100)
    end,
    result_brew = function(kettle)
      return { success = false, type = "explosion", text="The cauldron explodes! Everyone nearby is soot-covered."}
    end
  },
  {
    type="mishap",
    id="toxic_fumes",
    result_match = function(kettle, _)
      local matchScore = 100
      return clamp(matchScore, 0, 100)
    end,
    result_brew = function()
      return { success = false, type = "poison", text="Noxious fumes spread; bystanders feel dizzy."}
    end
  },
  {
    type="mishap",
    id="nothing",
    result_match = function(kettle, _)
        return 0.5
    end,
    result_brew = function()
      return { success = false, type = "nothing", text="The mixture evaporated instantly leaving nothing behind."}
    end
  }
}

function registerResults()
  for _, result in ipairs(ALCHEMY_RESULTS) do
    AlchemyBackend.register_result(result.type, result)
  end
  return true
end

-- call it!
registerResults()