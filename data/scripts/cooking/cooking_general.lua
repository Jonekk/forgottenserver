CRAFTING_GENERAL = CRAFTING_GENERAL or {recipes = {}}

CRAFTING_BLUEPRINT = 26387

local craftingRecipes = {
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
	{ recipeId = 'basket', itemId = 1989, levelRequired = 2, staminaRequired = 50, maxSize = 20, materials = {
        [26412]		= {count = 30},
		[ITEM_PIECE_OF_WOOD]	= {count = 2},
        }, category = 'general', subcategory = 'tools',
    },
	{ recipeId = 'pot', itemId = 2562, levelRequired = 2, staminaRequired = 50, materials = {
        [ITEM_IRON_ORE]		= {count = 20},
        }, category = 'general', subcategory = 'tools', simple = true,
    },
	{ recipeId = 'torch', itemId = 2050, levelRequired = 1, staminaRequired = 15, duration = 300 * 1000, materials = {
        [ITEM_WOODEN_STICK]		= {count = 2},
		[26412]	        		= {count = 3}, -- grass fiber
        }, category = 'general', subcategory = 'tools',
    },
	{ recipeId = 'rope', itemId = 2120, levelRequired = 1, staminaRequired = 15, duration = 300 * 1000, materials = {
        [26412]		= {count = 10},
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
        [26412]	= {count = 3}, -- grass fiber
        }, category = 'general', subcategory = 'materials', simple = true, multicraft = true,
    },
    { recipeId = 'fertilizer', itemId = 26411, levelRequired = 1, staminaRequired = 20, materials = {
        [3976]	        = {count = 10}, -- worm
		[26412]	        = {count = 10}, -- grass fiber
        }, category = 'general', subcategory = 'materials', simple = true, multicraft = true,
    },
	---------------------------- WEAPONS ----------------------------
	{ recipeId = 'spear', itemId = 2389, levelRequired = 1, staminaRequired = 50, attack = 20, materials = {
		[ITEM_WOODEN_STICK]	= {count = 8},
        }, category = 'general', subcategory = 'distance weapons',
    },
	{ recipeId = 'simple_bow', itemId = 2456, levelRequired = 1, staminaRequired = 70, attack = 1, materials = {
		[ITEM_WOODEN_STICK]	= {count = 10},
		[26413]	        	= {count = 10}, -- string
        }, category = 'general', subcategory = 'distance weapons',
    },
	{ recipeId = 'simple_arrow', itemId = 23839, levelRequired = 1, staminaRequired = 30, attack = 15, count = 4, materials = {
		[ITEM_WOODEN_STICK]	= {count = 10},
		}, category = 'general', subcategory = 'distance weapons',
	},
}

function craft_general(player, recipeId, grade, count)
    local recipeTemplate = findRecipe(craftingRecipes, recipeId)
	if not recipeTemplate then
        return false
    end
    local recipe = nil
    if recipeTemplate.simple then
        recipe = deepCopy(recipeTemplate)
        recipe.staminaRequired = recipe.staminaRequired * count
		recipe.count = count
		for materialId, materialInfo in pairs(recipe.materials) do
			materialInfo.count = materialInfo.count * count
		end
    else
		local playerCrafting = player:getSkillLevel(SKILL_CRAFTING)
        recipe = deepCopy(recipeTemplate)
		recipe.levelRequired = recipe.levelRequired + (grade - 1) * 2
		recipe.staminaRequired = recipe.staminaRequired * (1 + 0.5 * (grade - 1))
		for materialId, materialInfo in pairs(recipe.materials) do
			materialInfo.count = materialInfo.count * (1 + 0.5 * (grade - 1))
		end
		recipe.quality = randomBetween(10 + playerCrafting * 2, 100 + playerCrafting * 1.5) * (1 + 0.2 * (grade - 1))
		-- randomized attributes based on quality
		if recipe.maxSize then 		recipe.maxSize 		= recipe.maxSize * recipe.quality / 100 end
		if recipe.durability then 	recipe.durability 	= recipe.durability * recipe.quality / 100 end
		if recipe.duration then 	recipe.duration 	= recipe.duration * recipe.quality / 100 end
		if recipe.attack then 		recipe.attack 		= recipe.attack * (1 + (recipe.quality - 100) / (100 * 2)) end
    end
	local blueprintItem = craft(player, recipe, SKILL_CRAFTING, CRAFTING_BLUEPRINT)
	if blueprintItem then
		player:addItemEx(blueprintItem)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	else
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
		
	end
	return true
end


CRAFTING_GENERAL.recipes = craftingRecipes