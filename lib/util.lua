---@class Util
local util = {}

---Returns an explicit boolean value out of a value that is truthy or falsy
---@param value any
---@return boolean
function util.toboolean(value)
    return value and true or false
end

---@param val1 any
---@param val2 any
---@return type|nil
function util.comparetype(val1, val2)
    local t = type(val1)
    return t == type(val2) and t or nil
end

---@param tbl1 table
---@param tbl2 table
---@return boolean
function util.comparetables(tbl1, tbl2)
    for k, v in pairs(tbl1) do
        if util.comparetype(tbl2[k], v) == "table" then
            if not util.comparetables(tbl2[k], v) then
                return false
            end
        elseif tbl2[k] ~= v then
            return false
        end
    end
    return true
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
---@return table
function util.functiontable(tbl, mtbl)
    local t = tbl or {}
    local mt = mtbl or {}
    mt.__call = function(self, ...)
        for _, func in pairs(self) do func(...) end
    end
    return setmetatable(t, mt)
end

---Thanks `user973713` on stackoverflow!
---@param input string
---@param separator string
---@return ...
function util.splitstring(input, separator)
    if separator == nil then
        separator = "%s"
    end
    local t = {}
    for str in string.gmatch(input, "([^" .. separator .. "]+)") do
        table.insert(t, str)
    end
    return table.unpack(t)
end

---Thanks `manuel_2867` on the Figura Discord!
---@param tbl table
---@param keys table
---@return any
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

---@param playr Player?
---@return boolean
function util.handsEmpty(playr)
    local p = playr or player
    return p:getHeldItem():getCount() == 0 and p:getHeldItem(true):getCount() == 0
end

---`:getTags()` returns the item tags, `:getTag()` or `.tag` returns data components
---@param itemStack ItemStack
---@return boolean
function util.crossbowCharged(itemStack)
    local projectiles = itemStack:getTag().ChargedProjectiles
    return projectiles ~= nil and next(projectiles) ~= nil
end

---@overload fun(...: ItemStack.useAction): boolean
---@param playr Player
---@param ... ItemStack.useAction
---@return boolean
function util.checkUseAction(playr, ...)
    local actions = {...}
    local p
    if type(playr) == "PlayerAPI" then
        p = playr
    else
        table.insert(actions, playr)
        p = player
    end
    if not p:isUsingItem() then return false end
    local activeItem = p:getActiveItem()
    if activeItem:getCount() == 0 then return false end
    
    local useAction = activeItem:getUseAction()
    
    for _, action in ipairs(actions) do
        if useAction == action then return true end
    end

    return false
end

return util