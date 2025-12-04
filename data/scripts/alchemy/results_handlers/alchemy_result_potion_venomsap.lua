function alchemyResultPotionVenomsap(player, kettle, resultData)
    local potionItem = player:addItem(26446, resultData.count)
    potionItem:setQuality(resultData.quality)
    return true
end