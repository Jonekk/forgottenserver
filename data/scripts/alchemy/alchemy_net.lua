AlchemyNet = AlchemyNet or {}

local function getPositionFromToken(token)
	local x, y, z = token:match("(%d+),(%d+),(%d+)")
    local position = Position(x, y, z)
	return position
end

function alchemyOnExtendedOpcode(player, opcode, buffer)
    if opcode ~= OPCODE_ALCHEMY then return true end
    print("RX: ", buffer)
    msg = M.parse_message(buffer)
    if not msg or not msg.cmd then
        print("could not parse message")
        return
    end
	local kettlePosition = getPositionFromToken(msg.tokens.kettlePos)
	if not kettlePosition then
		print("Unknown kettle position")
		return false
	end
	print(kettlePosition, player)
	local kettle = Alchemy:getKettle(kettlePosition, player)
	if not kettle then
		print("Unknown kettle")
		return false
	end

    if msg.cmd == "step" then
		if msg.tokens.step == 'add' then
			local itemPos = getPositionFromToken(msg.tokens.itemPos)
			local ingredient = { itemId = msg.tokens.itemId, itemPos=itemPos }
			Alchemy:kettleAddIngredient(player, kettle, ingredient)
		elseif msg.tokens.step == 'stir' then
			local direction = msg.tokens.direction
			Alchemy:kettleStir(player, kettle, direction)
		elseif msg.tokens.step == "boil" then
			local heat = msg.tokens.heat
			Alchemy:kettleBoil(player, kettle, heat)
		else
			print("Unknown step: " .. msg.tokens.step)
		end
	elseif msg.cmd == "brew" then
		Alchemy:kettleBrew(player, kettle)
    end
end

function AlchemyNet:sendOpenKettle(player, pos, itemId, stepsList)
	payload = {itemId = itemId, pos = string.format("%d,%d,%d", pos.x, pos.y, pos.z), stepsList=stepsList}
	local msg = M.compose_message("open_result", payload)
	print("Alchemy TX: " .. msg)
    player:sendExtendedOpcode(OPCODE_ALCHEMY, msg)
	return true
end

function AlchemyNet:sendStepResult(player, success, stepData)
	local payload = {success = success, step = stepData.step}
	if stepData.step == "add" then
		payload.clientItemId = stepData.clientItemId
		payload.quality = stepData.quality
		payload.purity = stepData.purity
	elseif stepData.step == "stir" then
		payload.direction = stepData.direction
	elseif stepData.step == "boil" then
		payload.heat = stepData.heat
	else
		print("Unknown step in stepData")
		return false
	end
	local msg = M.compose_message("step_result", payload)
    print("Alchemy TX: " .. msg)
    player:sendExtendedOpcode(OPCODE_ALCHEMY, msg)

	return true
end

function AlchemyNet:sendBrewResult(player, pos, itemId, success)
	payload = {itemId = itemId, pos = string.format("%d,%d,%d", pos.x, pos.y, pos.z), stepsList=stepsList}
	local msg = M.compose_message("brew_result", payload)
	print("Alchemy TX: " .. msg)
    player:sendExtendedOpcode(OPCODE_ALCHEMY, msg)
	return true
end