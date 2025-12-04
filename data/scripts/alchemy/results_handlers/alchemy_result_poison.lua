function onGetFormulaValues(player, level, magicLevel)
    player:addHealth(-math.random(1, 10), COMBAT_POISONDAMAGE)
    player:addDamageCondition(nil, CONDITION_POISON, DAMAGELIST_LOGARITHMIC_DAMAGE, math.random(1, 3))
	return -math.random(1, 10)
end

local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_POISONDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_GREEN_RINGS)
combat:setArea(createCombatArea(AREA_SQUARE1X1))
combat:setCallback(CALLBACK_PARAM_LEVELMAGICVALUE, "onGetFormulaValues")

function alchemyResultPoison(player, kettle, resultData)
    combat:execute(player, positionToVariant(kettle.pos))
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, resultData.text)
end