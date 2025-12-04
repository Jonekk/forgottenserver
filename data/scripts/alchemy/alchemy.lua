
Alchemy = Alchemy or {kettles = {}}

-- local A = require("backend/alchemy")
function Alchemy:removeKettle(kettleToRemove)
    for i, kettle in ipairs(Alchemy.kettles) do
        if kettle == kettleToRemove then
            table.remove(Alchemy.kettles, i)
            return true  -- Found and removed
        end
    end
    return false  -- Not found
end

function Alchemy:getKettle(pos, player)
    -- return if exist
    for _, kettle in ipairs(Alchemy.kettles) do
        if kettle.pos == pos and kettle.player == player then
            return kettle
        end
    end

    -- create if doesnt exist
    local newKettle = AlchemyBackend.Kettle.new(pos, player)
    table.insert(Alchemy.kettles, newKettle)
    return newKettle
end

function Alchemy:kettleOpen(pos, player, itemId)
    stepsList = ""
    local kettle = Alchemy:getKettle(pos, player)
    if not kettle then
        return false
    end
	for _, step in ipairs(kettle.steps) do
		print(step.action)
        local new_step = ""
        if step.action == "add" then
            -- todo
            --newStep = "add,26378,100,120;"
            --newKettleItem.def.clientId
            newStep = string.format("add,%d,%d,%d;", step.data.ingredient.def.clientId, step.data.ingredient.quality or 0, step.data.ingredient.purity or 0)
        elseif step.action == "stir" then
            local direction = ""
            if step.data == "right" then
                direction = "clockwise"
            elseif step.data == "left" then
                direction = "counterclockwise"
            end
            newStep = "stir," .. direction .. ";"
        elseif step.action == "boil" then
            local heat = step.data
            newStep = "boil," .. heat .. ";"
        else
            print("Unknown alchemy step: " .. step.action)
        end

        stepsList = stepsList .. newStep
	end
    return AlchemyNet:sendOpenKettle(player, pos, itemId, stepsList)
end

function Alchemy:kettleAddIngredient(player, kettle, ingredient)
    -- ingredient - pos, itemId, quality, purity
    local pos = ingredient.itemPos
    if bit.band(pos.y, 0x40) == 0 then
        print("Tried to add ingredient not from container")
        return false
    end
	local fromCid = bit.band(pos.y, 0x0F) 
	local parentContainer = player:getContainerById(fromCid);
    local slot = pos.z;
	local item = parentContainer:getItem(player:getContainerIndex(fromCid) + slot);
    if not item then
        print("Could not find item")
        return false
    end
    print("Item: ", item:getId())

    local newKettleItem = AlchemyBackend.createItem(item:getName(), item:getQuality(), item:getPurity())
    if not newKettleItem then
        print("Could not create item: ", item:getName())
        return false
    end
    if not kettle:add_ingredient(newKettleItem) then
        print("Could not add item to the kettle")
        return false
    end
    item:remove(1)

    local stepData = {step = "add", clientItemId = newKettleItem.def.clientId, quality = item:getQuality(), purity = item:getPurity()}
    AlchemyNet:sendStepResult(player, true, stepData)
end

function Alchemy:kettleStir(player, kettle, direction)
    local directionLocal = ""
    if direction == "clockwise" then
        directionLocal = "right"
    elseif direction == "counterclockwise" then
        directionLocal = "left"
    else
        return false
    end
    local ret = kettle:stir(directionLocal, heat)
    local stepData = {step = "stir", direction=direction}
    return AlchemyNet:sendStepResult(player, ret, stepData)
end

function Alchemy:kettleBoil(player, kettle, heat)
    local ret = kettle:boil(heat)
    local stepData = {step = "boil", heat = heat}
    AlchemyNet:sendStepResult(player, ret, stepData)
end

function Alchemy:kettleBrew(player, kettle)
    local result = kettle:end_brew()
    if not result then
        print("Brew gave no result")
        return false
    end

    print(result.success, result.type, result.potiontype, result.count, result.quality, result.text)
    if result.type == "potion" then
        alchemyResultPotion(player, kettle, result)
        kettle.pos:sendMagicEffect(CONST_ME_MAGIC_BLUE)
    elseif result.type == "explosion" then
        alchemyResultExplosion(player, kettle, result)
    elseif result.type == "poison" then
        alchemyResultPoison(player, kettle, result)
    elseif result.type == "nothing" then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, result.text)
    else
        print("Unknown brew result")
        return false
    end
    -- resolve recipe
    -- add item to user / execute effect

    AlchemyNet:sendBrewResult(player, kettle.pos, kettle.itemId, true)
    -- remove kettle from list
    self:removeKettle(kettle)
end