local OP_CRAFT = 120
local MAX_PACKET_BYTES = 60000 -- stay well below protocol max

-- Optional: resolve a readable name; safe on modern TFS
local function itemName(id)
  local it = ItemType(id)
  if it and it:getName() and it:getName() ~= "" then return it:getName() end
  return tostring(id)
end

-- Eligibility checks (adjust to your rules)
local function eligible(player, recipe)
  local req = recipe or {}
  if req.levelRequired and player:getLevel() < req.levelRequired then return false end
  if req.req and req.req.level and player:getLevel() < req.req.level then return false end
  return true
end

-- Build filtered list of lines (no pagination yet)
-- TODO cache that
local function buildRecipesLines()
  local lines = {}
    --if not eligible(player, r, station) then return end
    --if search and search ~= "" then
    --  -- very cheap name filter
    --  local name = itemName(id):lower()
    --  if not name:find(search:lower(), 1, true) then return end
    --end

  for _, recipe in ipairs(CRAFTING_GENERAL.recipes) do
    lines[#lines+1] = serializeRecipe(recipe)
  end
  --for _, r in ipairs(CRAFT.simpleRecipes) do
  --  r.simple = true
  --  lines[#lines+1] = serializeRecipe(r.itemId, r)
  --end

  -- sort by required level (ascending in difficulty)
  table.sort(lines, function(a, b)
    local a3 = tonumber(a:match("^[^;]+;[^;]+;([^;]+)"))
    local b3 = tonumber(b:match("^[^;]+;[^;]+;([^;]+)"))
    return a3 < b3
  end)
  return lines
end

translationLinesCache = nil
local function buildLegend()
  if translationLinesCache then
    return translationLinesCache
  end
  translationLinesCache = ""

  local uniqueItems = {}
  for _, r in ipairs(CRAFTING_GENERAL.recipes) do
    if not table.contains(uniqueItems, r.itemId) then
      table.insert(uniqueItems, r.itemId)
    end
    for matId, matInfo in pairs(r.materials) do
      if not table.contains(uniqueItems, matId) then
        table.insert(uniqueItems, matId)
      end
    end
  end

  for _, itemId in ipairs(uniqueItems) do
    local serverId = itemId
    local it = ItemType(itemId)
    local clientId = it:getClientId()
    local itemName = it:getName()
    translationLinesCache = translationLinesCache .. string.format("%d;%d;%s\n", serverId, clientId, itemName)
  end
  return translationLinesCache
end

materialsListCache = nil

local function buildPlayerState(player)
  local playerState = string.format("craftlvl:%d\n", player:getSkillLevel(SKILL_CRAFTING))

  -- materials list
  if materialsListCache == nil then
    materialsListCache = {}
    for id, r in pairs(CRAFTING_GENERAL.recipes) do
      for matId, matInfo in pairs(r.materials) do
        if not table.contains(materialsListCache, matId) then
          table.insert(materialsListCache, matId)
        end
      end
    end
  end
  
  for _, itemId in ipairs(materialsListCache) do
    local serverId = itemId
    local itemCount = player:getItemCount(itemId)
    playerState = playerState .. string.format("%d;%d\n", serverId, itemCount)
  end
  return playerState
end

-- Send one page, ensuring payload stays below MAX_PACKET_BYTES
local function sendPaged(player, msgid, lines, page, per)
  local totalPages = math.max(1, math.ceil(#lines / per))
  page = math.max(1, math.min(page, totalPages))

  local from = (page - 1) * per + 1
  local to   = math.min(#lines, page * per)

  local header = string.format("%s\nPAGE:%d/%d", msgid, page, totalPages)
  local buf = { header }
  local size = #header + 1

  for i = from, to do
    local ln = lines[i]
    local add = #ln + 1
    if size + add > MAX_PACKET_BYTES then
      -- stop early if this packet would exceed safe size
      break
    end
    buf[#buf+1] = ln
    size = size + add
  end
  print("TX:\n", table.concat(buf, "\n"))
  player:sendExtendedOpcode(OP_CRAFT, table.concat(buf, "\n"))
end

-- Tiny parser for "key=value" tokens in a command line
local function token(line, key, default)
  return (line:match(key .. "=([^%s]+)") or default or "")
end

function craftingOnExtendedOpcode(player, opcode, buffer)
  if opcode ~= OP_CRAFT then return true end
  print("RX: ", buffer)

  local verb = buffer:match("^(%S+)")
  if verb == "recipes" then
    --local station  = token(buffer, "station", "")
    --local category = token(buffer, "tag", "")       -- you used `tag` on the client; map to category
    --local search   = token(buffer, "search", "")
    local page     = tonumber(token(buffer, "page", "1")) or 1
    local per      = tonumber(token(buffer, "per", "200")) or 200
    if per < 10 then per = 10 end
    if per > 1000 then per = 1000 end

    local lines = buildRecipesLines()
    sendPaged(player, "recipes", lines, page, per)
    return true
  elseif verb == "craft" then
    local recipeId = token(buffer, "recipeId", "")
    local grade = tonumber(token(buffer, "grade", "-1")) or -1
    local count = tonumber(token(buffer, "count", "-1")) or -1
    local r = CRAFTING_GENERAL.recipes[id]
    local success = craft_general(player, recipeId, grade, count)

    -- TODO: enforce ingredients & stamina, capacity, etc. (example skeleton):
    -- for mid, data in pairs(r.materials or {}) do
    --   if player:getItemCount(mid) < (data.count or 1) then
    --     player:sendExtendedOpcode(OP_CRAFT, "ERR not_enough_materials")
    --     return true
    --   end
    -- end
    -- for mid, data in pairs(r.materials or {}) do
    --   player:removeItem(mid, data.count or 1)
    -- end
    local successStr = success and '1' or '0'
    player:sendExtendedOpcode(OP_CRAFT, string.format("craft\nrecipeId=%s success=%d", recipeId, successStr))
    return true
  elseif verb == "legend" then
    local legendBuf = buildLegend()
    player:sendExtendedOpcode(OP_CRAFT, "legend\n" .. legendBuf)
    return true
  elseif verb == "player_state" then
    local playerStateBuf = buildPlayerState(player)
    player:sendExtendedOpcode(OP_CRAFT, "player_state\n" .. playerStateBuf)
    return true
  else
    player:sendExtendedOpcode(OP_CRAFT, "ERR unknown_cmd")
    return true
  end
end
