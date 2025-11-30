---@class Periodical
local periodical = {}
periodical.ALL = {}

---@param func function
---@return Periodical.Obj
function periodical.new(func)
    assert(type(func) == "function",
        "Invalid argument to function 'new'. Expected function, got " .. type(func))

    ---@class Periodical.Obj
    local interface = {}

    interface.func = func

    function interface.resetTickCounter()
        if interface.maxTicks == nil or interface.minTicks == interface.maxTicks then
            interface.tickCounter = interface.minTicks
        else
            interface.tickCounter = math.random(interface.minTicks, interface.maxTicks)
        end
        return interface
    end

    ---@overload fun(ticks)
    ---@param minTicks integer
    ---@param maxTicks integer
    ---@return Periodical.Obj
    function interface.setTiming(minTicks, maxTicks)
        interface.minTicks = minTicks
        interface.maxTicks = maxTicks
        interface.resetTickCounter()
        return interface
    end

    ---@overload fun(ticks)
    ---@param minTicks integer
    ---@param maxTicks integer
    ---@return Periodical.Obj
    function interface.timing(minTicks, maxTicks) return interface.setTiming(minTicks, maxTicks) end --- Alias

    ---@param cond function
    ---@return Periodical.Obj
    function interface.setCondition(cond)
        interface.conditionFunc = cond
        return interface
    end

    ---@param cond function
    ---@return Periodical.Obj
    function interface.condition(cond) return interface.setCondition(cond) end --- Alias

    function interface.register()
        local tbl = {}

        interface.index = #periodical.ALL + 1
        table.insert(periodical.ALL, interface)

        function tbl.unRegister()
            table.remove(periodical.ALL, interface.index)
            return interface
        end

        return tbl
    end

    ---@diagnostic disable-next-line: missing-return-value
    return interface.condition(function() return true end).timing(100)
end

events.TICK:register(function()
    if next(periodical.ALL) == nil then return end
    for _, rand in pairs(periodical.ALL) do
        if rand.conditionFunc() then
            rand.tickCounter = rand.tickCounter - 1
            if rand.tickCounter == 0 then
                rand.func()
                rand:resetTickCounter()
            end
        end
    end
end, "Periodical.tick")


return periodical
