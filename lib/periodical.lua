---@class Periodical
local periodical = {}
periodical.objs = 0

---@overload fun(func)
---@param func function
---@param eventType string
---@return Periodical.Obj
function periodical:new(func, eventType)
    ---@class Periodical.Obj
    local module = {}

    module.func = func
    module.type = eventType or "TICK"

    function module:resetTickCounter()
        if module.maxTicks == nil or module.minTicks == module.maxTicks then
            module.tickCounter = module.minTicks
        else
            module.tickCounter = math.random(module.minTicks, module.maxTicks)
        end
        return module
    end

    ---@overload fun(ticks)
    ---@param minTicks integer
    ---@param maxTicks integer
    ---@return Periodical.Obj
    function module:setTiming(minTicks, maxTicks)
        module.minTicks = minTicks
        module.maxTicks = maxTicks
        module:resetTickCounter()
        return module
    end

    ---@overload fun(ticks)
    ---@param minTicks integer
    ---@param maxTicks integer
    ---@return Periodical.Obj
    function module:timing(minTicks, maxTicks) return module.setTiming(minTicks, maxTicks) end --- Alias

    ---@param cond function
    ---@return Periodical.Obj
    function module:setCondition(cond)
        module.conditionFunc = cond
        return module
    end

    ---@param cond function
    ---@return Periodical.Obj
    function module:condition(cond) return module:setCondition(cond) end --- Alias

    function module:register()
        local mod = {}

        module.name = "Periodical."..tostring(periodical.objs+1)
        
        events[module.type]:register(function()
            if module.conditionFunc() then
                module.tickCounter = module.tickCounter - 1
                if module.tickCounter == 0 then
                    module.func()
                    module:resetTickCounter()
                end
            end
        end, module.name)
        
        function mod:unRegister()
            events[module.type]:remove(module.name)
            periodical.objs = periodical.objs - 1
            module.name = nil
            return module
        end

        return mod
    end

    return module:setCondition(world.exists):setTiming(100)
end

return periodical
