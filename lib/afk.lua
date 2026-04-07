local util = require "lib.util"

---@class Afk
---@field timer integer
---@field includeRotation boolean
---@field events {
---     ON_CHANGE: { [any]: function },
---     ON_RENDER_LOOP: { [any]: function },
---     ON_TICK_NOT_AFK: { [any]: function },
---}
---@field afkCheckTickRate integer
---@field delay integer
---@field onAfkChange function
local Afk = {}
Afk.__index = Afk
---@type Afk[]
Afk.ALL = {}

Afk.isAfk = false
Afk.afkTime = 0
Afk.didSneakChange = false

local isSingleplayer = client.getServerBrand() == "Integrated"

local onSneakChange = util.onchange(function()
    for _, afk in ipairs(Afk.ALL) do
        afk.didSneakChange = true
    end
end)

---@return boolean
function Afk:eval()
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

---@overload fun(secondsUntilAfk: integer): Afk.Obj
---@param secondsUntilAfk integer
---@param includeRotation? boolean
---@param afkCheckTickRate? integer
---@return Afk.Obj
function Afk.new(secondsUntilAfk, includeRotation, afkCheckTickRate)
    local afk = setmetatable({}, Afk)
    afk.timer = #Afk.ALL
    afk.includeRotation = includeRotation or true
    afk.events = {
        ON_CHANGE = util.functiontable(),
        ON_RENDER_LOOP = util.functiontable(),
        ON_TICK_NOT_AFK = util.functiontable(),
    }
    afk.afkCheckTickRate = afkCheckTickRate or 5
    afk.delay = secondsUntilAfk * afk.afkCheckTickRate
    afk.onAfkChange = util.onchange(afk.events.ON_CHANGE --[[@as fun(toggle: boolean)]])

    ---@class Afk.Obj
    local obj = {}

    ---@alias Afk.Event string
    ---| "ON_CHANGE"
    ---| "ON_RENDER_LOOP"
    ---| "ON_TICK_NOT_AFK"

    ---@generic self
    ---@param event Afk.Event
    ---@param func function
    ---@return self
    function obj:register(event, func)
        table.insert(afk.events[event], func)
        return obj
    end

    table.insert(Afk.ALL, afk)
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
