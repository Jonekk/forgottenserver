MOVABLE_WITH_WORMS_CHANCE = 70
MOVABLE_WITH_WORMS_TIMEOUT = 60 * 1000
MOVABLE_WITH_WORMS = { 1293, 1295 }

function customOnPlayerMoveItem(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
    if item and table.contains(MOVABLE_WITH_WORMS, item:getId()) then
        local destroyedTime = item:getCustomAttribute("destroyedTime")
        if not destroyedTime or os:mtime() - destroyedTime > MOVABLE_WITH_WORMS_TIMEOUT then
            if MOVABLE_WITH_WORMS_CHANCE > math.random(100) then
                Game.createItem(3976, round(gaussianRandom50p(2)) - 1, fromPosition)
                fromPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
            end
        end
        item:setCustomAttribute("destroyedTime", os:mtime())
    end
end