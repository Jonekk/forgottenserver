

local activeMinings = {}
local maxChancePerLoot = 30
local defaultMiningDestroyToList = { 3648, 3649, 3650, 3651, 3652 }

local PICKAXES = {
    { id = ITEM_STONE_PICK, level = 1, damage = 5 }
}

local MINING_ITEMS = {
    -- small stones
    {
        oreIds = { 1356, 1285, 3615, 3616, 3607 },
        durability = 70,
        difficulty = 5,
        minSkill = 1,
        minPickLevel = 1,
        multi = true,
        decayDuration = 20, --seconds
        loot = {
            { type = "item",    itemId = 1294,      lootChance = 100 },
            { type = "monster", monsterId = "Bat",  lootChance = 5 },
            { type = "pickDamage",                   lootChance = 3 },
            { type = "pickLose",                     lootChance = 1 },
        }
    },

    --------- custom ores
    {
        oreIds = { 26396 }, -- saltstone
        difficulty = 5,
        minSkill = 1,
        minPickLevel = 1,
        loot = {
            { type = "item",    itemId = 1294,      lootChance = 100 },
        }
    },
    {
        oreIds = { 26397 }, -- blackrock
        difficulty = 5,
        loot = {
            { type = "item",    itemId = 1294,      lootChance = 100 },
            { type = "monster", monsterId = "Bat",  lootChance = 5 },
            { type = "pickDamage",                   lootChance = 3 },
            { type = "pickLose",                     lootChance = 1 },
            { type = "nothing",                     lootChance = 5 }
        }
    },
    {
        oreIds = { 26398 }, -- firevein
        difficulty = 5,
        minSkill = 2,
        minPickLevel = 1,
        loot = {
            { type = "item",    itemId = 1294,      lootChance = 100 },
            { type = "monster", monsterId = "Bat",  lootChance = 5 },
            { type = "pickDamage",                   lootChance = 3 },
            { type = "pickLose",                     lootChance = 1 },
        }
    },
    {
        oreIds = { 26399 }, -- bogvein
        difficulty = 5,
        minSkill = 2,
        minPickLevel = 2,
        loot = {
            { type = "item",    itemId = 1294,      lootChance = 100 },
            { type = "monster", monsterId = "Bat",  lootChance = 5 },
            { type = "pickDamage",                   lootChance = 3 },
            { type = "pickLose",                     lootChance = 1 },
        }
    },
    {
        oreIds = { 26400 }, -- bloodrock
        difficulty = 5,
        minSkill = 1,
        minPickLevel = 1,
        loot = {
            { type = "item",    itemId = 1294,      lootChance = 100 },
            { type = "monster", monsterId = "Bat",  lootChance = 5 },
            { type = "pickDamage",                   lootChance = 3 },
            { type = "pickLose",                     lootChance = 1 },
        }
    },
    {
        oreIds = { 26401 }, -- palevein
        difficulty = 5,
        minSkill = 1,
        minPickLevel = 1,
        loot = {
            { type = "item",    itemId = 1294,      lootChance = 100 },
            { type = "monster", monsterId = "Bat",  lootChance = 5 },
            { type = "pickDamage",                   lootChance = 3 },
            { type = "pickLose",                     lootChance = 1 },
        }
    },    
}

local function getMiningDef(miningItemId)
    for i, miningdef in ipairs(MINING_ITEMS) do
        for j, oreId in ipairs(miningdef.oreIds) do
            if oreId == miningItemId then
                return miningdef
            end
        end
    end
    return nil
end

local function getPickDef(pickItem)
    for _, pick in ipairs(PICKAXES) do
        if pick.id == pickItem:getId() then
            return pick
        end
    end
    return nil
end

local function rollLoot(pool)
    local total = 0
    for _, entry in ipairs(pool) do
        total = total + entry.lootChance
    end
    if total <= 0 then
        return nil
    end

    local roll = math.random(1, total)
    local cum = 0
    for _, entry in ipairs(pool) do
        cum = cum + entry.lootChance
        if roll <= cum then
            return entry
        end
    end
    return nil
end

local function resolveLoot(player, waterPos, loot, activeMining)    
    if loot.type == "item" then
        local newItem = player:addItem(loot.itemId)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found " .. newItem:getName() .. ".")
    elseif loot.type == "nothing" then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You didnt mine anyting.")
    elseif loot.type == "pickDamage" then
        local damage = gaussianRandom20p(20)
        if activeMining.miningItem then
            local _, newD = activeMining.miningItem:addDurability(-damage)
            if newD == 0 then
                activeMining.miningItem = nil
            end

            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You hit something hard, damanging the pick (- " .. damage .." durability).")
        end
    elseif loot.type == "pickLose" then
        if activeMining.miningItem then
            activeMining.miningItem:remove(1)
            activeMining.miningItem = nil
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The pickaxe broke in half!")
        end
    elseif loot.type == "monster" then
        Game.createMonster(loot.monsterId, player:getPosition(), true, true)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The sounds of digging with a pickaxe attracted " .. loot.monsterId .. " from nearby!")
    end

end

