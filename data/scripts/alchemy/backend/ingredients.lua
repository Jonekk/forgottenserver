local function averageQuality(items)
    local sum = 0
    for i, item in ipairs(items) do
        sum = sum + (item.quality or 0)
    end
    return #items > 0 and sum / #items or 0
end

local function averagePurity(items)
    local sum = 0
    for i, item in ipairs(items) do
        sum = sum + (item.purity or 0)
    end
    return #items > 0 and sum / #items or 0
end

local function floorPurity(items)
    local lowest = 1000
    for i, item in ipairs(items) do
        if item.purity < lowest then
            lowest = item.purity
        end
    end
    return lowest
end

local INGREDIENTS = {
  { name = "goo", triggers = {
    right = function(item) --[[ nothing ]] end,
    left  = function(item) --[[ nothing ]] end,
    boil_low    = function(item) --[[ nothing ]] end,
    boil_medium = function(item) --[[ nothing ]] end,
    boil_high   = function(item) --[[ nothing ]] end,
    }
  },
  { name = "stabilizator_essense_1", triggers = {
    right = function(item) --[[ nothing ]] end,
    left  = function(item) --[[ nothing ]] end,
    boil_low    = function(item) item:change_state_number("boils", 1) if item:get_state("boils") > 5 then item:transform("goo") end end,
    boil_medium = function(item) item:change_state_number("boils", 2) if item:get_state("boils") > 5 then item:transform("goo") end end,
    boil_high   = function(item) item:change_state_number("boils", 3) if item:get_state("boils") > 5 then item:transform("goo") end end,
    }
  },
  { name = "stabilizator_essense_2", triggers = {
    right = function(item) --[[ nothing ]] end,
    left  = function(item) --[[ nothing ]] end,
    boil_low    = function(item) item:change_state_number("boils", 1) if item:get_state("boils") > 5 then item:transform("goo") end end,
    boil_medium = function(item) item:change_state_number("boils", 2) if item:get_state("boils") > 5 then item:transform("goo") end end,
    boil_high   = function(item) item:change_state_number("boils", 3) if item:get_state("boils") > 5 then item:transform("goo") end end,
    }
  },
  { name = "stamina_essence", triggers = {
    right = function(item) item:changeQuality(2) item:change_state_number("stirs", 1) if item:get_state("stirs") > 5 then item:changeQuality(-10) end end,
    left  = function(item) item:changeQuality(2) item:change_state_number("stirs", 1) if item:get_state("stirs") > 5 then item:changeQuality(-10) end end,
    boil_low    = function(item) item:change_state_number("boils", 1) if item:get_state("boils") > 5 then item:transform("goo") end end,
    boil_medium = function(item) item:change_state_number("boils", 1) if item:get_state("boils") > 5 then item:transform("goo") end end,
    boil_high   = function(item) item:change_state_number("boils", 1) if item:get_state("boils") > 5 then item:transform("goo") end end,
    }
  },
  { name = "life_essence", triggers = {
    right = function(item) --[[ nothing ]] end,
    left  = function(item) --[[ nothing ]] end,
    boil_low    = function(item) item:changeQuality(2) item:change_state_number("boils", 1) if item:get_state("boils") > 5 then item:transform("goo") end end,
    boil_medium = function(item) item:changeQuality(5) item:change_state_number("boils", 1) if item:get_state("boils") > 5 then item:transform("goo") end end,
    boil_high   = function(item) item:changeQuality(-10) item:change_state_number("boils", 1) if item:get_state("boils") > 5 then item:transform("goo") end end,
    }
  },
  { name = "poison_essence", triggers = {
    right = function(item) --[[ nothing ]] end,
    left  = function(item) --[[ nothing ]] end,
    boil_low    = function(item) item:changeQuality(-10) item:change_state_number("boils", 1) if item:get_state("boils") > 5 then item:transform("goo") end end,
    boil_medium = function(item) item:changeQuality(-10) item:change_state_number("boils", 1) if item:get_state("boils") > 5 then item:transform("goo") end end,
    boil_high   = function(item) item:changeQuality(-10) item:change_state_number("boils", 1) if item:get_state("boils") > 5 then item:transform("goo") end end,
    }
  },
  { name = "paralyze_essence", triggers = {
    right = function(item) --[[ nothing ]] end,
    left  = function(item) --[[ nothing ]] end,
    boil_low    = function(item) item:changeQuality(-5) item:change_state_number("boils", 1) if item:get_state("boils") > 5 then item:transform("goo") end end,
    boil_medium = function(item) item:changeQuality(1) item:change_state_number("boils", 1) if item:get_state("boils") > 5 then item:transform("goo") end end,
    boil_high   = function(item) item:changeQuality(10) item:change_state_number("boils", 1) if item:get_state("boils") > 5 then item:transform("goo") end end,
    }
  },
  { id = 26428, name = "starveil leaf", triggers = {
      right = function(item) item:changeQuality(1) end,
      left  = function(item) item:changeQuality(1) end,
      boil_low    = function(item) item:changeQuality(2) item:transform("stamina_essence") end,
      boil_medium = function(item) item:transform("stamina_essence") end,
      boil_high   = function(item) item:transform("goo") end,
      }
  },
  { id = 26431, name = "lifevine leaf", triggers = {
    right = function(item) --[[ nothing ]] end,
    left  = function(item) --[[ nothing ]] end,
    boil_low    = function(item) item:transform("life_essence") end,
    boil_medium = function(item) item:transform("life_essence") end,
    boil_high   = function(item) item:transform("goo") end,
    }
  },
  { id = 26443, name = "swamptorch root", triggers = {
    right = function(item) --[[ nothing ]] end,
    left  = function(item) --[[ nothing ]] end,
    boil_low    = function(item) item:transform("stabilizator_essense_1") end,
    boil_medium = function(item) item:transform("stabilizator_essense_1") end,
    boil_high   = function(item) item:transform("stabilizator_essense_2") end,
    }
  },
  { id = 26437, name = "mirelace core", triggers = {
    right = function(item) --[[ nothing ]] end,
    left  = function(item) --[[ nothing ]] end,
    boil_low    = function(item) item:transform("poison_essence") end,
    boil_medium = function(item) item:transform("poison_essence") end,
    boil_high   = function(item) item:transform("paralyze_essence") end,
    }
  },
}

