local fireSourcesEmpty = {
    -- classic campfire
	[1421] = { transformTo = 1424},
    [1787] = { transformTo = 1786},
}

fireSourcesLit = {
    [1424] = { maxDuration = 20 * 60 * 1000 },
    [1786] = { maxDuration = 60 * 60 * 1000 },
}

local timberList = {
    [ITEM_WOODEN_STICK] = { valueSeconds = 60 },
    [ITEM_PIECE_OF_WOOD] = { valueSeconds = 180 },
}

function cook(player, item, fromPosition, target, toPosition, isHotkey)
end

function addTimber(player, item, fromPosition, target, toPosition, isHotkey)
    local itemId = item:getId()
    local decayTo = 0
    if fireSourcesEmpty[itemId] then
        local quality = item:getCustomAttribute("quality")
        local durability = item:getCustomAttribute("durability")
        local durability_max = item:getCustomAttribute("durability_max")
        item:transform(fireSourcesEmpty[itemId].transformTo)
        
        item:setCustomAttribute("quality", quality)
        item:setCustomAttribute("durability", durability)
        item:setCustomAttribute("durability_max", durability_max)

        decayTo = itemId
    end

    local timberValue = timberList[target:getId()].valueSeconds * 1000
    local currentDuration = item:getDuration()
    local durationToAddMax = fireSourcesLit[item:getId()].maxDuration - currentDuration
    local maxTimberCount= math.floor(durationToAddMax / timberValue)

    local timberUsedCount = math.min(maxTimberCount, target:getCount())
    target:remove(timberUsedCount)

    item:setDuration(item:getDuration() + timberUsedCount * timberValue)
    if decayTo then
        item:decay(decayTo)
    end
end


function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if timberList[target:getId()] then
        return addTimber(player, item, fromPosition, target, toPosition, isHotkey)
    end
    if fireSourcesLit[item:getId()] then
        return cook(player, item, fromPosition, target, toPosition, isHotkey)
    end
    return true
end