CONSTRUCTION_BLUEPRINT_ID = 26402

WOODEN_WALL_RECIPE = {
	levelRequired = 1, staminaRequired = 200, quality = 90, durability = 1000, materials = {
        [ITEM_WOODEN_STICK]     = {count = 5},
        [ITEM_PIECE_OF_WOOD]	= {count = 20},
    },
}

WOODEN_WALL_LOCKING_DOOR = {
    levelRequired = 2, staminaRequired = 300, quality = 90, durability = 500, materials = {
        [ITEM_WOODEN_STICK]     = {count = 15},
        [ITEM_PIECE_OF_WOOD]	= {count = 30},
    },
}

local function recipe(template, recipeId, itemId)
	return setmetatable({ recipeId = recipeId, itemId = itemId }, { __index = template })
end

local craftingConstructionRecipes = {
	-- wooden fences
	recipe(WOODEN_WALL_RECIPE, "horizontal", 5270), -- horizontal
	recipe(WOODEN_WALL_RECIPE, "vertical", 5268), -- vertical
	recipe(WOODEN_WALL_RECIPE, "pole", 5263), -- pole
    recipe(WOODEN_WALL_RECIPE, "L", 5265), -- L
    recipe(WOODEN_WALL_RECIPE, "door", 5279), -- door
	recipe(WOODEN_WALL_LOCKING_DOOR, "locking door", 5286), -- door
	{ recipeId = "campfire", itemId = 1421, levelRequired = 1, staminaRequired = 50, quality = 90, durability = 500, materials = {
	      	[ITEM_SMALL_STONE]	= {count = 20},
        },
    },
	{ recipeId = "wooden chest", itemId = 8587, levelRequired = 1, staminaRequired = 50, quality = 90, durability = 500, materials = {
		[ITEM_PIECE_OF_WOOD]	= {count = 20},
  	},
},
}

function onSay(player, words, param)
	local split = param:splitTrimmed(",")
	local recipeId = split[1]
	local grade = tonumber(split[2]) or 1 -- ignored for now
	local recipe = findRecipe(craftingConstructionRecipes, recipeId)
	printRecipes(craftingConstructionRecipes)
	if recipe == nil then
		player:sendCancelMessage(("Recipe %s[%d] not found"):format(split[1], grade))
		return false
	end

	local blueprintItem = craft(player, recipe, SKILL_CRAFTING, CONSTRUCTION_BLUEPRINT_ID)
	if blueprintItem then
		player:addItemEx(blueprintItem)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	else
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
	end
	return false
end
