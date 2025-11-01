CRAFTING_GENERAL = CRAFTING_GENERAL or {recipes = {}}

local craftingRecipes = {
	-- axe
	{   recipeId = 'stone_axe', itemId = ITEM_STONE_AXE, levelRequired = 1, staminaRequired = 50, durability = 50, materials = {
			[ITEM_WOODEN_STICK]	= {count = 5},
			[ITEM_SMALL_STONE] 	= {count = 3},
		},
		category = 'general', subcategory = 'tools',
	},
	{   recipeId = 'stone_pick', itemId = ITEM_STONE_PICK, levelRequired = 2, staminaRequired = 50, durability = 50, materials = {
			[ITEM_WOODEN_STICK]	= {count = 5},
			[ITEM_SMALL_STONE] 	= {count = 6},
		},
		category = 'general', subcategory = 'tools',
	},
	{ recipeId = 'bucket', itemId = 2005, levelRequired = 2, staminaRequired = 50, materials = {
        [ITEM_WOODEN_STICK]		= {count = 20},
		[ITEM_PIECE_OF_WOOD]	= {count = 20},
        }, category = 'general', subcategory = 'tools', simple = true,
    },
	{   recipeId = 'stone_hunting_knife', itemId = 26416, levelRequired = 3, staminaRequired = 70, durability = 50, materials = {
			[ITEM_WOODEN_STICK]	= {count = 5},
			[ITEM_SMALL_STONE] 	= {count = 20},
		},
		category = 'hunting', subcategory = 'tools',
	},
	{   recipeId = 'small_trap', itemId = 26421, levelRequired = 5, staminaRequired = 70, durability = 10, materials = {
			[ITEM_WOODEN_STICK]	= {count = 5},
			[ITEM_IRON_ORE] 	= {count = 20},
			[ITEM_TIN_ORE] 		= {count = 5},
		},
		category = 'hunting', subcategory = 'traps',
	},
	{   recipeId = 'medium_trap', itemId = 26423, levelRequired = 10, staminaRequired = 110, durability = 10, materials = {
			[ITEM_WOODEN_STICK]	= {count = 5},
			[ITEM_IRON_ORE] 	= {count = 30},
			[ITEM_TIN_ORE] 		= {count = 10},
		},
		category = 'hunting', subcategory = 'traps',
	},
	{   recipeId = 'big_trap', itemId = 26425, levelRequired = 15, staminaRequired = 160, durability = 10, materials = {
			[ITEM_WOODEN_STICK]	= {count = 5},
			[ITEM_IRON_ORE] 	= {count = 40},
			[ITEM_TIN_ORE] 		= {count = 15},
		},
		category = 'hunting', subcategory = 'traps',
	},
    { recipeId = 'string', itemId = 26413, levelRequired = 1, staminaRequired = 15, materials = {
        [26412]	= {count = 4}, -- grass fiber
        }, category = 'general', subcategory = 'materials', simple = true, multicraft = true,
    },
    { recipeId = 'fertilizer', itemId = 26411, levelRequired = 1, staminaRequired = 20, materials = { -- fertilizer
        [3976]	        = {count = 10}, -- worm
		[26412]	        = {count = 10}, -- grass fiber
        }, category = 'general', subcategory = 'materials', simple = true, multicraft = true,
    }, 
}

function findRecipe(recipesList, recipeId)
	for _, recipe in ipairs(recipesList) do
		if recipe.recipeId == recipeId then
			return recipe
		end
	end
	return nil
end

function craft_general(player, recipeId, grade, count)
    local recipeTemplate = findRecipe(craftingRecipes, recipeId)
    local recipe = nil
    if recipeTemplate.simple then
		print("craft simple")
        recipe = deepCopy(recipeTemplate)
        recipe.staminaRequired = recipe.staminaRequired * count
		recipe.count = count
		for materialId, materialInfo in pairs(recipe.materials) do
			materialInfo.count = materialInfo.count * count
		end
    else
		print("craft not simple")
        recipe = deepCopy(recipeTemplate)
		recipe.levelRequired = recipe.levelRequired + (grade - 1) * 2
		recipe.staminaRequired = recipe.staminaRequired * (1 + 0.5 * grade)
		recipe.quality = 100 * (1 + 0.2 * grade)
		recipe.durability = recipe.durability * (1 + 0.5 * grade)
		for materialId, materialInfo in pairs(recipe.materials) do
			materialInfo.count = materialInfo.count * (1 + 0.5 * grade)
		end
    end
	local blueprintItem = craft(player, recipe, SKILL_CRAFTING, 26387)
	if blueprintItem then
		player:addItemEx(blueprintItem)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		return true
	else
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		
	end
	return false
end


CRAFTING_GENERAL.recipes = craftingRecipes