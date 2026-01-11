local util = require "lib.util"
---@class Afk
local Afk = {}
---@type Afk[]
Afk.ALL = {}

local onSneakChange = util.onChange(function()
    for _, afk in pairs(Afk.ALL) do
        afk.didSneakChange = true
    end
end)

---@alias Afk.Event
---| "ON_CHANGE"
---| "ON_RENDER_LOOP"
---| "ON_TICK_NOT_AFK"

---@param secondsUntilAfk integer
---@param includeRotation? boolean
---@param afkCheckTickRate? integer
---@return Afk.Obj
function Afk.new(secondsUntilAfk, includeRotation, afkCheckTickRate)
    ---@class Afk
    local module = {}

    module.isAfk = false
    module.afkTime = 0
    module.afkCheckTickRate = afkCheckTickRate or 5
    module.delay = secondsUntilAfk * module.afkCheckTickRate
    module.includeRotation = includeRotation or true
    module.didSneakChange = false

    module.events = {
        ON_CHANGE = util.functionTable(),
        ON_RENDER_LOOP = util.functionTable(),
        ON_TICK_NOT_AFK = util.functionTable(),
    }

    module.onAfkChange = util.onChange(module.events.ON_CHANGE --[[@as fun(toggle: boolean)]])

    ---@class Afk.Obj
    local obj = {}

    ---@param event Afk.Event
    ---@param func function
    ---@return Afk.Obj
    function obj:register(event, func)
        table.insert(module.events[event], func)
        return obj
    end

    table.insert(Afk.ALL, module)
    return obj
end

---@param afk Afk
---@return boolean
local function afkEval(afk)
    local posUnchanged = afk.position == afk.oldPosition
    local isAfk = posUnchanged and (player:getPose() ~= "SLEEPING") and not afk.didSneakChange
    afk.oldPosition = afk.position
    afk.position = player:getPos()

    if afk.includeRotation then
        local rotUnchanged = afk.rotation == afk.oldRotation

        afk.oldRotation = afk.rotation
        afk.rotation = player:getRot()

        return isAfk and rotUnchanged
    end
    
    return isAfk
end

events.TICK:register(function()
    local time = world.getTime()
    onSneakChange(player:isSneaking())

    for i, afk in ipairs(Afk.ALL) do
        if (time + i) % afk.afkCheckTickRate == 0 then
            if afkEval(afk) then
                afk.afkTime = afk.afkTime + 1
            else
                afk.didSneakChange = false
                afk.afkTime = 0
            end

            if afk.afkTime ~= 0 then
                if afk.afkTime >= afk.delay then
                    afk.isAfk = true
                end
            else
                if afk.oldAfkTime ~= 0 then
                    afk.isAfk = false
                end
            end

            afk.oldAfkTime = afk.afkTime

            afk.onAfkChange(afk.isAfk)
        end

        if not afk.isAfk then
            afk.events.ON_TICK_NOT_AFK()
        end
    end
end, "Afk")

events.RENDER:register(function(delta, context)
    for _, afk in pairs(Afk.ALL) do
        if not afk.isAfk then return end
        afk.events.ON_RENDER_LOOP(delta, context)
    end
end, "Afk")

return Afk
