-- generic_messages.lua
-- Parsing & composing messages of the form:
-- 1) cmd=<command>\nkey1=value1 key2=value2 ...
-- 2) same as 1), optionally followed by:
--    table:\n<row1>\n<row2>\n...
--
-- Supports spaces in values via quotes ("value with spaces" or 'value with spaces')
-- and backslash escaping (value\ with\ spaces). Also preserves token order.

M = {}

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function unescape(s)
  -- turn sequences like \" \\ \n \t \  (space) back into their characters
  -- Only used for quoted strings and backslash-escaped unquoted values.
  local map = { n = "\n", r = "\r", t = "\t" }
  return (s:gsub("\\([\\\"'%snt])", function(ch)
    if ch == " " then return " " end
    return map[ch] or ch
  end))
end

local function parse_cmd_and_tokens(headerLine)
  -- headerLine looks like: cmd=<command> [tokens...]
  -- We allow arbitrary whitespace around pieces.
  headerLine = trim(headerLine)

  -- Extract cmd=...
  local cmd
  do
    -- cmd=<anything until space>, but allow quotes/escapes in command too
    -- We'll scan manually to find first token and ensure it's cmd=
    local i = 1
    local len = #headerLine
    -- read first token (respecting quotes)
    local function read_token(pos)
      local buf = {}
      local in_quote = nil
      while pos <= len do
        local ch = headerLine:sub(pos, pos)
        if in_quote then
          if ch == "\\" then
            if pos < len then
              local nxt = headerLine:sub(pos + 1, pos + 1)
              table.insert(buf, ch .. nxt)
              pos = pos + 2
            else
              table.insert(buf, ch)
              pos = pos + 1
            end
          elseif ch == in_quote then
            table.insert(buf, ch)
            pos = pos + 1
            in_quote = nil
          else
            table.insert(buf, ch)
            pos = pos + 1
          end
        else
          if ch == '"' or ch == "'" then
            in_quote = ch
            table.insert(buf, ch)
            pos = pos + 1
          elseif ch:match("%s") then
            break
          else
            table.insert(buf, ch)
            pos = pos + 1
          end
        end
      end
      return table.concat(buf), pos
    end

    local first, pos = read_token(1)
    if not first or first == "" then
      return nil, "Missing header (cmd=...)"
    end

    -- Ensure it starts with cmd=
    local eq = first:find("^cmd=")
    if not eq then
      return nil, "Header must start with cmd=<command>"
    end

    local rawCmd = first:sub(5) -- after "cmd="
    rawCmd = trim(rawCmd)

    -- If command is quoted, strip quotes & unescape.
    if rawCmd:match('^".*"$') or rawCmd:match("^'.*'$") then
      local q = rawCmd:sub(1,1)
      rawCmd = rawCmd:sub(2, -2)
      rawCmd = unescape(rawCmd)
      cmd = rawCmd
    else
      -- unquoted; also allow backslash escapes
      cmd = unescape(rawCmd)
    end

    -- Remaining substring after first token is the tokens part
    headerLine = headerLine:sub(pos)
  end

  -- Tokenize key=value pairs (order preserving)
  local tokens_ordered = {}  -- { {k=..., v=...}, ... }
  local tokens_map = {}      -- { key = value }

  local s = trim(headerLine)
  local i, len = 1, #s

  local function read_key(pos)
    local buf = {}
    while pos <= len do
      local ch = s:sub(pos,pos)
      if ch == "=" then
        break
      elseif ch:match("%s") then
        -- keys cannot contain spaces; if space before '=', it's malformed
        break
      else
        table.insert(buf, ch)
        pos = pos + 1
      end
    end
    return table.concat(buf), pos
  end

  local function skip_spaces(pos)
    while pos <= len and s:sub(pos,pos):match("%s") do
      pos = pos + 1
    end
    return pos
  end

  local function read_value(pos)
    pos = skip_spaces(pos)
    if pos > len then return "", pos end

    local ch = s:sub(pos,pos)
    local value
    if ch == '"' or ch == "'" then
      -- Quoted value
      local q = ch
      pos = pos + 1
      local buf = {}
      while pos <= len do
        local c = s:sub(pos,pos)
        if c == "\\" then
          if pos < len then
            local nxt = s:sub(pos+1,pos+1)
            table.insert(buf, "\\" .. nxt)
            pos = pos + 2
          else
            table.insert(buf, "\\")
            pos = pos + 1
          end
        elseif c == q then
          pos = pos + 1
          break
        else
          table.insert(buf, c)
          pos = pos + 1
        end
      end
      value = unescape(table.concat(buf))
    else
      -- Unquoted value: read until space; allow backslash-escaped spaces
      local buf = {}
      while pos <= len do
        local c = s:sub(pos,pos)
        if c == "\\" then
          if pos < len then
            local nxt = s:sub(pos+1,pos+1)
            -- keep the escape; unescape later
            table.insert(buf, "\\" .. nxt)
            pos = pos + 2
          else
            table.insert(buf, "\\")
            pos = pos + 1
          end
        elseif c:match("%s") then
          break
        else
          table.insert(buf, c)
          pos = pos + 1
        end
      end
      value = unescape(table.concat(buf))
    end
    return value, pos
  end

  local pos = 1
  while true do
    pos = skip_spaces(pos)
    if pos > len then break end

    local key, afterKey = read_key(pos)
    if key == "" then
      -- skip junk or stop to avoid infinite loop
      break
    end
    pos = afterKey

    if s:sub(pos,pos) ~= "=" then
      -- malformed key without '='; try to recover by skipping token-like chunk
      while pos <= len and not s:sub(pos,pos):match("%s") do pos = pos + 1 end
    else
      pos = pos + 1 -- skip '='
      local val
      val, pos = read_value(pos)
      tokens_map[key] = val
      table.insert(tokens_ordered, { k = key, v = val })
    end
  end

  return {
    cmd = cmd,
    tokens = tokens_map,
    tokens_ordered = tokens_ordered
  }
