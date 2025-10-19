COOKING_BLUEPRINT_ID = 26405 -- TODO add cooking blueprint

SPICES_ALL = {
    ITEM_PILE_OF_SALT
} 

SPICES_BONUS = {
    [ITEM_PILE_OF_SALT] = 20
}

local craftingCookingRecipes = {
	[2666] = { levelRequired = 1, staminaRequired = 5, quality = 190, materials = { -- meat
        [26404]	= {count = 1},
        },
    },
	[2671] = { levelRequired = 2, staminaRequired = 5, quality = 90, materials = { -- ham
        [26404]	= {count = 1}, -- todo zmienić na raw ham
        },
    },
}

function getUsedSpices(selectedSpices, allowedSpices)
    local common_items = {}
    for _, v in ipairs(selectedSpices) do if table.contains(allowedSpices, v) then table.insert(common_items, v) end end
    return common_items
end

function getQualityBonusFromSpices(usedSpices, allowedSpices)
    local totalBonus = 0
    for _, spice in ipairs(usedSpices) do
        bonus = SPICES_BONUS[spice]
        if bonus then
            totalBonus  = totalBonus + bonus
        end
    end
end

function onSay(player, words, param)
	local split = param:splitTrimmed(",")
	local itemId = getItemId(split[1])
	local level = tonumber(split[2])
	local recipe = craftingCookingRecipes[itemId]
    local spicesParam = split[3]
    local spices = {}
    if spicesParam then
        spices = spicesParam:splitTrimmed("-")
    end

	if recipe == nil then
		player:sendCancelMessage(("Recipe %s[%d] not found"):format(split[1], level))
		return false
	end
    local allowedSpices = SPICES_ALL
    if recipe.allowedSpices then
        allowedSpices = allowedSpices
    end

    local usedSpices = getUsedSpices(spices, allowedSpices)

    local localRecipe = deepCopy(recipe)
    for _, spice in ipairs(usedSpices) do
        localRecipe.materials[spice] = {count = 1}
    end
    local spicesBonusQuality = getQualityBonusFromSpices(usedSpices)
    if spicesBonusQuality then
        localRecipe.quality = localRecipe.quality + getQualityBonusFromSpices(usedSpices)
    end

	local blueprintItem = craft(player, itemId, recipe, SKILL_COOKING, COOKING_BLUEPRINT_ID)
	if blueprintItem then
		player:addItemEx(blueprintItem)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	else
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
	end
	return false
end
