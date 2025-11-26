---@class doRandomly
---@field func function
---@field minTicks integer
---@field maxTicks integer
---@field tickCounter integer
---@field condition function
---@field index integer
local doRandomly = {}
doRandomly.ALL = {}

---@param func function
---@return self
function doRandomly.new(func)
    assert(type(func) == "function",
        "Invalid argument to function new. Expected function, got " .. type(func))

    ---@class doRandomly
    local interface = {}

    interface.func = func

    ---@return self
    function interface:resetTickCounter()
        if interface.maxTicks == nil or interface.minTicks == interface.maxTicks then
            interface.tickCounter = interface.minTicks
        else
            interface.tickCounter = math.random(interface.minTicks, interface.maxTicks)
        end
        return interface
    end

    ---@param minTicks integer
    ---@param maxTicks integer
    function interface:timing(minTicks, maxTicks)
        interface.minTicks = minTicks
        interface.maxTicks = maxTicks
        interface:resetTickCounter()
        return interface
    end

    ---@param condition function
    ---@return self
    function interface:setCondition(condition)
        interface.condition = condition
        return interface
    end

    ---@return self
    function interface:register()
        interface.index = #doRandomly.ALL + 1
        table.insert(doRandomly.ALL, interface)
        return interface
    end

    ---@return self
    function interface:unRegister()
        table.remove(doRandomly.ALL, interface.index)
        return interface
    end

    return interface:setCondition(function() return true end):timing(100, 300)
end

events.TICK:register(function()
    if next(doRandomly.ALL) == nil then return end
    for _, rand in pairs(doRandomly.ALL) do
        if rand.condition == nil or (rand.condition ~= nil and rand.condition()) then
            rand.tickCounter = rand.tickCounter - 1
            if rand.tickCounter == 0 then
                rand.func()
                rand:resetTickCounter()
            end
        end
    end
end, "DoRandomly.tick")


return doRandomly
