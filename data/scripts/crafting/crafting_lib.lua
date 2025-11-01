function getItemId(itemIdOrName)
    local itemType = ItemType(itemIdOrName)
	if not itemType or itemType:getId() == 0 then
		itemType = ItemType(tonumber(itemIdOrName))
		if itemType and itemType:getId() > 0 then
			return itemType:getId()
		end
	end
    if itemType then
        return itemType:getId()
    else
        return nil
    end
end

function craft(player, recipe, skillId, blueprintId)

	if recipe == nil then
		player:sendCancelMessage("There is no such level of this recipe.")
		return nil
	end

	local levelRequired = recipe.levelRequired
	if player:getSkillLevel(skillId) < levelRequired then
		player:sendCancelMessage("You have too low skill level craft that recipe.")
		return nil
	end	

	for materialId, materialInfo in pairs(recipe.materials) do
        if not player:hasItem(materialId, materialInfo.count, -1, true) then
			player:sendCancelMessage(("You dont have required materials (%d %s)"):format(materialInfo.count, ItemType(materialId):getName()))
			return nil
		end
    end

	local sumWeight = 0
	for materialId, materialInfo in pairs(recipe.materials) do
        player:removeItem(materialId, materialInfo.count, -1, true)
		sumWeight = sumWeight + ItemType(materialId):getWeight() * materialInfo.count
	end

	local result = Game.createItem(blueprintId)
	if result then
		result:setCustomAttribute("bp", recipe.itemId)
		result:setCustomAttribute("level", levelRequired)
		result:setCustomAttribute("work", 0)
		result:setCustomAttribute("work_max", recipe.staminaRequired)
		result:setCustomAttribute("bp_count", recipe.count)
		if recipe.quality then result:setCustomAttribute("bp_quality", gaussianRandom20p(recipe.quality)) end
		if recipe.durability then result:setCustomAttribute("bp_durability", gaussianRandom20p(recipe.durability)) end
		if recipe.watering then result:setCustomAttribute("bp_watering", gaussianRandom20p(recipe.watering)) end
		if recipe.fertility then result:setCustomAttribute("bp_fertility", gaussianRandom20p(recipe.fertility)) end

		local targetItemWeight = ItemType(recipe.itemId):getWeight()
		local weightChangePerWork = (targetItemWeight - sumWeight) / recipe.staminaRequired
		result:setWeight(sumWeight)
		result:setCustomAttribute("work_weight_change", weightChangePerWork)
        return result
	else
		return nil
	end
end

function serializeRecipe(recipe)
	local mats = {}
	for itemId, data in pairs(recipe.materials or {}) do
		table.insert(mats, itemId .. "x" .. data.count)
	end
	simple = recipe.simple and 1 or 0
	multicraft = recipe.multicraft and 1 or 0
	local line = string.format(
		"%s;%d;%d;%d;%d;%s;%s;%s;%d;%d",
		recipe.recipeId,
		recipe.itemId,
		recipe.levelRequired or 0,
		recipe.staminaRequired or 0,
		recipe.durability or 0,
		table.concat(mats, ","),
		recipe.category or "",
		recipe.subcategory or "",
		simple,
		multicraft
	)
	return line
end

function serializeRecipes(recipes)
	local lines = {}
	for resultId, recipe in pairs(recipes) do
	  line = serializeRecipe(resultId, recipe)
	  table.insert(lines, line)
	end
	return table.concat(lines, "\n")
  end

local function toLuaPretty(tbl, indent)
	indent = indent or 0
	local pad = string.rep("  ", indent)
	local padInner = string.rep("  ", indent + 1)
	local parts = {"{\n"}
  
	-- sort keys for deterministic output (optional)
	local keys = {}
	for k in pairs(tbl) do table.insert(keys, k) end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  
	for _, k in ipairs(keys) do
	  local v = tbl[k]
	  local key
	  if type(k) == "string" and k:match("^%a[%w_]*$") then
		key = k
	  else
		key = "[" .. tostring(k) .. "]"
	  end
  
	  local value
	  if type(v) == "table" then
		value = toLuaPretty(v, indent + 1)
	  elseif type(v) == "string" then
		value = string.format("%q", v)
	  else
		value = tostring(v)
	  end
  
	  table.insert(parts, string.format("%s%s = %s,\n", padInner, key, value))
	end
  
	table.insert(parts, pad .. "}")
	return table.concat(parts)
end

function printRecipes(tbl)
  print(toLuaPretty(tbl))
end
  