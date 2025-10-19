local config = {
	[2826] = {levelRequired = 3, staminaRequired = 10, destroyTo = 2827, products = {
        [2666] = {chance = 90, countMin = 1, countMax = 3},
        -- [skin?]
    }},
    [3095] = {levelRequired = 1, staminaRequired = 20, destroyTo = 3096, products = {
        [2666] = {chance = 90, countMin = 2, countMax = 3},
        [2671] = {chance = 40, countMin = 1, countMax = 2},
        -- [skin?]
    }},

}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local cfg = config[target:getId()]
    print(cfg, target:getId())
    if not cfg then
        return false
    end
    print(cfg)
    if player:getSkillLevel(SKILL_HUNTING) < cfg.levelRequired then
        player:sendTextMessage(("Your hunting level is too low to work on %s"):format(target:getName()))
        return true
    end
    print("b")
    if not player:useStamina(cfg.staminaRequired) then
        player:sendTextMessage(("Your dont have enough stamina [%d]"):format(cfg.staminaRequired))
        return true
    end
    player:addSkillTries(SKILL_HUNTING, cfg.staminaRequired)
    for productId, productInfo in pairs(cfg.products) do
        print(productId, productInfo)
        print(productInfo.chance, productInfo.countMin, productInfo.countMax)
        local chance = productInfo.chance + player:getSkillLevel(SKILL_HUNTING)
        if randomChance(chance) then
            local count = 1
            if productInfo.countMin and productInfo.countMax then
                count = randomBetween(productInfo.countMin, productInfo.countMax)
            end
            player:addItem(productId, count)
        end
    end
    toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
    target:transform(cfg.destroyTo)

    toolWearDown(item, 1)
end
