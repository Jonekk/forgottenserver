---- saltwater
-- 26450 tentacle
-- 26451 salmon
-- 26452 roach
-- 26454 mackerel
-- 26455 herring
-- 26458 cod
-- 26460 closed clam
-- 26462 flounder
---- freshwater
-- 26453 pike
-- 26456 bass
-- 26457 eel
-- 26463 zander
-- 26461 carp

local activeFishings = {}

local waterIds = {493, 4608, 4609, 4610, 4611, 4612, 4613, 4614, 4615, 4616, 4617, 4618, 4619, 4620, 4621, 4622, 4623, 4624, 4625, 7236, 10499, 15401, 15402}

-- Default loot if no zone matched
local DEFAULT_FISHING_LOOT = {
    { type = "item",    itemId = 26450, difficulty = 10,    chance = 10,    minSkill = 5    },  -- tentacle
    { type = "item",    itemId = 26451, difficulty = 10,    chance = 30,    minSkill = 10   },  -- salmon
    { type = "item",    itemId = 26452, difficulty = 6,     chance = 100,   minSkill = 3    }, -- roach
    { type = "item",    itemId = 26454, difficulty = 8,     chance = 50,                    },  -- mackerel
    { type = "item",    itemId = 26455, difficulty = 5,     chance = 100,                   }, -- herring
    { type = "item",    itemId = 26458, difficulty = 8,     chance = 70,                    },  -- cod
    { type = "item",    itemId = 26460, difficulty = 5,     chance = 25,    minSkill = 8    },   -- closed clam
    { type = "item",    itemId = 26462, difficulty = 4,     chance = 70,                    },  -- flounder
    { type = "monster", monsterId = "Crab", difficulty = 7, chance = 30,    minSkill = 5    },
    { type = "rodDamage",               difficulty = 7,     chance = 25,    minSkill = 5    },
    { type = "rodLose",                 difficulty = 6,     chance = 20,    minSkill = 8    },
    { type = "nothing",                 difficulty = 5,     chance = 40                     },
}

local FISHING_ZONES = {
    -- Lake 1
    {
        fromPos = Position(980, 967, 7),
        toPos   = Position(985, 970, 7),
        loot = {
            { type = "item",    itemId = 2667, difficulty = 5, chance = 100 },
            { type = "monster", monsterId = "Crab", difficulty = 7, chance = 5, minSkill = 5 },
            { type = "rodDamage",            difficulty = 7, chance = 3, minSkill = 5 },
            { type = "rodLose",              difficulty = 6, chance = 1, minSkill = 8},
            { type = "nothing",              difficulty = 5, chance = 5 }
        }
    },

    -- Lake 2
    {
        fromPos = Position(979, 970, 7),
        toPos   = Position(979, 970, 7),
        loot = {
            { type = "item",    difficulty = 5, itemId = 2667, chance = 5000 },
            { type = "nothing",              chance = 1000 }
        }
    }
}

local function getZoneByPos(pos)
    for _, zone in ipairs(FISHING_ZONES) do
        if pos.x >= zone.fromPos.x and pos.x <= zone.toPos.x
        and pos.y >= zone.fromPos.y and pos.y <= zone.toPos.y
        and pos.z == zone.fromPos.z then
            return zone
        end
    end
    return nil
end

local function filterLootBySkill(lootPool, skill)
    local filtered = {}
    for _, entry in ipairs(lootPool) do
        if not entry.minSkill or skill >= entry.minSkill then
            table.insert(filtered, entry)
        end
    end
    return filtered
end


local function rollLoot(pool)
    local total = 0
    for _, entry in ipairs(pool) do
        total = total + entry.chance
    end
    if total <= 0 then
        return nil
    end

    local roll = math.random(1, total)
    local cum = 0
    for _, entry in ipairs(pool) do
        cum = cum + entry.chance
        if roll <= cum then
            return entry
        end
    end
    return nil
end

local function resolveLoot(player, waterPos, activeFishing)
    local loot = activeFishing.loot
    if loot.type == "item" then
        local newItem = player:addItem(loot.itemId)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found " .. newItem:getName() .. ".")
    elseif loot.type == "nothing" then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You didnt catch anyting.")
    elseif loot.type == "rodDamage" then
        -- TODO
        if activeFishing.fishingRod then
            -- item:removeDurability()
        end
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You pulled so strong you damanged the fishing rod.")
    elseif loot.type == "rodLose" then
        if activeFishing.fishingRod then
            activeFishing.fishingRod:remove(1)
        end
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The fishing rod slipped out of your hands and fell into the water!")
    elseif loot.type == "monster" then
        Game.createMonster(loot.monsterId, player:getPosition(), true, true)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You pulled " .. loot.monsterId .. " from water!")
    end

end

function fishingOnExtendedOpcode(player, opcode, buffer)
    if opcode ~= OPCODE_FISHING then return true end
    print("RX: ", buffer)
    msg = M.parse_message(buffer)
    if not msg or not msg.cmd then
        print("could not parse message")
        return
    end

    local activeFishing = activeFishings[player:getName()]
    if not activeFishing then
        return
    end

    if msg.cmd == "fishing_finish" then
        if msg.tokens.finished == "true" and msg.tokens.success == "true" then
            player:addSkillTries(SKILL_FISHING, 1)
            -- TODO
            if activeFishing.fishingRod then
                --activeFishing.fishingRod:removeDurability(5)
            end
            local toPosition = activeFishing.pos
            resolveLoot(player, toPosition, activeFishing)
        end
    elseif msg.cmd == "fishing_step" then
        local toPosition = activeFishing.pos
        toPosition:sendMagicEffect(CONST_ME_LOSEENERGY)
    end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    print("fishing onUse")
	local targetId = target.itemid
	if not table.contains(waterIds, targetId) then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You cannot fish there")
		return true
	end

    local lootList = DEFAULT_FISHING_LOOT
    local zone = getZoneByPos(toPosition)
    if zone then
        lootList = zone.loot
    end

    local filteredLoot = filterLootBySkill(lootList, player:getSkillLevel(SKILL_FISHING))
    local finalLoot = rollLoot(filteredLoot)

    if not player:removeItem(3976, 1) then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You need worms")
        return true
    end

    local difficulty = gaussianRandom20p(finalLoot.difficulty)
    if finalLoot.type == "nothing" then
        difficulty = randomBetween(1, 10)
    end
    activeFishings[player:getName()] = { pos = toPosition, fishingRod = item, loot = finalLoot }
    local msg = M.compose_message("fishing_start", {difficulty=difficulty, pos=string.format("%d,%d,%d", toPosition.x, toPosition.y, toPosition.z)})
    print("TX: " .. msg)
    player:sendExtendedOpcode(OPCODE_FISHING, msg)
    return true
end