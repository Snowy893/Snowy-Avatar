---@class Util
---@field tick function | { register: fun(self: table, func: function, ticks: integer?) }
---@field TICK function | { register: fun(self: table, func: function, ticks: integer?) }
local util = {}

local tickObjs = {}
local timer = 0

setmetatable(util, {
    __index = setmetatable({ tick = {} }, {
        __index = function(self, key)
            if type(key) == "string" and key:lower() == "tick" then
                return self.tick
            end
        end,
    }),
    __newindex = function(self, key, value)
        if type(key) == "string" and key:lower() == "tick" then
            self.tick:register(value)
            return
        end
        rawset(self, key, value)
    end
})

---@param func function
---@param ticks integer?
function util.tick:register(func, ticks)
    table.insert(tickObjs, { func = func, ticks = ticks })
end

function events.tick()
    timer = timer + 1
    for _, obj in ipairs(tickObjs) do
        if (not obj.ticks or timer % obj.ticks == 0) then obj.func() end
    end
end

---@param func fun(value, oldValue, ...)
---@param initialValue? any
---@return fun(value, ...)
---@nodiscard
function util.onchange(func, initialValue)
    local oldValue = initialValue
    return function(value, ...)
        if oldValue ~= value then
            func(value, oldValue, ...)
        end
        oldValue = value
    end
end

---Returns an explicit boolean value out of a value that is truthy or falsy
---@param value any
---@return boolean
---@nodiscard
toboolean = toboolean or function(value)
    return value and true or false
end

---@param tbl table
---@param value any
---@nodiscard
table.find = table.find or function(tbl, value)
    if type(value) == "string" then
        return toJson(tbl):find(tostring(value)) ~= nil
    end
    for _, v in pairs(tbl) do
        if value == v then return true end
    end
end

---@param val1 any
---@param val2 any
---@return type|nil
---@nodiscard
function util.comparetype(val1, val2)
    local t = type(val1)
    return t == type(val2) and t or nil
end

---@param tbl1 table
---@param tbl2 table
---@return boolean
---@nodiscard
function util.comparetables(tbl1, tbl2)
    for k, v in pairs(tbl1) do
        if util.comparetype(tbl2[k], v) then
            if not util.comparetables(tbl2[k], v) then
                return false
            end
        elseif tbl2[k] ~= v then
            return false
        end
    end
    return true
end

---@param tbl? { [any]: function }
---@param mtbl? table
---@return table
---@nodiscard
function util.functiontable(tbl, mtbl)
    local t = tbl or {}
    local mt = mtbl or {}
    function mt:__call(...)
        for _, func in pairs(self) do func(...) end
    end
    return setmetatable(t, mt)
end

---Thanks `user973713` on stackoverflow!
---@param input string
---@param separator string
---@return string[]
---@nodiscard
function util.splitstring(input, separator)
    local sep = separator or "%s"
    local t = {}
    for str in string.gmatch(input, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

---@param key any
---@param default any
---@return any
---@nodiscard
function util.getOrDefault(key, default)
    local value = config:load(key)
    if value ~= nil then return value
    else return default end
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
---@nodiscard
function util.comparePermissionLevel(targetLevel, currentLevel)
    local level = currentLevel or avatar:getPermissionLevel()
    return permissionLevels[level] >= permissionLevels[targetLevel]
end

---@param fromPage Page
---@param toPage Page
---@param title string?
---@param item (ItemStack|Minecraft.itemID)?
---@return Action, Action
function util.switchPageActions(fromPage, toPage, title, item)
    return
        fromPage:newAction()
            :title(title)
            :item(item)
            :setOnLeftClick(function() action_wheel:setPage(toPage) end),
        toPage:newAction()
            :title("Back")
            :item("minecraft:barrier")
            :setOnLeftClick(function() action_wheel:setPage(fromPage) end)
end

---@param playr Player?
---@return boolean
---@nodiscard
function util.handsEmpty(playr)
    local p = playr or player
    return p:getHeldItem():getCount() == 0 and p:getHeldItem(true):getCount() == 0
end

---`:getTags()` returns the item tags, `:getTag()` or `.tag` returns data components
---@param itemStack ItemStack
---@return table?
---@nodiscard
function util.getProjectiles(itemStack)
    local projectiles = itemStack:getTag().ChargedProjectiles
    return projectiles
end

---@param itemStack ItemStack
---@return boolean
---@nodiscard
function util.crossbowCharged(itemStack)
    local projectiles = util.getProjectiles(itemStack)
    return projectiles ~= nil and next(projectiles) ~= nil
end

---@overload fun(...: ItemStack.useAction): boolean
---@param playr Player
---@param ... ItemStack.useAction
---@return boolean
---@nodiscard
function util.checkUseAction(playr, ...)
    local actions = { ... }
    local p

    if type(playr) == "PlayerAPI" then
        p = playr
    else
        table.insert(actions, playr)
        p = player
    end
    
    local activeItem = p:getActiveItem()
    if activeItem:getCount() == 0 then return false end

    local useAction = activeItem:getUseAction()
    for _, action in ipairs(actions) do
        if useAction == action then return true end
    end

    return false
end

---@param entity Entity
---@param delta number?
---@nodiscard
function util.eyePos(entity, delta)
    return entity:getPos(delta):add(0, entity:getEyeHeight(), 0)
end

---Thanks `manuel_2867` on the Figura Discord!
---@overload fun(rotation: Vector3)
---@param x any
---@param y any
---@param z any
function util.realRotToModelRot(x, y, z)
    local rot = type(x) == "Vector3" and x or vec(x, y, z)
    return vec(0, 180, 0) - rot
end

---@param action Action
---@param bool boolean?
function util.toggle(action, bool)
    action:toggled(bool)
    action.toggle(bool)
end

---Formats effect ids as `"effect.<namespace>.<name>` regardless of Minecraft version
---(1.20.5 and above formats it as `"<namespace>:<name>"`)
---@param effect string
---@return Minecraft.effectID
function util.getEffect(effect)
    local id = effect
    if effect:find(":", 2) then
        local namespace, name = effect:match("(.*)%:(.*)")
        id = "effect."..namespace.."."..name
    end
    return id
end

---@param ticks integer
---@return fun(time: integer): boolean
function util.createTimer(ticks)
    local lastTime = 0
    return function(time)
        local bool = time == lastTime or time % ticks == 0
        lastTime = time
        return bool
    end
end

return util