function miningOnExtendedOpcode(player, opcode, buffer)
    if opcode ~= OPCODE_MINING then return true end
    print("RX: ", buffer)
    msg = M.parse_message(buffer)
    if not msg or not msg.cmd then
        print("mining: could not parse message")
        return
    end

    local activeMining = activeMinings[player:getName()]
    if not activeMining then
        return
    end

    if msg.cmd == "mining_finish" then
        if msg.tokens.finished == "true" and msg.tokens.success == "true" then
            player:addSkillTries(SKILL_MINING, 1)
            -- TODO
            if activeMining.miningItem then
                --activeMining.miningItem:removeDurability(5)
            end
            -- local toPosition = activeMining.pos
            -- resolveLoot(player, toPosition, activeMining)

        end
    elseif msg.cmd == "mining_step" then

        if not player:useStamina(3) then
            local msg = M.compose_message("mining_finish", {reason = "no stamina"})
            print("TX: " .. msg)
            player:sendExtendedOpcode(OPCODE_MINING, msg)
            return true
        end

        local pickDef = getPickDef(activeMining.miningItem)
        local pickDurabilityDelta, pickNewDurability = activeMining.miningItem:addDurability(-1)
        if pickNewDurability == 0 then
            activeMining.miningItem = nil
        end
        local oreDestroyed = false
        if msg.tokens.success == "true" then
            player:addSkillTries(SKILL_MINING, 3)

            local damage = round(gaussianRandom50p(pickDef.damage * (7 + player:getSkillLevel(SKILL_MINING)) / 7)) * (0.75 + msg.tokens.successLevel / 4)
            local oreDurability = activeMining.target:getDurability()
            local realDamage = math.min(oreDurability, damage)

            local toPosition = activeMining.pos
            player:sendTextMessage(MESSAGE_DAMAGE_DEALT, "", toPosition, realDamage, TEXTCOLOR_RED)
            toPosition:sendMagicEffect(CONST_ME_HITAREA)

            if oreDurability == realDamage and activeMining.miningDef.multi == true then
                local originalId = activeMining.target.itemid
                activeMining.target:transform(randomItemFromTable(defaultMiningDestroyToList))
                activeMining.target:setMaxDurability(-1)
                activeMining.target:setDuration(activeMining.miningDef.decayDuration * 1000)
                activeMining.target:decay(originalId)

                oreDestroyed = true
            else
                local _, newOreDurability = activeMining.target:addDurability(-realDamage)
                if newOreDurability == 0 then
                    oreDestroyed = true
                end
            end

            local totalChance = maxChancePerLoot / 2 * realDamage / 5
            print("real damage: ", realDamage, "totalchance:", totalChance)
            while totalChance > 0 do
                local chanceSingle = math.min(totalChance, maxChancePerLoot)
                if randomChance(chanceSingle) then
                    local loot = rollLoot(activeMining.miningDef.loot)
                    print(loot, loot.type, loot.itemId, loot.monsterId)
                    resolveLoot(player, toPosition, loot, activeMining)
                    break
                end
                totalChance = totalChance - chanceSingle
            end
        end

        if oreDestroyed then
            local msg = M.compose_message("mining_finish", {reason = "ore destroyed"})
            print("TX: " .. msg)
            player:sendExtendedOpcode(OPCODE_MINING, msg)
            return true
        end

        -- pickaxe destroyed
        if not activeMining.miningItem then
            local msg = M.compose_message("mining_finish", {reason = "pickaxe destroyed"})
            print("TX: " .. msg)
            player:sendExtendedOpcode(OPCODE_MINING, msg)
            return true
        end

        -- no stamina for next swing, finish
        if player:getStamina() < 3 then
            local msg = M.compose_message("mining_finish", {reason = "no stamina"})
            print("TX: " .. msg)
            player:sendExtendedOpcode(OPCODE_MINING, msg)
            return true
        end

        local msg = M.compose_message("mining_update", { oreDurability = activeMining.target:getDurability()})
        print("TX: " .. msg)
        player:sendExtendedOpcode(OPCODE_MINING, msg)
    end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    print("mining onUse", target.itemid)
	local targetId = target.itemid
    local miningDef = getMiningDef(targetId)
    if not miningDef then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "That cant be mined.")
        return true
    end

    if player:getSkillLevel(SKILL_MINING) < miningDef.minSkill then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You mining skill is too low.")
        return true
    end

    local pickDef = getPickDef(item)
    if not pickDef.level or pickDef.level < miningDef.minPickLevel then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "That cant be mined with selected tool.")
        return true
    end
    
    if target:getDurability() == -1 then
        local durability = gaussianRandom50p(miningDef.durability)
        target:setMaxDurability(durability)
        target:setDurability(durability)
    end


    local difficulty = gaussianRandom20p(miningDef.difficulty)
    activeMinings[player:getName()] = { target = target, pos = toPosition, miningItem = item, miningDef = miningDef }
    local msg = M.compose_message("mining_start",
        {
            oreDurability = target:getDurability(),
            oreDurabilityMax = target:getMaxDurability(),
            difficulty=difficulty,
            pos=string.format("%d,%d,%d", toPosition.x, toPosition.y, toPosition.z)
        }
    )
    print("TX: " .. msg)
    player:sendExtendedOpcode(OPCODE_MINING, msg)
    return true
end