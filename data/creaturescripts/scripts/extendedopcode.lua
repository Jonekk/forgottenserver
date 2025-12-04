OPCODE_LANGUAGE = 		1
OPCODE_CRAFTING = 		120
OPCODE_HERBALISM = 		121
OPCODE_FISHING = 		122
OPCODE_CONSTRUCTION = 	123
OPCODE_ALCHEMY = 		124
OPCODE_MINING =			125

function onExtendedOpcode(player, opcode, buffer)
	if opcode == OPCODE_LANGUAGE then
		-- otclient language
		if buffer == 'en' or buffer == 'pt' then
			-- example, setting player language, because otclient is multi-language...
			-- player:setStorageValue(SOME_STORAGE_ID, SOME_VALUE)
		end
	elseif opcode == OPCODE_CRAFTING then
		craftingGeneralOnExtendedOpcode(player, opcode, buffer)
	elseif opcode == OPCODE_HERBALISM then
		herbalismOnExtendedOpcode(player, opcode, buffer)
	elseif opcode == OPCODE_FISHING then
		fishingOnExtendedOpcode(player, opcode, buffer)
	elseif opcode == OPCODE_CONSTRUCTION then
		craftingConstructionOnExtendedOpcode(player, opcode, buffer)
	elseif opcode == OPCODE_ALCHEMY then
		alchemyOnExtendedOpcode(player, opcode, buffer)
	elseif opcode == OPCODE_MINING then
		miningOnExtendedOpcode(player, opcode, buffer)
	else
		-- other opcodes can be ignored, and the server will just work fine...
	end
end
