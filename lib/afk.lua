---@class Afk
local afk = {}
local afks = 0

local util = require "lib.util"

---@alias Afk.event
---| "ON_CHANGE"
---| "ON_RENDER_LOOP"
---| "ON_TICK_NOT_AFK"

---@param secondsUntilAfk integer
---@return Afk.Obj
function afk.new(secondsUntilAfk)
    afks = afks + 1

    local afkCheckTickRate = 5
    local delay = secondsUntilAfk * afkCheckTickRate

    ---@class Afk.Obj
    local interface = {}

    interface.isAfk = false
    interface.afkTime = 0

    interface.events = {
        ON_CHANGE = {},
        ON_RENDER_LOOP = {},
        ON_TICK_NOT_AFK = {},
    }

    local onAfk = util.onChange(function(toggle)
        for _, func in pairs(interface.events.ON_CHANGE) do func(toggle) end
    end)

    ---@param event Afk.event
    ---@param func function
    function interface.register(event, func)
        local tbl = interface.events[event]
        table.insert(tbl, func)
        return interface
    end

    events.TICK:register(function()
        if world.getTime() % afkCheckTickRate == 0 then
            if (interface.position == interface.oldPosition)
                and (interface.rotation == interface.oldRotation)
                and (player:getPose() ~= "SLEEPING")
            then
                interface.afkTime = interface.afkTime + 1
            else
                interface.afkTime = 0
            end
            
            interface.oldPosition = interface.position
            interface.oldRotation = interface.rotation
            interface.position = player:getPos()
            interface.rotation = player:getRot()

            if interface.afkTime ~= 0 then
                if interface.afkTime >= delay then
                    interface.isAfk = true
                end
            else
                if interface.oldAfkTime ~= 0 then
                    interface.isAfk = false
                end
            end

            interface.oldAfkTime = interface.afkTime

            onAfk.check(interface.isAfk)
        end

        if not interface.isAfk then
            for _, func in pairs(interface.events.ON_TICK_NOT_AFK) do func() end
        end
    end, "Afk.tick."..afks)

    events.RENDER:register(function (delta, context)
        if not interface.isAfk then return end
        for _, func in pairs(interface.events.ON_RENDER_LOOP) do func(delta, context) end
    end, "Afk.render."..afks)

    return interface
end

return afk
