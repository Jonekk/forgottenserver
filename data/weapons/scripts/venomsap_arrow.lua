local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_PHYSICALDAMAGE)
combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_POISONARROW)
combat:setParameter(COMBAT_PARAM_BLOCKARMOR, true)
combat:setFormula(COMBAT_FORMULA_SKILL, 0, 0, 1, 0)

function onUseWeapon(item, player, variant)
	if not combat:execute(player, variant) then
		return false
	end
	local quality = item:getQuality()
	local totalDamage = gaussianRandom20p(20 * (1.3 * quality / 100))

	local damageTick = 1
	local period = 2
	if totalDamage >= 20 then
		damageTick = 2
		period = 3
	end
	if totalDamage >= 30 then
		damageTick = 3
		period = 3.5
	end
	if totalDamage >= 40 then
		damageTick = 4
		period = 4
	end
	local rounds = math.floor(totalDamage / damageTick)
	print("damageTick", damageTick, "period", period, "rounds", rounds)
	player:addDamageCondition(Creature(variant:getNumber()), CONDITION_POISON, DAMAGELIST_CONSTANT_PERIOD, damageTick, period, rounds)
	return true
end
