local config = {
    [2785] =    {staminaRequired = 5, productItem = 2677, countBase = 3, countPerSkill = 0.2, chanceGet = 100, chanceDestroy = 100, destroyTime=10, destroyTo = 2786, witheredId = 26414 },
    [26409] =   {staminaRequired = 5, productItem = 2680, countBase = 2, countPerSkill = 0.2, chanceGet = 100, chanceDestroy = 100, destroyTime=10, destroyTo = 26408, witheredId = 26415 },
}

local farmingCareItems = {
    [26414] = { changeTo = 2786 },
    [2786] = {},
    [26415] = { changeTo = 26408 },
    [26408] = {},
}

function isFarmingCareItem(item)
    if farmingCareItems[item:getId()] then
        return true
    else
        return false
    end
end

function waterFarmingItem(player, wateringItem, target)
    local itemCfg = farmingCareItems[target:getId()]
    if not itemCfg then
        return false
    end

    local watering = target:getCustomAttribute("watering")
    local wateringMax = target:getCustomAttribute("watering_max")
    if watering and wateringMax and watering < wateringMax then
        if player:useStamina(5) then
            player:addSkillTries(SKILL_FARMING, 5)

            local wateringChange = math.min(5, wateringMax - watering)
            target:setCustomAttribute("watering", watering + wateringChange)
            if itemCfg.changeTo and isFarmingItemWatered(target) and isFarmingItemFertilized(target) then
                target:transform(itemCfg.changeTo)
                target:decay()
            end
            target:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
            return true
        end
    end
    return false
end

function fertilizeFarmingItem(player, fertilizingItem, target)
    local itemCfg = farmingCareItems[target:getId()]
    if not itemCfg then
        return false
    end

    local fertility = target:getCustomAttribute("fertility")
    local fertilityMax = target:getCustomAttribute("fertility_max")
    if fertility and fertilityMax and fertility < fertilityMax then
        if player:useStamina(5) then
            player:addSkillTries(SKILL_FARMING, 5)

            local fertilityChange = math.min(5, fertilityMax - fertility)
            target:setCustomAttribute("fertility", fertility + fertilityChange)
            if itemCfg.changeTo and isFarmingItemWatered(target) and isFarmingItemFertilized(target) then
                target:transform(itemCfg.changeTo)
                target:decay()
            end
            target:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
            fertilizingItem:remove(1)
            return true
        end
    end
    return false
end

function isFarmingItemWatered(item)
    local watering = item:getCustomAttribute("watering")
    if watering and watering <= 0 then
        return false
    end
    return true
end

function isFarmingItemFertilized(item)
    local fertility = item:getCustomAttribute("fertility")
    if fertility and fertility <= 0 then
        return false
    end
    return true
end

function decayFarmingItemOnUse(player, item, witherTo)
    local playerFarmingLevel = player:getSkillLevel(SKILL_FARMING)

    local watering = item:getCustomAttribute("watering")
    local changeMade = false
    if watering and watering > 0 then
        local dryChance = math.max(10, 20 - (playerFarmingLevel/2))
        if dryChance > math.random(100) then
            item:setCustomAttribute("watering", watering - 50)
            changeMade = true
        end
    end

    local fertility = item:getCustomAttribute("fertility")
    if fertility and fertility > 0 then
        local decayChance = math.max(10, 20 - (playerFarmingLevel/2))
        if decayChance > math.random(100) then
            item:setCustomAttribute("fertility", fertility - 30)
            changeMade = true
        end
    end

    if not isFarmingItemWatered(item) or not isFarmingItemFertilized(item) then
        item:transform(witherTo)
        changeMade = true
    end

    if changeMade then
        item:updateConstructionItem()
    end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local cfg = config[item:getId()]

    if cfg.destroyTo == item:getId() then
        restoreTime = item:getCustomAttribute("restoreTime")
        if restoreTime and os:mtime() < restoreTime then
            player:sendTextMessage(MESSAGE_STATUS_SMALL, ("Target %s is empty"):format(item:getName()))
            return true
        end
    end

    if player:useStamina(cfg.staminaRequired) then
        player:addSkillTries(SKILL_FARMING, cfg.staminaRequired)
        local itemQuality = item:getQuality()
        if not itemQuality then itemQuality = 100 end

        local chanceGet = adjustChanceByQuality(cfg.chanceGet, itemQuality)
        local randomGet = math.random(100)
        if chanceGet >= randomGet then
            count = math.max(1, round(gaussianRandom50p(cfg.countBase * (itemQuality/100) + cfg.countPerSkill * player:getSkillLevel(SKILL_FARMING))))
            player:addItem(cfg.productItem, count)
        end
        local randomDestroy = math.random(100)
        if cfg.chanceDestroy >= randomDestroy then
            if cfg.destroyTo == item:getId() then
                item:setCustomAttribute("restoreTime", os:mtime() + gaussianRandom50p(cfg.destroyTime))
            else
                item:transform(cfg.destroyTo)
                item:setDuration(gaussianRandom50p(cfg.destroyTime * 1000))
                item:decay()
            end
        end
        decayFarmingItemOnUse(player, item, cfg.witheredId)
    else
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        player:sendTextMessage(MESSAGE_STATUS_SMALL, ("Not enough stamina (%d required)"):format(cfg.staminaRequired))
    end
	return true
end
