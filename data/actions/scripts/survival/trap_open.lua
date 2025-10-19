local config = {
    [26422] = { closedTrapId = 26421 }
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local cfg = config[item:getId()]
    if not cfg then
        return false
    end
    local itemId = item:getId()
    item:transform(cfg.closedTrapId)
    return true
end
