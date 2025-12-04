local function purityConst(herbalismLevel, min, max)
    return randomBetween(min, max)
end

local function purityHerbalismSimple(herbalismLevel, min, max)
    return math.min(randomBetween(min + herbalismLevel, max + herbalismLevel), 100)
end

-- enum {
    MONSTER_SNAKE = 1
    MONSTER_WASP = 2
    BLOODHIT = 3
    POISON = 4
    PARALYZE = 5
-- } enum

local function handleAdditionalEvents(alternativeEvents, player, position)
    for event, eventInfo in pairs(alternativeEvents) do
        local chance = eventInfo.ch
        print(event, chance)
        if (randomChance(chance)) then
            if event == MONSTER_SNAKE or event == MONSTER_WASP then
                local monsterId = event == MONSTER_SNAKE and "Snake" or (MONSTER_WASP and "Wasp" or nil)
                local spawnMonster = Game.createMonster(monsterId, position, true, true)
                spawnMonster:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
            elseif event == BLOODHIT then
                doTargetCombat(0, player, COMBAT_PHYSICALDAMAGE, -1, -5, CONST_ME_NONE, true, false, false)
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You hurt yourself during gathering.")
            elseif event == POISON then
                local poison = Condition(CONDITION_POISON)
                poison:setParameter(CONDITION_PARAM_DELAYED, true)
                poison:setParameter(CONDITION_PARAM_MINVALUE, -3)
                poison:setParameter(CONDITION_PARAM_MAXVALUE, -10)
                poison:setParameter(CONDITION_PARAM_STARTVALUE, -3)
                poison:setParameter(CONDITION_PARAM_TICKINTERVAL, 4000)
                poison:setParameter(CONDITION_PARAM_FORCEUPDATE, true)
                player:addCondition(poison)
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The herb you tried to gether seems to be poisonous.")
            elseif event == PARALYZE then
                local paralyze = Condition(CONDITION_PARALYZE)
                paralyze:setParameter(CONDITION_PARAM_TICKS, 20000)
                paralyze:setFormula(-1, 80, -1, 80)
                player:addCondition(paralyze)
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You cut yourself on the herb, your body feels a bit numb")
            end
        end
    end
end

local HERBS_MAP = {
    [26427] = { product = 26428, skill_tries = 2, maxChancePerOne=75, chanceBase = 50, chancePerHerbalismLevel = 10, purityFun = purityHerbalismSimple, purityArg1 = 50, purityArg2 = 90, aEv={[MONSTER_SNAKE] = {ch=2}, [MONSTER_WASP] = {ch=2}, [BLOODHIT] = {ch=1}}},
    [26430] = { product = 26431, skill_tries = 2, maxChancePerOne=75, chanceBase = 50, chancePerHerbalismLevel = 10, purityFun = purityHerbalismSimple, purityArg1 = 50, purityArg2 = 90, aEv={[MONSTER_SNAKE] = {ch=2}, [MONSTER_WASP] = {ch=2}, [BLOODHIT] = {ch=1}}},
    [26432] = { product = 26433, skill_tries = 2, maxChancePerOne=75, chanceBase = 50, chancePerHerbalismLevel = 10, purityFun = purityHerbalismSimple, purityArg1 = 50, purityArg2 = 90, aEv={[MONSTER_SNAKE] = {ch=2}, [MONSTER_WASP] = {ch=2}, [BLOODHIT] = {ch=1}}},
    [26434] = { product = 26435, skill_tries = 2, maxChancePerOne=75, chanceBase = 50, chancePerHerbalismLevel = 10, purityFun = purityHerbalismSimple, purityArg1 = 50, purityArg2 = 90, aEv={[MONSTER_SNAKE] = {ch=2}, [MONSTER_WASP] = {ch=2}, [BLOODHIT] = {ch=1}}},
    [26436] = { product = 26437, skill_tries = 2, maxChancePerOne=75, chanceBase = 50, chancePerHerbalismLevel = 10, purityFun = purityHerbalismSimple, purityArg1 = 50, purityArg2 = 90, aEv={[MONSTER_SNAKE] = {ch=2}, [MONSTER_WASP] = {ch=2}, [BLOODHIT] = {ch=1}}},
    [26438] = { product = 26439, skill_tries = 2, maxChancePerOne=75, chanceBase = 50, chancePerHerbalismLevel = 10, purityFun = purityHerbalismSimple, purityArg1 = 50, purityArg2 = 90, aEv={[MONSTER_SNAKE] = {ch=2}, [MONSTER_WASP] = {ch=2}, [BLOODHIT] = {ch=1}, [POISON] = {ch=2}}},
    [26440] = { product = 26441, skill_tries = 2, maxChancePerOne=75, chanceBase = 50, chancePerHerbalismLevel = 10, purityFun = purityHerbalismSimple, purityArg1 = 50, purityArg2 = 90, aEv={[MONSTER_SNAKE] = {ch=2}, [MONSTER_WASP] = {ch=2}, [BLOODHIT] = {ch=1}, [POISON] = {ch=10}}},
    [26442] = { product = 26443, skill_tries = 2, maxChancePerOne=75, chanceBase = 50, chancePerHerbalismLevel = 10, purityFun = purityHerbalismSimple, purityArg1 = 50, purityArg2 = 90, aEv={[BLOODHIT] = {ch=1}, [PARALYZE] = {ch=5}}},
}
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local herbInfo = HERBS_MAP[item:getId()]
    if not herbInfo then
        print("no herbInfo")
        return
    end

    local itemsToGet = 0
    local totalChance = herbInfo.chanceBase + player:getSkillLevel(SKILL_HERBALISM) * herbInfo.chancePerHerbalismLevel
    while totalChance > 0 do
        local chanceSingle = math.min(totalChance, herbInfo.maxChancePerOne)
        print("chance: " .. chanceSingle .. "/" .. totalChance)
        if randomChance(chanceSingle) then
            itemsToGet = itemsToGet + 1
        end
        totalChance = totalChance - chanceSingle
    end
    if itemsToGet > 0 then
        local productItem = player:addItem(herbInfo.product, itemsToGet)
        productItem:setQuality(item:getQuality())
        local purity = herbInfo.purityFun(player:getSkillLevel(SKILL_HERBALISM), herbInfo.purityArg1, herbInfo.purityArg2)
        productItem:setCustomAttribute("Purity", purity)
        toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
    else
        toPosition:sendMagicEffect(CONST_ME_POFF)
    end
    player:addSkillTries(SKILL_HERBALISM, herbInfo.skill_tries)
    item:remove(1)
    handleAdditionalEvents(herbInfo.aEv, player, toPosition)
    return true
end