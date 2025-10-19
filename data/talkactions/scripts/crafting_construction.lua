CONSTRUCTION_BLUEPRINT_ID = 26402

WOODEN_WALL_RECIPE = {
    [1] = { levelRequired = 1, staminaRequired = 200, quality = 90, durability = 1000, materials = {
        [ITEM_WOODEN_STICK]     = {count = 5},
        [ITEM_PIECE_OF_WOOD]	= {count = 20},
        },
    },
}

WOODEN_WALL_LOCKING_DOOR = {
    [1] = { levelRequired = 2, staminaRequired = 300, quality = 90, durability = 500, materials = {
        [ITEM_WOODEN_STICK]     = {count = 15},
        [ITEM_PIECE_OF_WOOD]	= {count = 30},
        },
    },
}

local craftingConstructionRecipes = {
	-- wooden fences
	[5270] = WOODEN_WALL_RECIPE, -- horizontal
	[5268] = WOODEN_WALL_RECIPE, -- vertical
	[5263] = WOODEN_WALL_RECIPE, -- pole
    [5265] = WOODEN_WALL_RECIPE, -- L
    [5279] = WOODEN_WALL_RECIPE, -- door
    [5286] = WOODEN_WALL_LOCKING_DOOR, -- locking door
	-- fire
	[1421] = {
		[1] = { levelRequired = 1, staminaRequired = 50, quality = 90, durability = 500, materials = {
        	[ITEM_SMALL_STONE]	= {count = 20},
        	},
		}
    },
}

function onSay(player, words, param)
	local split = param:splitTrimmed(",")
	local itemId = getItemId(split[1])
	local level = tonumber(split[2])
	local recipe = craftingConstructionRecipes[itemId][level]

	if recipe == nil then
		player:sendCancelMessage(("Recipe %s[%d] not found"):format(split[1], level))
		return false
	end

	local blueprintItem = craft(player, itemId, recipe, SKILL_CRAFTING, CONSTRUCTION_BLUEPRINT_ID)
	if blueprintItem then
		player:addItemEx(blueprintItem)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	else
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
	end
	return false
end
