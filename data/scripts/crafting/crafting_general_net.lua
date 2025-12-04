local OP_CRAFT = 120

local recipesCache = nil
local legendCache = nil
local materialsListCache = nil

local function buildPlayerState(player)
  local playerState = string.format("craftlvl:%d\n", player:getSkillLevel(SKILL_CRAFTING))
  if not materialsListCache then
    materialsListCache = getMaterialList(CRAFTING_GENERAL.recipes)
  end
  playerState = playerState .. getPlayerMaterialList(player, materialsListCache)

  return playerState
end

-- Tiny parser for "key=value" tokens in a command line
local function token(line, key, default)
  return (line:match(key .. "=([^%s]+)") or default or "")
end

function craftingGeneralOnExtendedOpcode(player, opcode, buffer)
  if opcode ~= OP_CRAFT then return true end
  print("RX: ", opcode, buffer)

  local verb = buffer:match("^(%S+)")
  if verb == "recipes" then
    local page     = tonumber(token(buffer, "page", "1")) or 1
    local per      = tonumber(token(buffer, "per", "200")) or 200
    if per < 10 then per = 10 end
    if per > 1000 then per = 1000 end

    if not recipesCache then
      recipesCache = buildRecipesLines(CRAFTING_GENERAL.recipes)
    end
    sendPaged(player, OP_CRAFT, "recipes", recipesCache, page, per)
    return true
  elseif verb == "legend" then
    if not legendCache then
      legendCache = buildLegend(CRAFTING_GENERAL.recipes)
    end
    player:sendExtendedOpcode(OP_CRAFT, "legend\n" .. legendCache)
    return true
  elseif verb == "player_state" then
    local playerStateBuf = buildPlayerState(player)
    player:sendExtendedOpcode(OP_CRAFT, "player_state\n" .. playerStateBuf)
    return true
  elseif verb == "craft" then
    local recipeId = token(buffer, "recipeId", "")
    local grade = tonumber(token(buffer, "grade", "-1")) or -1
    local count = tonumber(token(buffer, "count", "-1")) or -1
    local success = craft_general(player, recipeId, grade, count)

    local successStr = success and '1' or '0'
    player:sendExtendedOpcode(OP_CRAFT, string.format("craft\nrecipeId=%s success=%d", recipeId, successStr))
    return true
  else
    player:sendExtendedOpcode(OP_CRAFT, "ERR unknown_cmd")
    return true
  end
end
