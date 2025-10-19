craftingRecipes = {
	-- axe
	[ITEM_STONE_AXE] = {
		levelRequired = 1, staminaRequired = 50, durability = 50, materials = {
			[ITEM_WOODEN_STICK]	= {count = 5},
			[ITEM_SMALL_STONE] 	= {count = 3},
		},
		category = 'general', subcategory = 'tools',
	},
	[ITEM_STONE_PICK] = {
		levelRequired = 2, staminaRequired = 50, durability = 50, materials = {
			[ITEM_WOODEN_STICK]	= {count = 5},
			[ITEM_SMALL_STONE] 	= {count = 6},
		},
		category = 'general', subcategory = 'tools',
	},
	[26416] = {
		levelRequired = 3, staminaRequired = 70, durability = 50, materials = {
			[ITEM_WOODEN_STICK]	= {count = 5},
			[ITEM_SMALL_STONE] 	= {count = 20},
		},
		category = 'hunting', subcategory = 'tools',
	},
	[26421] = { -- small trap
		levelRequired = 5, staminaRequired = 70, durability = 10, materials = {
			[ITEM_WOODEN_STICK]	= {count = 5},
			[ITEM_IRON_ORE] 	= {count = 20},
			[ITEM_TIN_ORE] 		= {count = 5},
		},
		category = 'hunting', subcategory = 'traps',
	},
	[26423] = { -- medium trap
		levelRequired = 10, staminaRequired = 110, durability = 10, materials = {
			[ITEM_WOODEN_STICK]	= {count = 5},
			[ITEM_IRON_ORE] 	= {count = 30},
			[ITEM_TIN_ORE] 		= {count = 10},
		},
		category = 'hunting', subcategory = 'traps',
	},
	[26425] = { -- big trap
		levelRequired = 15, staminaRequired = 160, durability = 10, materials = {
			[ITEM_WOODEN_STICK]	= {count = 5},
			[ITEM_IRON_ORE] 	= {count = 40},
			[ITEM_TIN_ORE] 		= {count = 15},
		},
		category = 'hunting', subcategory = 'traps',
	},
	[2148] = { -- gold coin
	levelRequired = 15, staminaRequired = 160, durability = 10, materials = {
		[ITEM_WOODEN_STICK]	= {count = 5},
		[ITEM_IRON_ORE] 	= {count = 40},
		[ITEM_TIN_ORE] 		= {count = 15},
		},
		category = 'general', subcategory = 'test1',
	},
	[2149] = { -- ??
	levelRequired = 15, staminaRequired = 160, durability = 10, materials = {
		[ITEM_WOODEN_STICK]	= {count = 5},
		[ITEM_IRON_ORE] 	= {count = 40},
		[ITEM_TIN_ORE] 		= {count = 15},
		},
		category = 'general', subcategory = 'test2',
	},
}

local craftingSimpleRecipes = {
	{ itemId = 26413, levelRequired = 1, staminaRequired = 15, materials = {
        [26412]	= {count = 4}, -- grass fiber
        }
    },
    { itemId = 26411, levelRequired = 1, staminaRequired = 20, materials = { -- fertilizer
        [3976]	        = {count = 10}, -- worm
		[26412]	        = {count = 10}, -- grass fiber
        }
    },
	{ itemId = 2005, levelRequired = 2, staminaRequired = 50, materials = {
        [ITEM_WOODEN_STICK]		= {count = 20},
		[ITEM_PIECE_OF_WOOD]	= {count = 20},
        }
    },
}

function findSimpleRecipe(recipesList, itemId)
	for _, recipe in ipairs(recipesList) do
		if recipe.itemId == itemId then
			return recipe
		end
	end
	return nil
end

function onSay(player, words, param)
	printRecipes(craftingRecipes)
	local split = param:splitTrimmed(",")
	local itemId = getItemId(split[1])
	local level = tonumber(split[2])
	local recipe = nil
	if craftingRecipes[itemId] then
		recipe = deepCopy(craftingRecipes[itemId])
		recipe.levelRequired = recipe.levelRequired + (level - 1) * 5
		recipe.staminaRequired = recipe.staminaRequired * level
		recipe.quality = 100 * (1 + 0.2 * level)
		recipe.durability = recipe.durability * (1 + 0.5 * level)
		for materialId, materialInfo in pairs(recipe.materials) do
			materialInfo.count = materialInfo.count * level
		end
	else
		recipe = findSimpleRecipe(craftingSimpleRecipes, itemId)
	end

	if recipe == nil then
		player:sendCancelMessage(("Recipe %s[%d] not found"):format(split[1], level))
		return false
	end

	local blueprintItem = craft(player, itemId, recipe, SKILL_CRAFTING, 26387)
	if blueprintItem then
		player:addItemEx(blueprintItem)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	else
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
	end
	return false
end
