---@class Afk
local afk = {}
afk.ALL = {}

local util = require "lib.util"

---@alias Afk.Event
---| "ON_CHANGE"
---| "ON_RENDER_LOOP"
---| "ON_TICK_NOT_AFK"

---@param secondsUntilAfk integer
---@return Afk.Obj
function afk:new(secondsUntilAfk)
    ---@class Afk.Obj
    local interface = {}

    interface.afkCheckTickRate = 5
    interface.delay = secondsUntilAfk * interface.afkCheckTickRate
    interface.isAfk = false
    interface.afkTime = 0

    interface.events = {
        ON_CHANGE = {},
        ON_RENDER_LOOP = {},
        ON_TICK_NOT_AFK = {},
    }

    interface.onAfkChange = util:onChange(function(toggle)
        for _, func in pairs(interface.events.ON_CHANGE) do func(toggle) end
    end)

    ---@param event Afk.Event
    ---@param func function
    function interface:register(event, func)
        local tbl = interface.events[event]
        table.insert(tbl, func)
        return interface
    end

    table.insert(afk.ALL, interface)

    return interface
end

events.TICK:register(function()
    local time = world.getTime()
    for i, obj in pairs(afk.ALL) do
        if (time + i) % obj.afkCheckTickRate == 0 then
            if (obj.position == obj.oldPosition)
                and (obj.rotation == obj.oldRotation)
                and (player:getPose() ~= "SLEEPING")
            then
                obj.afkTime = obj.afkTime + 1
            else
                obj.afkTime = 0
            end

            obj.oldPosition = obj.position
            obj.oldRotation = obj.rotation
            obj.position = player:getPos()
            obj.rotation = player:getRot()

            if obj.afkTime ~= 0 then
                if obj.afkTime >= obj.delay then
                    obj.isAfk = true
                end
            else
                if obj.oldAfkTime ~= 0 then
                    obj.isAfk = false
                end
            end

            obj.oldAfkTime = obj.afkTime

            obj.onAfkChange:check(obj.isAfk)
        end

        if not obj.isAfk then
            for _, func in pairs(obj.events.ON_TICK_NOT_AFK) do func() end
        end
    end
end, "Afk")

events.RENDER:register(function(delta, context)
    for _, obj in pairs(afk.ALL) do
        if not obj.isAfk then return end
        for _, func in pairs(obj.events.ON_RENDER_LOOP) do func(delta, context) end
    end
end, "Afk")

return afk