end

--- Parse full message (header + optional table)
-- @param text string
-- @return tbl with fields:
--   cmd: string
--   tokens: map
--   tokens_ordered: array of {k,v}
--   table_rows: array of strings (may be empty)
--   raw_header: original header line
--   has_table: boolean
function M.parse_message(text)
  if type(text) ~= "string" then
    return nil, "input must be a string"
  end

  -- Normalize newlines
  text = text:gsub("\r\n", "\n"):gsub("\r", "\n")

  -- Split into lines
  local firstNL = text:find("\n", 1, true)
  local header, rest
  if firstNL then
    header = text:sub(1, firstNL - 1)
    rest   = text:sub(firstNL + 1)
  else
    header = text
    rest   = ""
  end

  local head, err = parse_cmd_and_tokens(header)
  if not head then
    return nil, err
  end

  -- Check for optional "table:" block
  local rows = {}
  local has_table = false
  if rest and rest ~= "" then
    -- Allow leading blank lines before "table:"
    local trimmedRest = trim(rest)
    if trimmedRest:sub(1, 6):lower() == "table:" then
      has_table = true
      local after = trimmedRest:sub(7) -- after "table:"
      -- Strip a single leading newline if present
      if after:sub(1,1) == "\n" then after = after:sub(2) end
      -- Split by \n (keep empty rows if user wants explicit blanks)
      for row in (after .. "\n"):gmatch("([^\n]*)\n") do
        -- do not trim rows; keep as-is
        table.insert(rows, row)
      end
      -- Remove possible last empty due to trailing newline (optional)
      if #rows > 0 and rows[#rows] == "" then
        table.remove(rows, #rows)
      end
    end
  end

  head.table_rows = rows
  head.has_table  = has_table
  head.raw_header = header
  return head
end

-- Compose a header + optional table from cmd + tokens
-- tokens can be:
--   - map table {k=v, ...} (order not guaranteed)
--   - or an array of {k=..., v=...} to preserve order
-- table_rows is an array of strings
local function needs_quotes(v)
  -- quote if contains spaces or tabs or is empty
  return v == "" or v:find("[%s]") ~= nil
end

local function escape_for_unquoted(v)
  -- Escape spaces and backslashes minimally for unquoted use
  local out = v:gsub("\\", "\\\\")
  out = out:gsub(" ", "\\ ")
  out = out:gsub("\t", "\\t")
  out = out:gsub("\n", "\\n")
  out = out:gsub("\r", "\\r")
  return out
end

local function escape_for_quotes(v, quote_char)
  -- Escape backslash, the quote char, and common controls
  local out = v:gsub("\\", "\\\\")
  if quote_char == '"' then
    out = out:gsub('"', '\\"')
  elseif quote_char == "'" then
    out = out:gsub("'", "\\'")
  end
  out = out:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
  return out
end

local function tokens_iter(tokens)
  -- Returns an iterator over {k, v} preserving order if tokens is an array.
  if #tokens > 0 and tokens[1] and type(tokens[1]) == "table" and tokens[1].k then
    local i = 0
    return function()
      i = i + 1
      local t = tokens[i]
      if t then return t.k, t.v end
    end
  else
    -- map iteration (order not guaranteed)
    local iter, tbl, key = pairs(tokens)
    return function()
      key = iter(tbl, key)
      if key ~= nil then return key, tokens[key] end
    end
  end
end

function M.compose_message(cmd, tokens, table_rows)
  if type(cmd) ~= "string" or cmd == "" then
    return nil, "cmd must be a non-empty string"
  end
  tokens = tokens or {}
  table_rows = table_rows or {}

  -- render cmd
  local parts = {}

  local function render_value(v)
    v = tostring(v)
    if needs_quotes(v) then
      -- prefer double quotes unless it contains them
      local quote = '"'
      if v:find('"', 1, true) and not v:find("'", 1, true) then
        quote = "'"
      end
      return quote .. escape_for_quotes(v, quote) .. quote
    else
      return escape_for_unquoted(v)
    end
  end

  table.insert(parts, "cmd=" .. render_value(cmd))

  for k, v in tokens_iter(tokens) do
    if k ~= nil and v ~= nil then
      table.insert(parts, string.format("%s=%s", tostring(k), render_value(tostring(v))))
    end
  end

  local header = table.concat(parts, " ")
  if #table_rows == 0 then
    return header
  end

  -- Append table block
  local buf = { header, "table:" }
  for _, row in ipairs(table_rows) do
    table.insert(buf, tostring(row))
  end
  return table.concat(buf, "\n")
end
