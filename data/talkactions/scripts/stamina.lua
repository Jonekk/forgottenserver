function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		--return true
	end

	if player:getAccountType() < ACCOUNT_TYPE_GOD then
		--return false
	end

	local split = param:splitTrimmed(",")
	if not split[2] then
		player:sendCancelMessage("Insufficient parameters.")
		return false
	end

	local target = Player(split[1])
	if not target then
		player:sendCancelMessage("A player with that name is not online.")
		return false
	end

	local staminaChange = 1
	if split[2] then
		staminaChange = tonumber(split[2])
	end

	target:changeStamina(staminaChange)
	return false
end
