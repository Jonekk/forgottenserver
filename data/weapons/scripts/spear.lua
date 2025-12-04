local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_PHYSICALDAMAGE)
combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_SPEAR)
combat:setParameter(COMBAT_PARAM_BLOCKARMOR, true)
combat:setFormula(COMBAT_FORMULA_SKILL, 0, 0, 1, 0)

function onUseWeapon(item, player, variant)
	if not combat:execute(player, variant) then
		return false
	end

    local tile = nil
	local targetCreature = Creature(variant:getNumber())
    if targetCreature then
        tile = targetCreature:getTile()
    else
        tile = Tile(variant:getPosition())
    end
    local splititem = item:split(1)
    splititem:moveTo(tile)

	return true
end
