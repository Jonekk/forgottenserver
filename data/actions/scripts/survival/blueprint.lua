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
            local count = item:getCustomAttribute("bp_count")
            local bp_quality = item:getCustomAttribute("bp_quality")
            local bp_duration = item:getCustomAttribute("bp_duration")
            local bp_durability = item:getCustomAttribute("bp_durability")
            local bp_maxsize = item:getCustomAttribute("bp_maxsize")
            local bp_attack = item:getCustomAttribute("bp_attack")
            -- local productItem = player:addItem(productId, count, true, 0)

            -- force empty containers
            if ItemType(productId):isFluidContainer() then
                count = 0
            end

            item:transform(productId, count)
            item:resetWeight()
            item:clearCustomAttributes()
            if bp_quality then item:setQuality(round(bp_quality)) end
            print("Duration before: ", item:getDuration())
            if bp_duration then item:setDuration(bp_duration) end
            print("Duration after: ", item:getDuration())
            if bp_durability then item:setMaxDurability(round(bp_durability)) end
            if bp_durability then item:setDurability(round(bp_durability)) end
            if bp_maxsize then 
                local container = Container(item.uid)
                container:setCapacity(bp_maxsize)
            end
            if bp_attack then item:setAttribute(ITEM_ATTRIBUTE_ATTACK, bp_attack) end
            
            --item:remove(1)
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
