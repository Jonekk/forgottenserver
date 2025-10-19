function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local workDone = item:getCustomAttribute("work")
    local workRequired = item:getCustomAttribute("work_max")
    local workOnUse = workRequired - workDone
    if workOnUse > 10 then
        workOnUse = 10
    end
    local workAfterUse = workOnUse + workDone

    if item:getCustomAttribute("level") > player:getSkillLevel(SKILL_CRAFTING) + 5 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You have too low skill level to work on that blueprint.")
        return true
    end

    local weightChange = workOnUse * item:getCustomAttribute("work_weight_change")
    if weightChange > 0 and player:getFreeCapacity() < weightChange then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, ("Not enough capacity to work on the blueprint (%d required for next step)"):format(weightChange))
        return true
    end

    if player:useStamina(workOnUse) then
        player:addSkillTries(SKILL_CRAFTING, workOnUse)
        if workAfterUse == workRequired then
            local productId = item:getCustomAttribute("bp")
            local productItem = player:addItem(productId, 1, true, 0)
            local bp_quality = item:getCustomAttribute("bp_quality")
            local bp_durability = item:getCustomAttribute("bp_durability")
            local bp_durability = item:getCustomAttribute("bp_durability")
            if bp_quality then productItem:setCustomAttribute("quality", round(bp_quality)) end
            if bp_durability then productItem:setCustomAttribute("durability", round(bp_durability)) end
            if bp_durability then productItem:setCustomAttribute("durability_max", round(bp_durability)) end
            item:remove(1)
            item:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        else
            item:setCustomAttribute("work", workAfterUse)
            player:sendTextMessage(MESSAGE_STATUS_SMALL, ("Blueprint work: %d/%d"):format(workAfterUse, workRequired))
            item:setWeight(item:getAttribute(ITEM_ATTRIBUTE_WEIGHT) + weightChange)
            player:updateInventoryWeight()
            item:getPosition():sendMagicEffect(CONST_ME_HITAREA)
        end
    else
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        player:sendTextMessage(MESSAGE_STATUS_SMALL, ("Not enough stamina (%d required)"):format(workOnUse))
    end
	return true
end
