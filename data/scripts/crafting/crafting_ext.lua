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
local function buildRecipesLines()
  local lines = {}
    --if not eligible(player, r, station) then return end
    --if search and search ~= "" then
    --  -- very cheap name filter
    --  local name = itemName(id):lower()
    --  if not name:find(search:lower(), 1, true) then return end
    --end

  for id, r in pairs(CRAFT.recipes) do
    lines[#lines+1] = serializeRecipe(id, r)
  end

  table.sort(lines) -- deterministic
  return lines
end

translationLinesCache = nil
local function buildLegend()
  if translationLinesCache then
    return translationLinesCache
  end
  translationLinesCache = ""

  local uniqueItems = {}
  for id, r in pairs(CRAFT.recipes) do
    if not table.contains(uniqueItems, id) then
      table.insert(uniqueItems, id)
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
    print("legend", serverId, clientId, itemName)
    translationLinesCache = translationLinesCache .. string.format("%d;%d;%s\n", serverId, clientId, itemName)
  end
  return translationLinesCache
end

materialsListCache = nil

local function buildPlayerState(player)
  local playerState = string.format("CRAFTLVL:%d;", 1)

  -- materials list
  if materialsListCache == nil then
    materialsListCache = {}
    for id, r in pairs(CRAFT.recipes) do
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
    print("player_state", serverId, itemCount)
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

  local header = string.format("MSG:%s\nVER:%d;PAGE:%d/%d", msgid, CRAFT.version, page, totalPages)
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

  player:sendExtendedOpcode(OP_CRAFT, table.concat(buf, "\n"))
end

-- Tiny parser for "key=value" tokens in a command line
local function token(line, key, default)
  return (line:match(key .. "=([^%s]+)") or default or "")
end

function craftingOnExtendedOpcode(player, opcode, buffer)
  if opcode ~= OP_CRAFT then return true end

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
    local id = tonumber(token(buffer, "id", "-1")) or -1
    local r = CRAFT.recipes[id]
    if not r or not eligible(player, r) then
      player:sendExtendedOpcode(OP_CRAFT, "ERR not_eligible")
      return true
    end

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

    local outCount = r.outputCount or 1
    player:addItem(id, outCount)
    player:sendExtendedOpcode(OP_CRAFT, ("DONE id=%d"):format(id))
    return true
  elseif verb == "legend" then
    local legendBuf = buildLegend()
    player:sendExtendedOpcode(OP_CRAFT, "MSG:legend\n" .. legendBuf)
    return true
  elseif verb == "player_state" then
    local playerStateBuf = buildPlayerState(player)
    player:sendExtendedOpcode(OP_CRAFT, "MSG:player_state\n" .. playerStateBuf)
    return true
  else
    player:sendExtendedOpcode(OP_CRAFT, "ERR unknown_cmd")
    return true
  end
end
