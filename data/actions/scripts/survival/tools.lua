local config = {
	[ITEM_STONE_AXE] = {
        [2720] = {staminaRequired = 5, productItems = {[ITEM_WOODEN_STICK] = {chance = 60}}, chanceDestroy = 10, destroyTime=10, destroyTo=8786}, -- dead tree
        [2717] = {staminaRequired = 5, productItems = {[ITEM_WOODEN_STICK] = {chance = 60}}, chanceDestroy = 10, destroyTime=10, destroyTo=8786}, -- dead tree
        [2714] = {staminaRequired = 5, productItems = {[ITEM_WOODEN_STICK] = {chance = 60}}, chanceDestroy = 10, destroyTime=10, destroyTo=8786}, -- dead tree
        [2709] = {staminaRequired = 5, productItems = {[ITEM_WOODEN_STICK] = {chance = 60}}, chanceDestroy = 10, destroyTime=10, destroyTo=8786}, -- dead tree
    },
	[ITEM_STONE_PICK] = {
        -- small stones
        [1356] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 60}}, chanceDestroy = 20, destroyTime=10},
        [1285] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 60}}, chanceDestroy = 20, destroyTime=10},
        [3616] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 60}}, chanceDestroy = 20, destroyTime=10},
        [3607] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 60}}, chanceDestroy = 20, destroyTime=10},
        -- big stones 2x1 or 2x2
        [3620] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 60}}, chanceDestroy = 5, destroyTime=10},
        [1286] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 60}}, chanceDestroy = 5, destroyTime=10},
        [1291] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 60}}, chanceDestroy = 5, destroyTime=10},
        [1306] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 60}}, chanceDestroy = 5, destroyTime=10},
        [1299] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 60}}, chanceDestroy = 5, destroyTime=10},
        [3631] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 60}}, chanceDestroy = 5, destroyTime=10},
        -- custom ores
        [26396] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 30}, [ITEM_PILE_OF_SALT] = {chance = 30}}, chanceDestroy = 10, destroyTime=10}, -- saltstone
        [26397] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 30}, [ITEM_COAL] = {chance = 20}}, chanceDestroy = 10, destroyTime=10}, -- blackrock
        [26398] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 30}, [ITEM_COPPER_ORE] = {chance = 20}}, chanceDestroy = 10, destroyTime=10}, -- firevein
        [26399] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 30}, [ITEM_IRON_ORE] = {chance = 10}}, chanceDestroy = 10, destroyTime=10}, -- bogvein
        [26400] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 30}, [ITEM_IRON_ORE] = {chance = 40}}, chanceDestroy = 10, destroyTime=10}, -- bloodrock
        [26401] = {staminaRequired = 5, productItems = {[ITEM_SMALL_STONE] = {chance = 30}, [ITEM_TIN_ORE] = {chance = 20}}, chanceDestroy = 10, destroyTime=10}, -- palevein
    },
}

local skillsPerToolUse = {
    [ITEM_STONE_AXE] = {},
    [ITEM_STONE_PICK] = { [SKILL_MINING] = { skillTriesPerStamina = 1} }
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local cfgTool = config[item:getId()]
    local cfgTarget = cfgTool[target:getId()]
    local cfgSkill = skillsPerToolUse[item:getId()]

    if not cfgTarget then
        return false
    end

    destroyedUntil = target:getCustomAttribute("destroyedUntil")
    if destroyedUntil and os:mtime() < destroyedUntil then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, ("Target %s is empty"):format(target:getName()))
        return true
    end

    if player:useStamina(cfgTarget.staminaRequired) then
        -- generate products
        for productId, productInfo in pairs(cfgTarget.productItems) do
            local random = math.random(100)
            local chance = productInfo.chance
            local itemQuality = item:getQuality()
            if itemQuality then
                chance = adjustChanceByQuality(chance, itemQuality)
            end
            if random < productInfo.chance then
                player:addItem(productId, 1)
            end
        end
        local random = math.random(100)
        if random < cfgTarget.chanceDestroy then
            toPosition:sendMagicEffect(CONST_ME_POFF)
            player:sendTextMessage(MESSAGE_DAMAGE_DEALT, "", toPosition, 10, TEXTCOLOR_RED)
            local destroyedTime = gaussianRandom20p(cfgTarget.destroyTime * 1000)
            if cfgTarget.destroyTo then
                local targetLiveId = target:getId()
                target:transform(cfgTarget.destroyTo)
                target:setDuration(destroyedTime)
                target:decay(targetLiveId)
            else 
                target:setCustomAttribute("destroyedUntil", os:mtime() + destroyedTime)
            end
        else
            player:sendTextMessage(MESSAGE_DAMAGE_DEALT, "", toPosition, 10, TEXTCOLOR_RED)
            toPosition:sendMagicEffect(CONST_ME_HITAREA)
        end

        -- tool wearing down
        local durability = item:getCustomAttribute("durability")
        if durability and durability > 1 then
            item:setCustomAttribute("durability", durability - 1)
        else
            item:remove(1)
            player:sendTextMessage(MESSAGE_STATUS_SMALL, ("You broke the %s"):format(item:getName()))
        end

        -- skills increase
        if cfgSkill then
            for skillId, skillCfg in pairs(cfgSkill) do
                player:addSkillTries(skillId, skillCfg.skillTriesPerStamina * cfgTarget.staminaRequired)
            end
        end
    else
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        player:sendTextMessage(MESSAGE_STATUS_SMALL, ("Not enough stamina (%d required)"):format(cfgTarget.staminaRequired))
    end
	return true
end
