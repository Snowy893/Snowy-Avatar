---@class Util
local util = {}

---Returns an explicit boolean value out of a value that is truthy or falsy (and values I'd like to treat as falsy)
---@param value any
---@return boolean
function util.toboolean(value)
    if value then return true else return false end
end

---@param func fun(value, oldValue, ...)
---@param initialValue? any
---@return fun(value, ...)
function util.onchange(func, initialValue)
    local oldValue = initialValue
    return function(value, ...)
        if oldValue ~= value then
            func(value, oldValue, ...)
        end
        oldValue = value
    end
end

---@param tbl? function[]
---@param mtbl? table
---@return functiontable
function util.functiontable(tbl, mtbl)
    local t = tbl or {}
    local mt = mtbl or {}
    mt.__call = function(self, ...)
        for _, func in pairs(self) do func(...) end
    end
    ---@class functiontable
    return setmetatable(t, mt)
end

---Thanks `user973713` on stackoverflow!
---@param inputStr string
---@param seperator string
---@return ...
function util.splitstring(inputStr, seperator)
    if seperator == nil then
        seperator = "%s"
    end
    local t = {}
    for str in string.gmatch(inputStr, "([^" .. seperator .. "]+)") do
        table.insert(t, str)
    end
    return table.unpack(t)
end

---Thanks `manuel_2867` on the Figura Discord!
---@param tbl table
---@param keys table
function util.indexable(tbl, keys)
    if tbl == nil then return nil end
    if #keys == 1 then return tbl[keys[1]] end
    return util.indexable(tbl[table.remove(keys, 1)], keys)
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

local permissionLevels = {
    BLOCKED = 0,
    LOW = 1,
    DEFAULT = 2,
    HIGH = 3,
    MAX = 4
}

---Returns true if the current permission level is greater than or equal to the input permission level
---@overload fun(targetLevel: AvatarAPI.permissionLevel): boolean
---@param targetLevel AvatarAPI.permissionLevel
---@param currentLevel AvatarAPI.permissionLevel
---@return boolean 
function util.comparePermissionLevel(targetLevel, currentLevel)
    local level = currentLevel or avatar:getPermissionLevel()
    return permissionLevels[level] >= permissionLevels[targetLevel]
end

---@param itemStack ItemStack
function util.itemEmpty(itemStack)
    return itemStack:getCount() == 0
end

---@param playr? Player
function util.handsEmpty(playr)
    local p = playr or player
    return util.itemEmpty(p:getHeldItem()) and util.itemEmpty(p:getHeldItem(true))
end

---`:getTags()` returns the item tags, `:getTag()` or `.tag` returns data components
---@param itemStack ItemStack
---@return boolean
function util.crossbowCharged(itemStack)
    local projectiles = itemStack:getTag().ChargedProjectiles
    return projectiles ~= nil and next(projectiles) ~= nil
end

---@param ... ItemStack.useAction
---@return boolean
function util.checkUseAction(...)
    if not player:isUsingItem() then return false end
    local activeItem = player:getActiveItem()
    if activeItem:getCount() == 0 then return false end
    
    local useAction = activeItem:getUseAction()

    if select("#", ...) == 1 then
        return useAction == ...
    end
    
    for _, action in ipairs({...}) do
        if useAction == action then return true end
    end

    return false
end

return util