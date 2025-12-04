local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_PHYSICALDAMAGE)
combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_BURSTARROW)
combat:setParameter(COMBAT_PARAM_BLOCKARMOR, true)
combat:setFormula(COMBAT_FORMULA_SKILL, 0, 0, 1, 0)

function onUseWeapon(item, player, variant)
	if not combat:execute(player, variant) then
		return false
	end
	local quality = item:getQuality()

	local chance = 50 * (1 + (quality / (4 * 100)))
	if randomChance(chance) then
		local finalSpeed =  100 * (300 - quality) / 300
		local time = math.max(3, 5 * (quality / 100))
		local condition = Condition(CONDITION_PARALYZE)
		condition:setParameter(CONDITION_PARAM_TICKS, time * 1000)
		condition:setFormula(-1, finalSpeed, -1, finalSpeed)
		local targetCreature = Creature(variant:getNumber())
		if targetCreature then
			 local ret = targetCreature:addCondition(condition)
			 print("adding condition:", ret)
		end
	end
	return true
end


local combat = Combat()
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_MAGIC_RED)



function onCastSpell(creature, variant, isHotkey)
	if not combat:execute(creature, variant) then
		return false
	end

	creature:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	return true
end
