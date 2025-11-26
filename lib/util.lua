---@class util
local util = {}

---@param tbl table
---@param value any
function util.contains(tbl, value)
    for _, v in pairs(tbl) do
        if value == v then return true end
    end
    return false
end

---@overload fun(tbl, func)
---@param tbl table
---@param func function
---@param excludeTables boolean
function util.deepLoop(tbl, func, excludeTables)
    if excludeTables == nil then excludeTables = true end
    for _, v in pairs(tbl) do
        if type(v) == "table" then
            if not excludeTables then func(v) end
            util.deepLoop(v, func)
        else
            func(v)
        end
    end
end

return util