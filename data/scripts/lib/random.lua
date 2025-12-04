function randomBetween(min, max)
    return min + math.random(max - min + 1) - 1
end

function randomChance(chance)
    local roll = math.random(100)
    -- print(roll .. " / " .. chance)
    return chance >= roll
end

function randomItemFromTable(tbl)
    return tbl[math.random(#tbl)]
end