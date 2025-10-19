function deepCopy(original)
    if type(original) ~= "table" then return original end  -- Return non-tables as-is
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = deepCopy(value)  -- Recursively copy nested tables
    end
    return copy
end