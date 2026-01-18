---@class Periodical
local Periodical = {}
Periodical.registeredEvents = {}
---@type Periodical.Obj[]
Periodical.objs = {}

---@overload fun(func: function)
---@param func function
---@param eventType string?
---@return Periodical.Obj
function Periodical:new(func, eventType)
    ---@class Periodical.Obj
    local module = {}

    module.func = func
    module.type = eventType or "TICK"

    if events[module.type] == nil then error("Event \"" .. module.type .. "\" does not exist!") end

    function pings.setTickCounter(ticks)
        module.tickCounter = ticks
    end

    function module:resetTickCounter()
        if module.maxTicks == nil or module.minTicks == module.maxTicks then
            module.tickCounter = module.minTicks
        else
            pings.setTickCounter(math.random(module.minTicks, module.maxTicks))
        end
        return module
    end

    ---@overload fun(ticks: integer)
    ---@param minTicks integer
    ---@param maxTicks integer
    ---@return Periodical.Obj
    function module:setTiming(minTicks, maxTicks)
        module.minTicks = minTicks
        module.maxTicks = maxTicks
        module:resetTickCounter()
        return module
    end

    ---@overload fun(ticks: integer)
    ---@param minTicks integer
    ---@param maxTicks integer
    ---@return Periodical.Obj
    function module:timing(minTicks, maxTicks) return module:setTiming(minTicks, maxTicks) end --- Alias

    ---@param cond fun(): boolean
    ---@return Periodical.Obj
    function module:setCondition(cond)
        module.conditionFunc = cond
        return module
    end

    ---@param cond fun(): boolean
    ---@return Periodical.Obj
    function module:condition(cond) return module:setCondition(cond) end --- Alias

    ---@return Periodical.RegisteredObj
    function module:register()
        ---@class Periodical.RegisteredObj
        local registeredModule = {}

        if Periodical.registeredEvents[module.type] == nil then
            Periodical.objs[module.type] = {}
            Periodical.registeredEvents[module.type] = events[module.type]:register(function()
                for _, obj in pairs(Periodical.objs[module.type]) do
                    if obj.conditionFunc() then
                        obj.tickCounter = obj.tickCounter - 1
                        if obj.tickCounter == 0 then
                            obj.func()
                            obj:resetTickCounter()
                        end
                    end
                end
            end)
        end

        module.index = #Periodical.objs[module.type] + 1

        table.insert(Periodical.objs[module.type], module.index, module)
        
        ---@return Periodical.Obj
        function registeredModule:unRegister()
            table.remove(Periodical.objs, module.index)
            return module
        end

        return registeredModule
    end

    return module:setCondition(world.exists):setTiming(100)
end

return Periodical
