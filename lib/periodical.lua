---@class Periodical
local periodical = {}
periodical.objs = 0

---@overload fun(func)
---@param func function
---@param eventType string
---@return Periodical.Obj
function periodical:new(func, eventType)
    ---@class Periodical.Obj
    local interface = {}

    interface.func = func
    interface.type = eventType or "TICK"

    function interface:resetTickCounter()
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
    function interface:setTiming(minTicks, maxTicks)
        interface.minTicks = minTicks
        interface.maxTicks = maxTicks
        interface:resetTickCounter()
        return interface
    end

    ---@overload fun(ticks)
    ---@param minTicks integer
    ---@param maxTicks integer
    ---@return Periodical.Obj
    function interface:timing(minTicks, maxTicks) return interface.setTiming(minTicks, maxTicks) end --- Alias

    ---@param cond function
    ---@return Periodical.Obj
    function interface:setCondition(cond)
        interface.conditionFunc = cond
        return interface
    end

    ---@param cond function
    ---@return Periodical.Obj
    function interface:condition(cond) return interface:setCondition(cond) end --- Alias

    function interface:register()
        local tbl = {}

        interface.name = "Periodical."..tostring(periodical.objs+1)
        
        events[interface.type]:register(function()
            if interface.conditionFunc() then
                interface.tickCounter = interface.tickCounter - 1
                if interface.tickCounter == 0 then
                    interface.func()
                    interface:resetTickCounter()
                end
            end
        end, interface.name)
        
        function tbl:unRegister()
            events[interface.type]:remove(interface.name)
            periodical.objs = periodical.objs - 1
            interface.name = nil
            return interface
        end

        return tbl
    end

    return interface:setCondition(function() return true end):setTiming(100)
end

return periodical
