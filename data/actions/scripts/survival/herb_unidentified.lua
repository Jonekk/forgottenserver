local function chanceHerbalismBasic(fluency, herbalismLevel, chanceMin, chanceMax, k)
    return math.min(chanceMax, (chanceMax - (chanceMax - chanceMin) * math.exp(-k * fluency)) * ((100 + herbalismLevel) / 100))
end
------------------------------------
local HERBS_MAP = {
    [26427] = { chanceFun=chanceHerbalismBasic, chanceMin=10, chanceMax=75, chanceArg1=0.03, herbalismTries = 10}
}
------------------------------------

function herbalismOnExtendedOpcode(player, opcode, buffer)
    if opcode ~= OPCODE_HERBALISM then return true end
    -- print("RX: ", buffer)
    msg = M.parse_message(buffer)
    if not msg or not msg.cmd then
        print("could not parse message")
        return
    end

    local x, y, z = msg.tokens.pos:match("(%d+),(%d+),(%d+)")
    local position = Position(x, y, z)
    local tile = Tile(position)
    local itemId = tonumber(msg.tokens.itemId)
    local herbItem = tile:getItemById(itemId)
    if not herbItem then
        local msg = M.compose_message(msg.cmd, {status=false, error="This item does not exist"})
        player:sendExtendedOpcode(OPCODE_HERBALISM, msg)
        return false
    end
    local targetItemId = herbItem:getCustomAttribute("targetItem")
    local herbInfo = HERBS_MAP[targetItemId]
    if not herbInfo then
        local msg = M.compose_message(msg.cmd, {status=false, error="This item is not a gatherable herb"})
        player:sendExtendedOpcode(OPCODE_HERBALISM, msg)
        return false
    end
    
    if msg.cmd == "identify" then
        local skill_tries = 0
        local success = false
        local chance = herbInfo.chanceFun(player:getHerbFluency(targetItemId), player:getSkillLevel(SKILL_HERBALISM), herbInfo.chanceMin, herbInfo.chanceMax, herbInfo.chanceArg1)
        if randomChance(chance) then
            herbItem:transform(targetItemId)
            skill_tries = herbInfo.herbalismTries * 2
            position:sendMagicEffect(CONST_ME_MAGIC_BLUE)
            success = true
        else
            herbItem:remove(1)
            skill_tries = herbInfo.herbalismTries
            position:sendMagicEffect(CONST_ME_POFF)
        end
        local msg = M.compose_message("identify", {status=true, success=success})
        player:sendExtendedOpcode(OPCODE_HERBALISM, msg)
    elseif msg.cmd == "examine" then
        herbItem:remove(1)
        skill_tries = herbInfo.herbalismTries
        position:sendMagicEffect(CONST_ME_MAGIC_BLUE)
        player:addHerbFluency(targetItemId, 1)
        local msg = M.compose_message("examine", {status=true})
        player:sendExtendedOpcode(OPCODE_HERBALISM, msg)
    end
    player:addSkillTries(SKILL_HERBALISM, skill_tries)
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if player:getSkillLevel(SKILL_HERBALISM) < 0 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You cannot identify belowe " .. 5 .. " herbalism level")
        return
    end
    local targetItemId = item:getCustomAttribute("targetItem")
    local herbInfo = HERBS_MAP[targetItemId]
    if not herbInfo then
        print(targetItemId .. " not found in map")
        return false
    end
    local playerFluency = player:getHerbFluency(targetItemId)
    local quality = item:getQuality()
    local herbName = "unknown"
    if playerFluency >= 10 then
        local targetItemType = ItemType(targetItemId)
        herbName = targetItemType:getName()
    end
    local chance = herbInfo.chanceFun(playerFluency, player:getSkillLevel(SKILL_HERBALISM), herbInfo.chanceMin, herbInfo.chanceMax, herbInfo.chanceArg1)

    local msg = M.compose_message("unidentified_data", {pos=string.format("%d,%d,%d", toPosition.x, toPosition.y, toPosition.z), itemId=item:getId(), chance=chance, quality=quality, name=herbName})
    player:sendExtendedOpcode(OPCODE_HERBALISM, msg)
    return true
end