function registerIngredients()
  for _, ingredient in ipairs(INGREDIENTS) do
    local id = ingredient.id or 0
    AlchemyBackend.register_ingredient(id, ingredient.name, {triggers = ingredient.triggers, combine = ingredient.combine})
  end
  return true
end


-- call it!
registerIngredients()

--[[
    -- honey
    Alchemy.register_ingredient(0, "honey", {
      triggers = {
        right = function(item) item:changeQuality(8) end,
        left  = function(item) item:changeQuality(-3) end,
        boil_low    = function(item) item:changeQuality(2) end,
        boil_medium = function(item) item:changeQuality(4) end,
        boil_high   = function(item) item:changeQuality(-10) end,
      }
    })
  
    -- mandrake
    Alchemy.register_ingredient(0, "mandrake", {
      triggers = {
        boil_low    = function(item) item:changeQuality(1) end,
        boil_medium = function(item) item:changeQuality(2) end,
        boil_high   = function(item) item:changeQuality(-5) end,
      },
      combine = {
        -- mandrake + salt -> pickled_mandrake
        function(kettle)
          local mandrake = kettle:get("mandrake")
          local salt = kettle:get("salt")
          if mandrake and salt then
            kettle:add_ingredient(Alchemy.createItem("pickled_mandrake"), averageQuality({mandrake, salt}), averagePurity({mandrake, salt}))
            kettle:remove_instance(mandrake)
            kettle:remove_instance(salt)
          end
        end
      }
    })
  
    -- salt
    Alchemy.register_ingredient(0, "salt", {
      triggers = {
        left = function(_, kettle)
          for _, it in ipairs(kettle.items) do
            if it.name ~= "salt" then it:changeQuality(4) end
          end
        end,
        boil_high = function(item) changeQuality(item, 10) end,
      }
    })
  
    -- iron_shavings
    Alchemy.register_ingredient(0, "iron_shavings", {
      triggers = {
        boil_low    = function(item) item:changeQuality(item, 1) end,
        boil_medium = function(item) item:changeQuality(item, 2) end,
        boil_high   = function(item) item:changeQuality(item, -2) end,
      },
      combine = {
        function(kettle)
          if kettle.temp == "medium" and kettle:has("iron_shavings") and kettle:has("honey") then
            kettle:remove("iron_shavings", 1)
            local h = kettle:get("honey")
            if h then h:changeQuality(3) end
            kettle:add_virtual("sweet_iron", {quality=58, purity=45})
          end
        end
      }
    })
  
    -- sweet_iron (product)
    Alchemy.register_ingredient(0, "sweet_iron", {
      triggers = {
        right = function(item) item:changeQuality(1) end,
      }
    })
  
    -- bat_wing
    Alchemy.register_ingredient(0, "bat_wing", {
      triggers = {
        left = function(item, kettle) kettle:remove("bat_wing", 1) end, -- dissolves on left stir
        boil_high = function(item) item:changeQuality(-8) end,
      }
    })
  
    -- pickled_mandrake (product)
    Alchemy.register_ingredient(0, "pickled_mandrake", {
      triggers = {}
    })
  
    -- (Optional) more global combine rules via:
    -- Alchemy.add_combine_rule(function(kettle) ... end)
  end
  
]]