function alchemyResultPotionVitality(player, kettle, resultData)
    local potionItem = player:addItem(26444, resultData.count)
    potionItem:setQuality(resultData.quality)
    return true
end