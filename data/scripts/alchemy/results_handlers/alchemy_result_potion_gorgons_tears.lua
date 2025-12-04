function alchemyResultPotionGorgonsTears(player, kettle, resultData)
    local potionItem = player:addItem(26447, resultData.count)
    potionItem:setQuality(resultData.quality)
    return true
end