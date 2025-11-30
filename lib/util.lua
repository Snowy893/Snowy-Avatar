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
---@return OnChange
function util.onChange(func, initialValue)
    ---@class OnChange
    local interface = {}
    
    local oldValue = initialValue or nil
    local extraArg

    function interface.setExtraArg(value)
        extraArg = value
        return interface
    end

    ---@overload fun(value)
    ---@param value any
    function interface.check(value)
        if oldValue ~= value then
            func(value, oldValue, extraArg)
        end
        oldValue = value
    end

    return interface
end

return util