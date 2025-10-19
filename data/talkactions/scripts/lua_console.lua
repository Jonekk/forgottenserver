-- Runs arbitrary Lua on the SERVER. Restrict to GODs only.
-- Usage: /lua Game.setWorldLight(30)
local function reply(player, msg)
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
  end
  
function onSay(player, words, param)
    print("aaa")
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "I got message")
    -- allow only high-privilege accounts
    -- local group = player:getGroup()
    -- if not player:getGroup():getAccess() then
	-- 	return true
	-- end

	-- if player:getAccountType() < ACCOUNT_TYPE_GAMEMASTER then
	-- 	return false
	-- end
  
    if not param or param == "" then
      reply(player, "Usage: /lua <code>")
      return false
    end
  
    -- Try to evaluate as an expression first, then as a statement
    local chunk, err
    -- Lua 5.2+: load; Lua 5.1: loadstring
    local loader = load or loadstring
  
    -- expression: prefix "return " to show results
    chunk, err = loader("return (" .. param .. ")", "=(/lua expr)", "t", _G)
    if not chunk then
      -- statement (no return value)
      chunk, err = loader(param, "=(/lua stmt)", "t", _G)
      if not chunk then
        reply(player, "Lua error: " .. err)
        return false
      end
    end
  
    local ok, res = pcall(chunk)
    if not ok then
      reply(player, "Runtime error: " .. tostring(res))
    else
      if res ~= nil then
        reply(player, "Result: " .. tostring(res))
      else
        reply(player, "OK")
      end
    end
    return false -- don’t broadcast to chat
end
  