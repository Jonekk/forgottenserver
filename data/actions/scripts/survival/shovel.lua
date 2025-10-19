GRASS_FROM_ID = 9043
GRASS_TO_ID = 9058
DIRTS = { 103, 804, 806, 4832, 4833}

function isGrass(item)
    if item then
        local itemId = item:getId()
        if itemId >= GRASS_FROM_ID and itemId <= GRASS_TO_ID then
            return true
        end
    end
    return false
end

function isDirt(item)
    if item then
        local itemId = item:getId()
        if table.contains(DIRTS, itemId) then
            return true
        end
    end
    return false
end

-- checks 3x3 around center
function digAllowed(centerX, centerY, z)
    for x = centerX - 1, centerX + 1 do
        for y = centerY - 1, centerY + 1 do
            -- Process tile at position (x, y, z)
            local tile = Tile(x, y, z)
            if not tile or not tile:isConstructable() then
                return false
            end
            if tile then
                local groundItem = tile:getGround()
                if not isGrass(groundItem) and not isDirt(groundItem) then
                    return false
                end
            end
        end
    end
    return true
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)

    if digAllowed(toPosition.x, toPosition.y, toPosition.z) then
        local tile = Tile(toPosition.x, toPosition.y, toPosition.z)
        tile:constructItem(804)
        tile:getPosition():sendMagicEffect(CONST_ME_POFF)
    end
end