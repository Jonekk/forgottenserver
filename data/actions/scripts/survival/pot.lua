function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    item:transform(1421)
    local tile = item:getTile()
    local potItem = tile:addItem(2562, 0)
    item:transform(item:getId())
end