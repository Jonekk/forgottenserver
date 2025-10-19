local LEVEL_LOWER = 1
local LEVEL_SAME = 2
local LEVEL_HIGHER = 3

local DISTANCE_BESIDE = 1
local DISTANCE_CLOSE = 2
local DISTANCE_FAR = 3
local DISTANCE_VERYFAR = 4

local directions = {
	[DIRECTION_NORTH] = "north",
	[DIRECTION_SOUTH] = "south",
	[DIRECTION_EAST] = "east",
	[DIRECTION_WEST] = "west",
	[DIRECTION_NORTHEAST] = "north-east",
	[DIRECTION_NORTHWEST] = "north-west",
	[DIRECTION_SOUTHEAST] = "south-east",
	[DIRECTION_SOUTHWEST] = "south-west"
}

local descriptions = {
	[DISTANCE_BESIDE] = {
		[LEVEL_LOWER] = "below you",
		[LEVEL_SAME] = " somwhere here",
		[LEVEL_HIGHER] = "above you"
	},
	[DISTANCE_CLOSE] = {
		[LEVEL_LOWER] = "to a lower level to the",
		[LEVEL_SAME] = "to the",
		[LEVEL_HIGHER] = "to a higher level to the"
	},
	[DISTANCE_FAR] = "far to the",
	[DISTANCE_VERYFAR] = "very far to the"
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local lastDirection = item:getCustomAttribute("direction")
	local stepsLeft = item:getCustomAttribute("stepsLeft")
	local monster = item:getCustomAttribute("monster")
	local stamina = item:getCustomAttribute("stamina")
	local playerId = item:getCustomAttribute("player")
    if not lastDirection or not stepsLeft or not monster then
        return false
    end

    if not player:useStamina(stamina) then
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        player:sendTextMessage(MESSAGE_STATUS_SMALL, ("Not enough stamina (%d required)"):format(stamina))
		return true
    end

    player:addSkillTries(SKILL_HUNTING, stamina)

	local currentPosition = item:getPosition()
	local nextPosition = getRandomNextValidPosition(currentPosition, lastDirection)
	if nextPosition then
		print("dir:", direction, " dist:", distance, "off:" , offsetX, offsetY, "Pos: ", nextPosition.x, nextPosition.y)
		local positionDifference = {
			x = currentPosition.x - nextPosition.x,
			y = currentPosition.y - nextPosition.y,
			z = 0
		}

		local maxPositionDifference, direction = math.max(math.abs(positionDifference.x), math.abs(positionDifference.y))
		if maxPositionDifference >= 5 then
			local positionTangent = positionDifference.x ~= 0 and positionDifference.y / positionDifference.x or 10
			if math.abs(positionTangent) < 0.4142 then
				direction = positionDifference.x > 0 and DIRECTION_WEST or DIRECTION_EAST
			elseif math.abs(positionTangent) < 2.4142 then
				direction = positionTangent > 0 and (positionDifference.y > 0 and DIRECTION_NORTHWEST or DIRECTION_SOUTHEAST) or positionDifference.x > 0 and DIRECTION_SOUTHWEST or DIRECTION_NORTHEAST
			else
				direction = positionDifference.y > 0 and DIRECTION_NORTH or DIRECTION_SOUTH
			end
		end

		local level = positionDifference.z > 0 and LEVEL_HIGHER or positionDifference.z < 0 and LEVEL_LOWER or LEVEL_SAME
		local distance = maxPositionDifference < 5 and DISTANCE_BESIDE or maxPositionDifference < 101 and DISTANCE_CLOSE or maxPositionDifference < 250 and DISTANCE_FAR or DISTANCE_VERYFAR
		local description = descriptions[distance][level] or descriptions[distance]
		if distance ~= DISTANCE_BESIDE then
			description = description .. " " .. directions[direction]
		end

		player:sendTextMessage(MESSAGE_INFO_DESCR, "The trace leads " .. description .. ".")
		if stepsLeft > 1 then
			local traceItem = Game.createItem(item:getId(), 1, nextPosition)
			traceItem:setCustomAttribute("stepsLeft", stepsLeft - 1)
			traceItem:setCustomAttribute("direction", getAngleBetweenPositions(currentPosition, nextPosition))
			traceItem:setCustomAttribute("monster", monster)
			traceItem:setCustomAttribute("stamina", stamina)
			traceItem:setCustomAttribute("player", playerId)
		else
			Game.createMonster(monster, nextPosition)
		end
	else
		player:sendTextMessage(MESSAGE_INFO_DESCR, "You lost the track.")
	end

	item:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
    item:remove(1)

	return true
end