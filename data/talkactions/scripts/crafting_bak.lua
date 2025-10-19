local craftingRecipes_bak = {
	-- axe
	[ITEM_AXE] = {
		[1] = { levelRequired = 1, staminaRequired = 50, quality = 90, durability = 50, materials = {
			[ITEM_WOODEN_STICK]	= {count = 5},
			[ITEM_SMALL_STONE] 	= {count = 3},
			},
		},
		[2] = { levelRequired = 3, staminaRequired = 150, quality = 110, durability = 90, materials = {
			[ITEM_WOODEN_STICK] = {count = 10},
			[ITEM_SMALL_STONE] 	= {count = 6},
			},
		},
		[3] = { levelRequired = 5, staminaRequired = 150, quality = 110, durability = 90, materials = {
			[ITEM_WOODEN_STICK] = {count = 10},
			[ITEM_SMALL_STONE] 	= {count = 6},
			},
		},
	},
	[ITEM_PICK] = {
		[1] = { levelRequired = 2, staminaRequired = 50, quality = 90, durability = 50, materials = {
			[ITEM_WOODEN_STICK]	= {count = 5},
			[ITEM_SMALL_STONE] 	= {count = 6},
			},
		},
		[2] = { levelRequired = 4, staminaRequired = 150, quality = 110, durability = 90, materials = {
			[ITEM_WOODEN_STICK] = {count = 10},
			[ITEM_SMALL_STONE] 	= {count = 12},
			},
		},
	}
}

function onSay(player, words, param)
	local split = param:splitTrimmed(" ")

	local itemType = ItemType(split[1])
	if itemType:getId() == 0 then
		itemType = ItemType(tonumber(split[1]))
		if not tonumber(split[1]) or itemType:getId() == 0 then
			player:sendCancelMessage("There is no item with that id or name.")
			return false
		end
	end
	local itemId = itemType:getId()

	item = craftingRecipes[itemId]
	if item == nil then
		player:sendCancelMessage("There is no such recipe.")
		return false
	end

	local level = tonumber(split[2])
	local recipe = item[level]
	if recipe == nil then
		player:sendCancelMessage("There is no such level of this recipe.")
		return false
	end

	local levelRequired = item[level].levelRequired
	if player:getSkillLevel(SKILL_CRAFTING) < levelRequired then
		player:sendCancelMessage("You have too low skill level craft that recipe.")
		return false
	end	

	for materialId, materialInfo in pairs(recipe.materials) do
        if not player:hasItem(materialId, materialInfo.count, -1, true) then
			player:sendCancelMessage(("You dont have required materials (%d %s)"):format(materialInfo.count, ItemType(materialId):getName()))
			return false
		end
    end

	local sumWeight = 0
	for materialId, materialInfo in pairs(recipe.materials) do
        player:removeItem(materialId, materialInfo.count, -1, true)
		sumWeight = sumWeight + ItemType(materialId):getWeight() * materialInfo.count
	end

	local result = Game.createItem(26387)
	if result then
		result:setCustomAttribute("bp", itemId)
		result:setCustomAttribute("level", levelRequired)
		result:setCustomAttribute("work", 0)
		result:setCustomAttribute("work_max", recipe.staminaRequired)
		result:setCustomAttribute("bp_quality", gaussianRandom20p(recipe.quality))
		result:setCustomAttribute("bp_durability", gaussianRandom20p(recipe.durability))
		-- result:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, ("Work progress: %d/%d."):format(0, recipe.staminaRequired))

		local targetItemWeight = ItemType(itemId):getWeight()
		local weightChangePerWork = (targetItemWeight - sumWeight) / recipe.staminaRequired
		result:setWeight(sumWeight)
		result:setCustomAttribute("work_weight_change", weightChangePerWork)
		player:addItemEx(result)

		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	else
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
	end
	return false
end
