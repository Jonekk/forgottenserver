local function purityConst(herbalismLevel, min, max)
    return randomBetween(min, max)
end

local function purityHerbalismSimple(herbalismLevel, min, max)
    return math.min(randomBetween(min + herbalismLevel, max + herbalismLevel), 100)
end


local HERBS_MAP = {
    [26427] = { product = 26428, skill_tries = 2, maxChancePerOne=75, chanceBase = 50, chancePerHerbalismLevel = 10, purityFun = purityHerbalismSimple, purityArg1 = 50, purityArg2 = 90}
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
    return true
end