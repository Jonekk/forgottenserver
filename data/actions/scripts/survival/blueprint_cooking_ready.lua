

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if item:getCustomAttribute("level") > player:getSkillLevel(SKILL_COOKING) + 5 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You have too low skill level to work on that blueprint.")
        return false
    end

    local productId = item:getCustomAttribute("bp")

    if not fireSourcesLit[target:getId()] then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You need to cook that over fire.")
        return false
    end

    local productItem = player:addItem(productId)
    productItem:setCustomAttribute("quality", round(item:getCustomAttribute("bp_quality")))
    item:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
    item:remove(1)
	return true
end
