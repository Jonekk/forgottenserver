-- TODO: this file should be a class 

MAX_PACKET_BYTES = 60000

function sendPaged(player, opcode, msgid, lines, page, per)
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
    player:sendExtendedOpcode(opcode, table.concat(buf, "\n"))
end

function buildLegend(recipesList)
    local uniqueItems = {}
    for _, r in ipairs(recipesList) do
      if not table.contains(uniqueItems, r.itemId) then
        table.insert(uniqueItems, r.itemId)
      end
      for matId, matInfo in pairs(r.materials) do
        if not table.contains(uniqueItems, matId) then
          table.insert(uniqueItems, matId)
        end
      end
    end
    legendLines = ""
    for _, itemId in ipairs(uniqueItems) do
      local serverId = itemId
      local it = ItemType(itemId)
      local clientId = it:getClientId()
      local itemName = it:getName()
      legendLines = legendLines .. string.format("%d;%d;%s\n", serverId, clientId, itemName)
    end
    return legendLines
end

function getMaterialList(recipes)
    materialsList = {}
    for id, r in pairs(recipes) do
      for matId, matInfo in pairs(r.materials) do
        if not table.contains(materialsList, matId) then
          table.insert(materialsList, matId)
        end
      end
    end
    return materialsList
  end
  
function getPlayerMaterialList(player, materialList)
    materialListLines = ""
    for _, itemId in ipairs(materialList) do
        local serverId = itemId
        local itemCount = player:getItemCount(itemId)
        materialListLines = materialListLines .. string.format("%d;%d\n", serverId, itemCount)
    end
    return materialListLines
end

function buildRecipesLines(recipes)
    local lines = {}
    for _, recipe in ipairs(recipes) do
      lines[#lines+1] = serializeRecipe(recipe)
    end
    -- sort by required level (ascending in difficulty)
    table.sort(lines, function(a, b)
      local a3 = tonumber(a:match("^[^;]+;[^;]+;([^;]+)"))
      local b3 = tonumber(b:match("^[^;]+;[^;]+;([^;]+)"))
      return a3 < b3
    end)
    return lines
end