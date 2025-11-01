function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if item:getCustomAttribute("level") > player:getSkillLevel(SKILL_FARMING) + 5 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You have too low skill level to work on that.")
        return true
    end

    local productId = item:getCustomAttribute("bp")
    local tile = Tile(toPosition)
	if not tile then
		return false
	end
    if not tile:isConstructable() then
        return false
    end
    local productItem = Game.createItem(productId)

    local bp_quality = item:getCustomAttribute("bp_quality")
    local bp_durability = item:getCustomAttribute("bp_durability")
    local bp_watering = item:getCustomAttribute("bp_watering")
    local bp_fertility = item:getCustomAttribute("bp_fertility")

    if bp_quality then productItem:setQuality(round(bp_quality)) end
    if bp_durability then 
        productItem:setCustomAttribute("durability", round(bp_durability))
        productItem:setCustomAttribute("durability_max", round(bp_durability))
    end
    if bp_watering then
        productItem:setCustomAttribute("watering", round(bp_watering) / 2)
        productItem:setCustomAttribute("watering_max", round(bp_watering))
    end
    if bp_fertility then
        productItem:setCustomAttribute("fertility", round(bp_fertility) / 2)
        productItem:setCustomAttribute("fertility_max", round(bp_fertility))
    end

    tile:constructItemEx(productItem)
    --item:remove(1)
    toPosition:sendMagicEffect(CONST_ME_MAGIC_GREEN)
	return true
end
