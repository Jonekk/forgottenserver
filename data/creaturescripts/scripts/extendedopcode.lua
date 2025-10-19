local OPCODE_LANGUAGE = 1
local OPCODE_CRAFTING = 120

function onExtendedOpcode(player, opcode, buffer)
	if opcode == OPCODE_LANGUAGE then
		-- otclient language
		if buffer == 'en' or buffer == 'pt' then
			-- example, setting player language, because otclient is multi-language...
			-- player:setStorageValue(SOME_STORAGE_ID, SOME_VALUE)
		end
	elseif opcode == OPCODE_CRAFTING then
		craftingOnExtendedOpcode(player, opcode, buffer)
	else
		-- other opcodes can be ignored, and the server will just work fine...
	end
end
