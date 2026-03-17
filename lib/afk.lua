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

---@overload fun(secondsUntilAfk: integer): Afk.obj
---@param secondsUntilAfk integer
---@param includeRotation? boolean
---@param afkCheckTickRate? integer
---@return Afk.obj
function Afk.new(secondsUntilAfk, includeRotation, afkCheckTickRate)
    ---@class Afk.interface
    local interface = {
        isAfk = false,
        afkTIme = 0,
        timer = #Afk.ALL,
        includeRotation = includeRotation or true,
        didSneakChange = false,
        events = {
            ON_CHANGE = util.functiontable(),
            ON_RENDER_LOOP = util.functiontable(),
            ON_TICK_NOT_AFK = util.functiontable(),
        },
    }

    interface.afkCheckTickRate = afkCheckTickRate or 5
    interface.delay = secondsUntilAfk * interface.afkCheckTickRate

    interface.onAfkChange = util.onchange(interface.events.ON_CHANGE --[[@as fun(toggle: boolean)]])

    ---@return boolean
    function interface:eval()
        local posUnchanged = self.position == self.oldPosition
        local isAfk = posUnchanged and (player:getPose() ~= "SLEEPING") and not self.didSneakChange
        self.oldPosition = self.position
        self.position = player:getPos()

        if self.includeRotation then
            local rotUnchanged = self.rotation == self.oldRotation

            self.oldRotation = self.rotation
            self.rotation = player:getRot()

            return isAfk and rotUnchanged
        end

        return isAfk
    end

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

events.TICK:register(function()
    if not next(Afk.ALL) then return end
    if isSingleplayer and client.isPaused() then return end

    onSneakChange(player:isSneaking())

    for _, afk in ipairs(Afk.ALL) do
        afk.timer = afk.timer + 1
        if afk.timer == afk.afkCheckTickRate then
            afk.timer = 0
            
            if afk:eval() then
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
    for _, afk in ipairs(Afk.ALL) do
        if not afk.isAfk then return end
        afk.events.ON_RENDER_LOOP(delta, context)
    end
end, "Afk")

return Afk
