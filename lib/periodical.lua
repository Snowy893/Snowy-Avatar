---@class Periodical
local Periodical = {}
---@type Periodical.obj[]
Periodical.objs = {}
local count = 0
local isSingleplayer = client.getServerBrand() == "Integrated"

local function tick()
    if isSingleplayer and client.isPaused() then return end
    ---@param obj Periodical.obj
    for _, obj in ipairs(Periodical.objs) do
        if obj.conditionFunc() then
            obj.tickCounter = obj.tickCounter - 1
            if obj.tickCounter == 0 then
                obj.func()
                obj:resetTickCounter()
            end
        end
    end
end

---@overload fun(func: function)
---@param func function
---@return Periodical.obj
function Periodical.new(func)
    ---@class Periodical.obj
    local interface = {}

    interface.func = func

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

        obj.index = #Periodical.objs + 1

        if obj.index == 1 then
            events.TICK:register(tick, "Periodical")
        end

        table.insert(Periodical.objs, obj.index, obj)

        ---@return Periodical.obj
        function registeredObj:unRegister()
            table.remove(Periodical.objs, obj.index)
            if #Periodical.objs == 0 then events.TICK:remove("Periodical") end
            return obj
        end

        return registeredObj
    end

    return interface:setCondition(world.exists):setTiming(100)
end

return Periodical
