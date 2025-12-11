---@class Util
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

---Thank you `chloespacedout`!
---@param part ModelPart
---@param name? string
---@param maxDepth? integer
---@param currentDepth? integer
---@return ModelPart
function util.deepcopy(part, name, maxDepth, currentDepth)
    local depth = currentDepth or 1
    if maxDepth and depth > maxDepth then return part end
    local copy
    if name then
        copy = part:copy(name)
    else
        copy = part:copy(part:getName())
    end
    for _, child in ipairs(part:getChildren()) do
        copy:removeChild(child)
        util.deepcopy(child, nil, maxDepth, depth + 1):moveTo(copy)
    end
    return copy
end

---@overload fun(func)
---@param func function
---@param initialValue any
---@return Util.onChange
function util:onChange(func, initialValue)
    ---@class Util.onChange
    local module = {}

    local oldValue = initialValue or nil
    local extraArg

    ---@param value any
    ---@return Util.onChange
    function module:setExtraParam(value)
        extraArg = value
        return module
    end

    ---@param value any
    function module:check(value)
        if oldValue ~= value then
            func(value, oldValue, extraArg)
        end
        oldValue = value
    end

    return module
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
---@overload fun(targetLevel)
---@param targetLevel AvatarAPI.permissionLevel
---@return boolean 
function util.comparePermissionLevel(targetLevel, currentLevel)
    local level = currentLevel or avatar:getPermissionLevel()
    return permissionLevels[level] >= permissionLevels[targetLevel]
end

---@param offHand? boolean
---@param playr? Player
function util.isHandEmpty(offHand, playr)
    local p = playr or player
    return p:getHeldItem(offHand).id == "minecraft:air"
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
