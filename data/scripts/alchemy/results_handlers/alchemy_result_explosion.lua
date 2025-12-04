function onGetFormulaValues(player, level, magicLevel)
    player:addHealth(-math.random(1, 10), COMBAT_FIREDAMAGE)
	return -math.random(1, 10)
end

local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_EXPLOSIONHIT)
combat:setArea(createCombatArea(AREA_SQUARE1X1))
combat:setCallback(CALLBACK_PARAM_LEVELMAGICVALUE, "onGetFormulaValues")

function alchemyResultExplosion(player, kettle, resultData)
    combat:execute(player, positionToVariant(kettle.pos))
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, resultData.text)
end