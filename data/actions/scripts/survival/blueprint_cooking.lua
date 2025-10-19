COOKING_BLUEPRINT_READY_ID = 26406 -- TODO add cooking blueprint

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local workDone = item:getCustomAttribute("work")
    local workRequired = item:getCustomAttribute("work_max")
    local workOnUse = workRequired - workDone
    if workOnUse > 10 then
        workOnUse = 10
    end
    local workAfterUse = workOnUse + workDone

    if item:getCustomAttribute("level") > player:getSkillLevel(SKILL_COOKING) + 5 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You have too low skill level to work on that recipe.")
        return true
    end

    local weightChange = workOnUse * item:getCustomAttribute("work_weight_change")
    if weightChange > 0 and player:getFreeCapacity() < weightChange then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, ("Not enough capacity to work on the recipe (%d required for next step)"):format(weightChange))
        return true
    end

    if player:useStamina(SKILL_COOKING) then
        player:addSkillTries(SKILL_COOKING, workOnUse)
        if workAfterUse == workRequired then
            item:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
            item:transform(COOKING_BLUEPRINT_READY_ID)
            item:removeCustomAttribute("work")
            item:removeCustomAttribute("work_max")
        else
            item:setCustomAttribute("work", workAfterUse)
            player:sendTextMessage(MESSAGE_STATUS_SMALL, ("Recipe work: %d/%d"):format(workAfterUse, workRequired))
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
