CRAFTING_CONSTRUCTION = CRAFTING_CONSTRUCTION or {recipes = {}}

CONSTRUCTION_BLUEPRINT_ID = 26402

WOODEN_WALL_RECIPE = {
	levelRequired = 1, staminaRequired = 200, quality = 90, durability = 1000, materials = {
        [ITEM_WOODEN_STICK]     = {count = 5},
        [ITEM_PIECE_OF_WOOD]	= {count = 20},
    }, category = 'buildings', subcategory = 'wooden',
}

WOODEN_WALL_LOCKING_DOOR = {
    levelRequired = 2, staminaRequired = 300, quality = 90, durability = 500, materials = {
        [ITEM_WOODEN_STICK]     = {count = 15},
        [ITEM_PIECE_OF_WOOD]	= {count = 30},
    }, category = 'buildings', subcategory = 'wooden',
}

local function recipe(template, recipeId, itemId)
    local newrecipe = deepCopy(template)
    newrecipe.recipeId = recipeId
    newrecipe.itemId = itemId
	return newrecipe
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
        }, category = 'camp', subcategory = 'fire', simple = true,
    },
	{ recipeId = "wooden chest", itemId = 8587, levelRequired = 1, staminaRequired = 50, quality = 90, maxSize = 5, durability = 500, materials = {
		[ITEM_PIECE_OF_WOOD]	= {count = 20},
  	}, category = 'camp', subcategory = 'containers',
},
}

function craft_construction(player, recipeId, grade, count)
    local recipeTemplate = findRecipe(craftingConstructionRecipes, recipeId)
    if not recipeTemplate then
        return false
    end

    recipe = deepCopy(recipeTemplate)
    recipe.levelRequired = recipe.levelRequired + (grade - 1) * 2
    recipe.staminaRequired = recipe.staminaRequired * (1 + 0.5 * (grade - 1))
    recipe.quality = 100 * (1 + 0.2 * (grade - 1))
    if recipe.maxSize then 		recipe.maxSize 		= recipe.maxSize * (1 + 0.5 * (grade - 1)) end
    if recipe.durability then 	recipe.durability 	= recipe.durability * (1 + 0.5 * (grade - 1)) end
    for materialId, materialInfo in pairs(recipe.materials) do
        materialInfo.count = materialInfo.count * (1 + 0.5 * (grade - 1))
    end

	local blueprintItem = craft(player, recipe, SKILL_CRAFTING, CONSTRUCTION_BLUEPRINT_ID)
	if blueprintItem then
		player:addItemEx(blueprintItem)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	else
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
	end
	return true
end

CRAFTING_CONSTRUCTION.recipes = craftingConstructionRecipes