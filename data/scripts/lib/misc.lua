function adjustChanceByQuality(baseChance, quality)
    -- Input validation
    baseChance = math.max(0, baseChance)
    quality = math.max(1, quality)  -- Prevent log(0) errors

    if quality <= 100 then
        return baseChance * (quality / 100)  -- Linear penalty for low quality
    else
        local overquality = quality - 100
        -- last value - more means less rewaring
        local logBoost = 0.5 * math.log(1 + overquality / 35)
        -- Cap to prevent exceeding 90% chance
        return math.min(baseChance * (1 + logBoost), 0.9)
    end
end

function toolWearDown(item, value)
    local durability = item:getCustomAttribute("durability")
    if durability and durability >= value  then
        item:setCustomAttribute("durability", durability - value)
    else
        item:remove(1)
        player:sendTextMessage(MESSAGE_STATUS_SMALL, ("You broke the %s"):format(item:getName()))
    end
end