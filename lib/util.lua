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

---Thank you `u/Serious-Accident8443`!
---@param value any
---@param cases table
---@return any
function util.switch(value, cases)
    local match = cases[value] or cases.default or function() end
    return match()
end

---@overload fun(func)
---@param func function
---@param initialValue any
function util.onChange(func, initialValue)
    ---@class onChange
    local interface = {}
    
    local oldValue = initialValue or nil

    function interface:check(value)
        if oldValue ~= value then
            func(value)
        end
        oldValue = value
        return interface
    end

    return interface
end

return util