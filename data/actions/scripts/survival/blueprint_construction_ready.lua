function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if item:getCustomAttribute("level") > player:getSkillLevel(SKILL_CRAFTING) + 5 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You have too low skill level to work on that blueprint.")
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

    if bp_quality then productItem:setQuality(round(bp_quality)) end
    if bp_durability then 
        productItem:setMaxDurability(round(bp_durability))
        productItem:setDurability(round(bp_durability))
    end

    tile:constructItemEx(productItem)
    item:remove(1)
    toPosition:sendMagicEffect(CONST_ME_MAGIC_GREEN)
	return true
end
