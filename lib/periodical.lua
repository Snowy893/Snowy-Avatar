---@class Periodical
local Periodical = {}
Periodical.registeredEvents = {}
---@type Periodical.Obj[]
Periodical.objs = {}
local count = 0

---@overload fun(func: function)
---@param func function
---@param eventType "TICK"|"WORLD_TICK"
---@return Periodical.Obj
function Periodical.new(func, eventType)
    ---@class Periodical.Obj
    local module = {}

    module.func = func
    module.type = eventType or "TICK"

    if events[module.type] == nil then error("Event \"" .. module.type .. "\" does not exist!") end

    count = count + 1

    ---@param ticks number
    pings["periodical" .. tostring(count)] = function(ticks)
        module.tickCounter = ticks
    end

    module.ping = pings["periodical" .. tostring(count)]

    ---@return Periodical.Obj
    function module:resetTickCounter()
        if self.maxTicks == nil or self.minTicks == self.maxTicks then
            self.tickCounter = self.minTicks
        else
            self.ping(math.random(self.minTicks, self.maxTicks))
        end
        return self
    end

    ---@overload fun(ticks: integer): Periodical.Obj
    ---@param minTicks integer
    ---@param maxTicks integer
    ---@return Periodical.Obj
    function module:setTiming(minTicks, maxTicks)
        self.minTicks = minTicks
        self.maxTicks = maxTicks
        self:resetTickCounter()
        return self
    end

    ---@overload fun(ticks: integer): Periodical.Obj
    ---@param minTicks integer
    ---@param maxTicks integer
    ---@return Periodical.Obj
    function module:timing(minTicks, maxTicks) return self:setTiming(minTicks, maxTicks) end --- Alias

    ---@param cond fun(): boolean
    ---@return Periodical.Obj
    function module:setCondition(cond)
        self.conditionFunc = cond
        return self
    end

    ---@param cond fun(): boolean
    ---@return Periodical.Obj
    function module:condition(cond) return self:setCondition(cond) end --- Alias

    ---@return Periodical.RegisteredObj
    function module:register()
        ---@class Periodical.Obj
        local obj = self
        ---@class Periodical.RegisteredObj
        local registeredObj = {}

        if Periodical.registeredEvents[obj.type] == nil then
            Periodical.objs[obj.type] = {}
            events[obj.type]:register(function()
                ---@param o Periodical.Obj
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

        ---@return Periodical.Obj
        function registeredObj:unRegister()
            table.remove(Periodical.objs[obj.type], obj.index)
            if #Periodical.objs[obj.type] == 0 then events["periodical"..obj.type]:remove() end
            return obj
        end

        return registeredObj
    end

    return module:setCondition(world.exists):setTiming(100)
end

return Periodical
