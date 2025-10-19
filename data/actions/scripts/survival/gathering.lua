local config = {
	[2784] = {staminaRequired = 10, productItem = 26384, chanceGet = 50, chanceDestroy = 10, destroyTime=10},
	[2770] = {staminaRequired = 10, productItem = 26384, chanceGet = 50, chanceDestroy = 10, destroyTime=10},
    [3985] = {staminaRequired = 10, productItem = 26412, chanceGet = 50, chanceDestroy = 10, destroyTime=10},
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local cfg = config[item:getId()]
    if not cfg then
        return false
    end

    destroyedTime = item:getCustomAttribute("destroyedTime")
    if destroyedTime and os:mtime() - destroyedTime < cfg.destroyTime * 1000 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, ("Target %s is empty"):format(item:getName()))
        return true
    end

    if player:useStamina(cfg.staminaRequired) then
        local chanceGet = math.random(100)
        if cfg.chanceGet >= chanceGet then
            player:addItem(cfg.productItem, 1)
        end
        local chanceDestroy = math.random(100)
        if cfg.chanceDestroy >= chanceDestroy then
            toPosition:sendMagicEffect(CONST_ME_POFF)
            item:setCustomAttribute("destroyedTime", os:mtime())
            return true
        end
        toPosition:sendMagicEffect(CONST_ME_HITAREA)
    else
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        player:sendTextMessage(MESSAGE_STATUS_SMALL, ("Not enough stamina (%d required)"):format(cfg.staminaRequired))
    end
	return true
end
