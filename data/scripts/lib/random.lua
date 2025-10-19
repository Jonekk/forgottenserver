function randomBetween(min, max)
    return min + math.random(max - min + 1) - 1
end

function randomChance(chance)
    return chance >= math.random(100)
end
