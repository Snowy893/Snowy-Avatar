---@class Periodical
---@field id string
---@field func function
---@field pingTicks fun(ticks: integer)
local Periodical = {}
Periodical.__index = Periodical
---@type {[string]: Periodical}
Periodical.ALL = {}

local count = 0
local isSingleplayer = client.getServerBrand() == "Integrated"

function Periodical:resetTickCounter()
    if self.maxTicks == nil or self.minTicks == self.maxTicks then
        self.tickCounter = self.minTicks
    else
        self.pingTicks(math.random(self.minTicks, self.maxTicks))
    end
    return self
end

---@overload fun(ticks: integer): Periodical
---@param minTicks integer
---@param maxTicks integer
function Periodical:setTiming(minTicks, maxTicks)
    self.minTicks = minTicks
    self.maxTicks = maxTicks
    self:resetTickCounter()
    return self
end

---@overload fun(ticks: integer): Periodical
---@param minTicks integer
---@param maxTicks integer
---@return self
function Periodical:timing(minTicks, maxTicks) return self:setTiming(minTicks, maxTicks) end --- Alias

---@param cond fun(): boolean
---@return self
function Periodical:setCondition(cond)
    self.conditionFunc = cond
    return self
end

---@param cond fun(): boolean
---@return self
function Periodical:condition(cond) return self:setCondition(cond) end --- Alias

---@return Periodical
function Periodical:register()
    Periodical.ALL[self.id] = self
    return self
end

function events.tick()
    if isSingleplayer and client.isPaused() then return end
    for _, obj in pairs(Periodical.ALL) do
        if not obj.conditionFunc() then goto continue end

        obj.tickCounter = obj.tickCounter - 1

        if obj.tickCounter < 0 then
            obj.tickQueue = obj.tickCounter
        end

        if obj.tickCounter == 0 then
            obj.func()
            obj:resetTickCounter()
        end

        ::continue::
    end
end

---@overload fun(func: function)
---@param func function
---@return Periodical
function Periodical.new(func)
    count = count + 1
    local periodical = setmetatable({}, Periodical)
    periodical.id = "Periodical" .. tostring(count)
    periodical.func = func
    periodical.tickQueue = 0

    ---@param ticks number
    pings[periodical.id] = function(ticks)
        periodical.tickCounter = math.max(0, ticks - periodical.tickQueue)
        periodical.tickQueue = 0
    end

    periodical.pingTicks = pings[periodical.id]

    return periodical:setCondition(world.exists):setTiming(100)
end

return Periodical
