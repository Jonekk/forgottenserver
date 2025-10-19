local huntMonsters = {
    ["rabbit"] =    {levelRequired = 1,     stamina = 10, traceId = 26418, chance = 80},
    ["deer"] =      {levelRequired = 3,     stamina = 15, traceId = 26419, chance = 80},
    ["wolf"] =      {levelRequired = 5,     stamina = 15, traceId = 26417, chance = 60},
    ["bear"] =      {levelRequired = 10,    stamina = 20, traceId = 26420, chance = 20},
}


function isWalkableWater(pos)
    local tile = Tile(pos)
    if tile then
        local ground = tile:getGround()
        if ground then
            local groundId = ground:getId()
            if groundId >= 4820 and groundId <= 4825 then
                return true
            end
        end
    end
    return false
end

function posIsAllowedToTrace(pos)
    local tile = Tile(pos)
    if tile and tile:isWalkable() and not isWalkableWater(pos) and not tile:hasFlag(TILESTATE_PROTECTIONZONE) then
        return pos
    end
end

function getValidPositionInArea(centerPos, minRadius, maxRadius, z)
	for i = 1, PATH_CONFIG.maxAttemptsPerPoint do
		local dx = math.random(-maxRadius, maxRadius)
		local dy = math.random(-maxRadius, maxRadius)

		if math.abs(dx) >= minRadius or math.abs(dy) >= minRadius then
			local pos = Position(centerPos.x + dx, centerPos.y + dy, z or centerPos.z)
			if posIsAllowedToTrace(pos) then
				return pos
			end
		end
	end
	return nil
end

--function getRandomValidPositionInRange(originPos, minDist, maxDist)
--	for i = 1, MAX_ATTEMPTS_END do
--		-- Generate a random angle in radians
--		local angle = math.random() * 2 * math.pi
--
--		-- Generate a random distance between minDist and maxDist
--		local distance = math.random(minDist * 100, maxDist * 100) / 100 -- allow sub-tile precision
--
--		-- Convert polar to Cartesian offset
--		local dx = math.floor(math.cos(angle) * distance + 0.5)
--		local dy = math.floor(math.sin(angle) * distance + 0.5)
--
--		local x = originPos.x + dx
--		local y = originPos.y + dy
--		local z = originPos.z
--
--		local pos = Position(x, y, z)
--        if posIsAllowedToTrace(pos) then
--            return pos
--        end
--
--	end
--
--	return nil -- No valid tile found in attempts
--end

--function getValidPositionInArea(centerPos, minRadius, maxRadius, z)
--    for i = 1, MAX_ATTEMPTS_PATH do
--        -- Generate random angle and distance
--        local angle = math.random() * 2 * math.pi
--        local distance = math.random(minRadius, maxRadius)
--        
--        local x = centerPos.x + math.floor(math.cos(angle) * distance)
--        local y = centerPos.y + math.floor(math.sin(angle) * distance)
--        local pos = Position(x, y, z or centerPos.z)
--        
--        if posIsAllowedToTrace(pos) then
--            return pos
--        end
--    end
--    return nil
--end

PATH_CONFIG = {
    -- Base step distance range (in tiles)
    minStepDistance = 11,
    maxStepDistance = 15,
    
    -- Directional variation controls
    maxDirectionChangePrimary = math.pi/2,
    maxDirectionChangeBackup = math.pi,
    
    -- Distance thresholds (in tiles)
    startRadius = {3, 5}, -- First point from start
    
    -- Attempt limits
    maxAttemptsPerPoint = 25,
    maxPointLookupDistance = 3
}

function getDistanceBetween(pos1, pos2)
    local dx, dy = pos2.x - pos1.x, pos2.y - pos1.y
    return math.sqrt(dx*dx + dy*dy)
end

function getRandomNextAngle(prevAngle, maxDirectionChange)
	local minAngle = prevAngle - maxDirectionChange
	local maxAngle = prevAngle + maxDirectionChange

	-- Normalize range to [0, 2π)
	local function normalize(angle)
		angle = angle % (2 * math.pi)
		return angle
	end

	local newAngle = math.random() * (maxAngle - minAngle) + minAngle
	return normalize(newAngle)
end

function getStepOffset(angle, distance)
	local dx = math.floor(math.cos(angle) * distance + 0.5)
	local dy = math.floor(math.sin(angle) * distance + 0.5)
	return dx, dy
end

function getRandomNextValidPosition(lastPosition, lastDirection)
	for i = 1, PATH_CONFIG.maxAttemptsPerPoint do
        local distance = math.random(PATH_CONFIG.minStepDistance, PATH_CONFIG.maxStepDistance)
        local maxAngleChange = PATH_CONFIG.maxDirectionChangePrimary
        if  i > (PATH_CONFIG.maxAttemptsPerPoint / 2) then
            maxAngleChange = PATH_CONFIG.maxDirectionChangeBackup
        end
        local direction = getRandomNextAngle(lastDirection, maxAngleChange)
        local offsetX, offsetY = getStepOffset(direction, distance)
        local nextPositionCandidate = Position(lastPosition.x + offsetX, lastPosition.y + offsetY, lastPosition.z)
		if posIsAllowedToTrace(nextPositionCandidate) then
		    return nextPositionCandidate
		end
	end
	return nil
end

function getAngleBetweenPositions(fromPos, toPos)
	local dx = toPos.x - fromPos.x
	local dy = toPos.y - fromPos.y
	return math.atan2(dy, dx)
end

function onSay(player, words, param)
	local monsterName = param
    local huntCfg = huntMonsters[monsterName]
    print(monsterName)
    if not huntCfg then
        return false
    end

    if player:getSkillLevel(SKILL_HUNTING) < huntCfg.levelRequired then
        return false
    end

    if not player:useStamina(huntCfg.stamina) then
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        player:sendTextMessage(MESSAGE_STATUS_SMALL, ("Not enough stamina (%d required)"):format(huntCfg.stamina))
    end
    player:addSkillTries(SKILL_HUNTING, huntCfg.stamina)

    if not randomChance(huntCfg.chance) then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, ("You could not find any traced of %s"):format(monsterName))
        return true
    end
    local direction = math.random() * 2 * math.pi
    local distance = math.random(PATH_CONFIG.startRadius[1], PATH_CONFIG.startRadius[2])
    local offsetX, offsetY = getStepOffset(direction, distance)

    local playerPosition = player:getPosition()
    print(direction, distance, offsetX, offsetY)
    local tracePositionCandidate = Position(playerPosition.x + offsetX, playerPosition.y + offsetY, playerPosition.z)
    local tracePosition = getValidPositionInArea(tracePositionCandidate, 0, PATH_CONFIG.maxPointLookupDistance)
    if not tracePosition then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, ("Could not trace %s"):format(monsterName))
        return true
    end
    local traceItem = Game.createItem(huntCfg.traceId, 1, tracePosition)

    traceItem:setCustomAttribute("stepsLeft", math.random(5, 10))
    traceItem:setCustomAttribute("direction", getAngleBetweenPositions(playerPosition, tracePosition))
    traceItem:setCustomAttribute("monster", monsterName)
    traceItem:setCustomAttribute("stamina", huntCfg.stamina)
    traceItem:setCustomAttribute("player", player:getGuid())
	return true
end
