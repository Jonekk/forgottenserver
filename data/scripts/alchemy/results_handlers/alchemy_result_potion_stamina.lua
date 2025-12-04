function alchemyResultPotionStamina(player, kettle, resultData)
    local potionItem = player:addItem(26445, resultData.count)
    potionItem:setQuality(resultData.quality)
    return true
end