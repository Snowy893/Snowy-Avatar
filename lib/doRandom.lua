---@class doRandom
---@field func function
---@field minTicks integer
---@field maxTicks integer
---@field condition function
local doRandom = {}
doRandom.ALL = {}

function doRandom:resetTickCounter()
    if self.maxTicks == nil or self.minTicks == self.maxTicks then
        self.tickCounter = self.minTicks
    else
        self.tickCounter = math.random(self.minTicks, self.maxTicks)
    end
end

---@overload fun(func)
---@overload fun(func, min, max)
---@param func function
---@param minTicks integer
---@param maxTicks integer
---@param condition function
---@return doRandom
function doRandom:new(func, minTicks, maxTicks, condition)
    self.func = func
    self.minTicks = minTicks or 100
    self.maxTicks = maxTicks or 300
    self:resetTickCounter()
    if condition == nil then self.condition = function () return true end
    else self.condition = condition end
    table.insert(doRandom.ALL, self)
    return self
end

function events.TICK()
    if next(doRandom.ALL) == nil then return end
    for _, rand in pairs(doRandom.ALL) do
        if rand.condition ~= nil and rand.condition() then
            rand.tickCounter = rand.tickCounter - 1
            if rand.tickCounter == 0 then
                rand.func()
                rand:resetTickCounter()
            end
        end
    end
end

return doRandom