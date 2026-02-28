local util = require "lib.util"

---@class ActiveItems
---@field fixCrouchArmOffset boolean
local activeItems = {}
local activeItemsProxy = {}
local mt = {}

---@alias Hand
---| { RIGHT: boolean?, LEFT: boolean? }

---@param hand Hand?
local function fixRot(hand)
    local rightRot = hand and hand.RIGHT and 20 or nil
    local leftRot = hand and hand.LEFT and 20 or nil
    vanilla_model.RIGHT_ARM:setOffsetRot(rightRot)
    vanilla_model.LEFT_ARM:setOffsetRot(leftRot)
end

mt.__index = activeItemsProxy
function mt:__newindex(key, value)
    if key ~= "fixCrouchArmOffset" then
        rawset(activeItems, key, value)
        return
    end
    if activeItemsProxy[key] ~= value then
        if not value then fixRot() end
    end
    activeItemsProxy[key] = value
end

local onItemUse = util.functiontable()
local onCrossbowCharged = util.functiontable()

---@param func fun(useAction: ItemStack.useAction, useTime: integer, leftHanded: boolean)
function activeItems.onItemUse(func)
    table.insert(onCrossbowCharged, func)
end

---@param func fun(projectiles: table)
function activeItems.onCrossbowCharged(func)
    table.insert(onItemUse, func)
end

events.TICK:register(function()
    local crouching = player:isCrouching()
    local leftHanded = player:isLeftHanded()
    local mainHandActive = player:getActiveHand() == "OFF_HAND"
    local rightHandActive = mainHandActive ~= leftHanded
    local useAction = player:getActiveItem():getUseAction()
    local rightItem = player:getHeldItem(leftHanded)
    local leftItem = player:getHeldItem(not leftHanded)
    local projectiles = util.getProjectiles(rightItem) or util.getProjectiles(leftItem)
    local hand ---@type Hand

    if useAction ~= "NONE" and useAction ~= "CROSSBOW" then
        onItemUse(useAction, player:getActiveItemTime(), rightHandActive)
        hand = crouching and rightHandActive and { RIGHT = true } or { LEFT = true } or nil
    elseif projectiles then
        onCrossbowCharged(projectiles)
        hand = crouching and { RIGHT = true, LEFT = true } or nil
    end

    if activeItems.fixCrouchArmOffset then fixRot(hand) end
end)

events.tick:register(function()

end, "ActiveItems")

return setmetatable(activeItems, mt)