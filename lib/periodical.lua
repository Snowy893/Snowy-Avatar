---@class Periodical
local Periodical = {}
Periodical.registeredEvents = {}
---@type Periodical.obj[]
Periodical.objs = {}
local count = 0

---@overload fun(func: function)
---@param func function
---@param eventType "TICK"|"WORLD_TICK"
---@return Periodical.obj
function Periodical.new(func, eventType)
    ---@class Periodical.obj
    local interface = {}

    interface.func = func
    interface.type = eventType or "TICK"

    if events[interface.type] == nil then error("Event \"" .. interface.type .. "\" does not exist!") end

    count = count + 1

    ---@param ticks number
    pings["periodical" .. tostring(count)] = function(ticks)
        interface.tickCounter = ticks
    end

    interface.ping = pings["periodical" .. tostring(count)]

    ---@generic self
    ---@return self
    function interface:resetTickCounter()
        if self.maxTicks == nil or self.minTicks == self.maxTicks then
            self.tickCounter = self.minTicks
        else
            self.ping(math.random(self.minTicks, self.maxTicks))
        end
        return self
    end

    ---@generic self
    ---@overload fun(ticks: integer): Periodical.obj
    ---@param minTicks integer
    ---@param maxTicks integer
    ---@return self
    function interface:setTiming(minTicks, maxTicks)
        self.minTicks = minTicks
        self.maxTicks = maxTicks
        self:resetTickCounter()
        return self
    end

    ---@generic self
    ---@overload fun(ticks: integer): Periodical.obj
    ---@param minTicks integer
    ---@param maxTicks integer
    ---@return self
    function interface:timing(minTicks, maxTicks) return self:setTiming(minTicks, maxTicks) end --- Alias

    ---@generic self
    ---@param cond fun(): boolean
    ---@return self
    function interface:setCondition(cond)
        self.conditionFunc = cond
        return self
    end

    ---@generic self
    ---@param cond fun(): boolean
    ---@return self
    function interface:condition(cond) return self:setCondition(cond) end --- Alias

    ---@return Periodical.RegisteredObj
    function interface:register()
        ---@class Periodical.obj
        local obj = self
        ---@class Periodical.RegisteredObj
        local registeredObj = {}

        if Periodical.registeredEvents[obj.type] == nil then
            Periodical.objs[obj.type] = {}
            events[obj.type]:register(function()
                ---@param o Periodical.obj
                for _, o in ipairs(Periodical.objs[obj.type]) do
                    if o.conditionFunc() then
                        o.tickCounter = o.tickCounter - 1
                        if o.tickCounter == 0 then
                            o.func()
                            o:resetTickCounter()
                        end
                    end
                end
            end, "periodical.."..tostring(obj.type))
        end

        obj.index = #Periodical.objs[obj.type] + 1

        table.insert(Periodical.objs[obj.type], obj.index, obj)

        ---@return Periodical.obj
        function registeredObj:unRegister()
            table.remove(Periodical.objs[obj.type], obj.index)
            if #Periodical.objs[obj.type] == 0 then events["periodical"..obj.type]:remove() end
            return obj
        end

        return registeredObj
    end

    return interface:setCondition(world.exists):setTiming(100)
end

return Periodical
