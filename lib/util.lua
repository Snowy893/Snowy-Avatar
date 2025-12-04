---@class util
local util = {}

---@param tbl table
---@param value any
---@return boolean
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
function util:onChange(func, initialValue)
    ---@class OnChange
    local interface = {}

    local oldValue = initialValue or nil
    local extraArg

    ---@param value any
    function interface:setExtraParam(value)
        extraArg = value
        return interface
    end

    ---@param value any
    function interface:check(value)
        if oldValue ~= value then
            func(value, oldValue, extraArg)
        end
        oldValue = value
    end

    return interface
end

---@param fromPage Page
---@param toPage Page
---@param title string
---@param item? Minecraft.itemID
---@return Action
function util.switchPageAction(fromPage, toPage, title, item)
    return fromPage:newAction()
        :title(title)
        :item(item)
        :setOnLeftClick(function() action_wheel:setPage(toPage) end)
end

---@return boolean
function util.isRaining()
    local currentBiome
    local rainType
    local rainGradient = 0

    rainGradient = world.getRainGradient()
    currentBiome = world.getBiome(player:getPos())
    rainType = currentBiome.getPrecipitation(currentBiome)

    return rainGradient == 1 and rainType == "RAIN"
end

return util
