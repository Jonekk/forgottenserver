FARMING_BLUEPRINT_ID = 26407

local craftingFarmingRecipes = {
	[2786] = { -- bluewberry bush
		[1] = { levelRequired = 1, staminaRequired = 50, quality = 90, durability = 500, watering = 50, fertility = 50, materials = {
				[ITEM_WOODEN_STICK]		= {count = 3},
				[2677]	        		= {count = 50}, -- blueberry
				[26411]	        		= {count = 2}, -- fertilizer
        	},
		}
    },
	[26408] = { -- strawberry bush
		[1] = { levelRequired = 1, staminaRequired = 50, quality = 90, durability = 500, watering = 50, fertility = 50, materials = {
				[ITEM_WOODEN_STICK]		= {count = 3},
				[2680]	        		= {count = 10}, -- strawberry
				[26411]	        		= {count = 2}, -- fertilizer
        	},
		}
    },
}


function onSay(player, words, param)
	local split = param:splitTrimmed(",")
	local itemId = getItemId(split[1])
	local level = tonumber(split[2])
	local recipe = craftingFarmingRecipes[itemId][level]

	if recipe == nil then
		player:sendCancelMessage(("Recipe %s[%d] not found"):format(split[1], level))
		return false
	end

	local blueprintItem = craft(player, itemId, recipe, SKILL_FARMING, FARMING_BLUEPRINT_ID)
	if blueprintItem then
		player:addItemEx(blueprintItem)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	else
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
	end
	return false
end
