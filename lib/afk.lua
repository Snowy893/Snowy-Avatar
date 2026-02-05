local util = require "lib.util"
---@class Afk
local Afk = {}
---@type Afk.interface[]
Afk.ALL = {}

local isSingleplayer = client.getServerBrand() == "Integrated"

local onSneakChange = util.onchange(function()
    for _, afk in ipairs(Afk.ALL) do
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
---@return Afk.obj
function Afk.new(secondsUntilAfk, includeRotation, afkCheckTickRate)
    ---@class Afk.interface
    local interface = {}

    interface.isAfk = false
    interface.afkTime = 0
    interface.afkCheckTickRate = afkCheckTickRate or 5
    interface.delay = secondsUntilAfk * interface.afkCheckTickRate
    interface.includeRotation = includeRotation or true
    interface.didSneakChange = false

    interface.events = {
        ON_CHANGE = util.functiontable(),
        ON_RENDER_LOOP = util.functiontable(),
        ON_TICK_NOT_AFK = util.functiontable(),
    }

    interface.onAfkChange = util.onchange(interface.events.ON_CHANGE --[[@as fun(toggle: boolean)]])

    ---@class Afk.obj
    local obj = {}

    ---@generic self
    ---@param event Afk.Event
    ---@param func function
    ---@return self
    function obj:register(event, func)
        table.insert(interface.events[event], func)
        return obj
    end

    table.insert(Afk.ALL, interface)
    return obj
end

---@param afk Afk.interface
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
    if not next(Afk.ALL) then return end
    if isSingleplayer and client.isPaused() then return end

    local time = world.getTime()
    onSneakChange(player:isSneaking())

    for i = 1, #Afk.ALL do
        local afk = Afk.ALL[i]
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
