---@class doRandomly
---@field func function
---@field minTicks integer
---@field maxTicks integer
---@field condition any
---@field index integer
local doRandomly = {}
doRandomly.ALL = {}

---@return self
function doRandomly:resetTickCounter()
    if self.maxTicks == nil or self.minTicks == self.maxTicks then
        self.tickCounter = self.minTicks
    else
        self.tickCounter = math.random(self.minTicks, self.maxTicks)
    end
    return self
end

---@param func function
---@return self
function doRandomly:new(func)
    self.func = func
    self.condition = true
    self.minTicks = 100
    self.maxTicks = 300
    self:resetTickCounter()
    return self
end

---@param minTicks integer
---@param maxTicks integer
function doRandomly:timing(minTicks, maxTicks)
    self.minTicks = minTicks
    self.maxTicks = maxTicks
    self:resetTickCounter()
    return self
end

---@param condition any
---@return self
function doRandomly:condition(condition)
    self.condition = condition
    return self
end

---@return self
function doRandomly:register()
    self.index = #doRandomly.ALL + 1
    table.insert(doRandomly.ALL, self)
    return self
end

---@return self
function doRandomly:unRegister()
    table.remove(doRandomly.ALL, self.index)
    return self
end

function events.TICK()
    if next(doRandomly.ALL) == nil then return end
    for _, rand in pairs(doRandomly.ALL) do
        if rand.condition ~= nil and (rand.condition or rand.condition()) then
            rand.tickCounter = rand.tickCounter - 1
            if rand.tickCounter == 0 then
                rand.func()
                rand:resetTickCounter()
            end
        end
    end
end

return doRandomly