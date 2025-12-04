local potionsMap = {
    ["vitality"] = function(...) return alchemyResultPotionVitality(...) end,
    ["stamina"] = function(...) return alchemyResultPotionStamina(...) end,
    ["venomsap"] = function(...) return alchemyResultPotionVenomsap(...) end,
    ["gorgons_tears"] = function(...) return alchemyResultPotionGorgonsTears(...) end,
}

function alchemyResultPotion(player, kettle, resultData)
    print("Result potion:", resultData.potiontype, "y", potionsMap[resultData.potiontype], "x", alchemyResultPotionVitality)
    local potionHandler = potionsMap[resultData.potiontype]
    if not potionHandler then
        print("Could not find potion handler")
        return false
    end

    local ret = potionHandler(player, kettle, resultData)
    if not ret then
        print("Could not execute potion handler")
        return false
    end

    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, resultData.text)
    return true
end