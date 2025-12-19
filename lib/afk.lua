---@diagnostic disable: undefined-field
local util = require "lib.util"
---@class Afk
local afk = {}
---@type Afk.Obj[]
afk.ALL = {}

---@alias Afk.Event
---| "ON_CHANGE"
---| "ON_RENDER_LOOP"
---| "ON_TICK_NOT_AFK"

---@param secondsUntilAfk integer
---@param includeRotation? boolean
---@return Afk.Obj
function afk:new(secondsUntilAfk, includeRotation)
    ---@class Afk.Obj
    local module = {}

    module._afkCheckTickRate = 5
    module._delay = secondsUntilAfk * module._afkCheckTickRate
    module._isAfk = false
    module._afkTime = 0
    module._includeRotation = includeRotation or true

    module._events = {
        ON_CHANGE = {},
        ON_RENDER_LOOP = {},
        ON_TICK_NOT_AFK = {},
    }

    module._onAfkChange = util:onChange(function(toggle)
        for _, func in pairs(module._events.ON_CHANGE) do func(toggle) end
    end)

    ---@param event Afk.Event
    ---@param func function
    function module:register(event, func)
        table.insert(module._events[event], func)
        return module
    end

    table.insert(afk.ALL, module)

    return module
end

---@param obj Afk.Obj
---@return boolean
local function afkEval(obj)
    local posUnchanged = obj._position == obj._oldPosition
    local isAfk = posUnchanged and player:getPose() ~= "SLEEPING"

    obj._oldPosition = obj._position
    obj._position = player:getPos()

    if obj._includeRotation then
        local rotUnchanged = obj._rotation == obj._oldRotation

        obj._oldRotation = obj._rotation
        obj._rotation = player:getRot()

        return isAfk and rotUnchanged
    end
    
    return isAfk
end

events.TICK:register(function()
    local time = world.getTime()
    for i, obj in ipairs(afk.ALL) do
        if (time + i) % obj._afkCheckTickRate == 0 then
            if afkEval(obj) then
                obj._afkTime = obj._afkTime + 1
            else
                obj._afkTime = 0
            end

            if obj._afkTime ~= 0 then
                if obj._afkTime >= obj._delay then
                    obj._isAfk = true
                end
            else
                if obj._oldAfkTime ~= 0 then
                    obj._isAfk = false
                end
            end

            obj._oldAfkTime = obj._afkTime

            obj._onAfkChange:check(obj._isAfk)
        end

        if not obj._isAfk then
            for _, func in pairs(obj._events.ON_TICK_NOT_AFK) do func() end
        end
    end
end, "Afk")

events.RENDER:register(function(delta, context)
    for _, obj in pairs(afk.ALL) do
        if not obj._isAfk then return end
        for _, func in pairs(obj._events.ON_RENDER_LOOP) do func(delta, context) end
    end
end, "Afk")

return afk
