---@class Util
local util = {}

---Thank you `u/Serious-Accident8443`!
---@param value any
---@param cases table
---@return any
function util.switch(value, cases)
    local match = cases[value] or cases.default or function() end
    return match()
end

---Returns an explicit boolean value out of a value that is truthy or falsy
---@param value any
---@return boolean
function util.toboolean(value)
    if value then return true else return false end
end

---@generic T
---@param func fun(value: T, oldValue: T, ...)
---@param initialValue? any
---@return fun(value: T, ...)
function util.onChange(func, initialValue)
    local oldValue = initialValue or nil

    return function(value, ...)
        if oldValue ~= value then
            func(value, oldValue, ...)
        end
        oldValue = value
    end
end

---@param tbl? table
---@param metaTable? table
---@return FunctionTable
function util.functionTable(tbl, metaTable)
    local t = tbl or {}
    local mtbl = metaTable or {}
    mtbl.__call = function(tble, ...)
        for _, func in pairs(tble) do func(...) end
    end
    ---@class FunctionTable
    return setmetatable(t, mtbl)
end

---Thanks `user973713` on stackoverflow!
---@param inputStr string
---@param seperator string
---@return ...
function util.splitString(inputStr, seperator)
    if seperator == nil then
        seperator = "%s"
    end
    local t = {}
    for str in string.gmatch(inputStr, "([^" .. seperator .. "]+)") do
        table.insert(t, str)
    end
    return table.unpack(t)
end

---Checks if `targetVersion` is greater than or equal to `currentVersion`. Returns nil if it's a non-standard Minecraft version (e.g., snapshots)
---@param targetVersion string
---@param currentVersion? string
---@return boolean?
function util.compareVersion(targetVersion, currentVersion)
    local version = currentVersion or client.getVersion()
    local condition = false

    local _, update, hotfix = util.splitString(version, ".")
    update = tonumber(update)
    if not update then
        return nil
    end
    hotfix = tonumber(hotfix)

    local _, targetUpdate, targetHotfix = util.splitString(targetVersion, ".")
    targetUpdate = tonumber(targetUpdate)
    if targetUpdate then
        condition = update >= targetUpdate
    end
    targetHotfix = tonumber(targetHotfix)
    if targetHotfix then
        condition = condition and hotfix >= targetHotfix
    end

    return condition
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
---@overload fun(targetLevel: AvatarAPI.permissionLevel)
---@param targetLevel AvatarAPI.permissionLevel
---@param currentLevel AvatarAPI.permissionLevel
---@return boolean 
function util.comparePermissionLevel(targetLevel, currentLevel)
    local level = currentLevel or avatar:getPermissionLevel()
    return permissionLevels[level] >= permissionLevels[targetLevel]
end

---@param itemStack ItemStack
function util.isItemEmpty(itemStack)
    return itemStack:getCount() == 0
end

---@param offHand? boolean
---@param playr? Player
function util.isHandEmpty(offHand, playr)
    local p = playr or player
    return util.isItemEmpty(p:getHeldItem(offHand))
end

---`:getTags()` returns the item tags, `:getTag()` or `.tag` returns data components
---@param itemStack ItemStack
---@return boolean
function util.isCrossbowCharged(itemStack)
    local projectiles = itemStack:getTag().ChargedProjectiles
    return projectiles ~= nil and next(projectiles) ~= nil
end

---Checks if the player is using an item with `action` that is either `"BOW"` or `"SPEAR"`. EXCLUDES CROSSBOWS!
---@param itemStack ItemStack
---@return boolean
function util.isRangedWeaponDrawn(itemStack)
    if player:isUsingItem() then
        local useAction = itemStack:getUseAction()
        return (useAction == "BOW") or (useAction == "SPEAR")
    end
    return false
end

return util
