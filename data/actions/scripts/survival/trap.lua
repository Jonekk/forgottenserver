local config = {
    [26421] = { openTrapId = 26422, stamina = 20, huntingRequired = 5, monsters = {
        ["wolf"] = {chance = 1},
        ["deer"] = {chance = 10},
        ["rabbit"] = {chance = 50},
    }, time = 5},
    [26423] = { openTrapId = 26424, stamina = 40, huntingRequired = 10, monsters = {
        ["bear"] = {chance = 1},
        ["wolf"] = {chance = 50},
    }, time = 5},
    [26425] = { openTrapId = 26426, stamina = 60, huntingRequired = 15, monsters = {
        ["sheep"] = {chance = 1},
        ["bear"] = {chance = 10},
    }, time = 5}
}

function getSpawnedMonster(monstersCfg)
    for monsterName, monsterInfo in pairs(monstersCfg) do
        if randomChance(monsterInfo.chance) then
            return monsterName
        end
    end
    return nil
end

function isPositionVisible(position)
    local spectators = Game.getSpectators(position, false, true, 7, 7, 7, 7)
    return #spectators > 0
end

local function decayAction(pos, itemId, decayTo, monsterName)
    local tile = Tile(pos)
    if tile then
        local item = tile:getItemById(itemId)
        if item then
            -- Custom decay action here
            if isPositionVisible(pos) then
                addEvent(decayAction, 1000, pos, itemId, decayTo, monsterName)
            else
                local bloodItem = Game.createItem(2019, 2, pos) -- Item ID 2016 is blood
                if bloodItem then
                    bloodItem:decay() -- Make the blood decay naturally
                end

                if monsterName then
                    local monster = Game.createMonster(monsterName, pos)

                    -- slow
                    local conditionHaste = Condition(CONDITION_HASTE)
                    conditionHaste:setParameter(CONDITION_PARAM_TICKS, 10 * 1000)
                    conditionHaste:setParameter(CONDITION_PARAM_SPEED, -110)
                    monster:addCondition(conditionHaste)

                    -- damage
                    monster:addHealth(-math.random(1, 10))
                end

                -- tool wearing down
                local durability = item:getCustomAttribute("durability")
                if durability and durability > 1 then
                    item:setCustomAttribute("durability", durability - 1)
                    item:transform(decayTo)
                else
                    item:remove(1)
                end
            end
        end
    end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local cfg = config[item:getId()]
    if not cfg then
        return false
    end

    if fromPosition.x == CONTAINER_POSITION and item:getParent():getId() ~= ITEM_BROWSEFIELD then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You cannot open trap in the inventory.")
        return true
    end

    if cfg.huntingRequired > player:getSkillLevel(SKILL_HUNTING) then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You have too low skill level to set up this trap.")
        return true
    end

    if player:useStamina(cfg.stamina) then
        player:addSkillTries(SKILL_HUNTING, cfg.stamina)
        local itemId = item:getId()
        item:transform(cfg.openTrapId)
        local monsterToSpawn = getSpawnedMonster(cfg.monsters)

        addEvent(decayAction, cfg.time * 1000, toPosition, cfg.openTrapId, itemId, monsterToSpawn)
    end
    
    return true
end


