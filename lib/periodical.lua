---@class Periodical
local Periodical = {}
---@type {[string]: Periodical.obj}
Periodical.objs = {}
local count = 0
local isSingleplayer = client.getServerBrand() == "Integrated"

function events.tick()
    if isSingleplayer and client.isPaused() then return end
    for _, obj in pairs(Periodical.objs) do
        if not obj.conditionFunc() then goto continue end

        obj.tickCounter = obj.tickCounter - 1

        if obj.tickCounter == 0 then
            obj.func()
            obj:resetTickCounter()
        end

        ::continue::
    end
end

---@overload fun(func: function)
---@param func function
---@return Periodical.obj
function Periodical.new(func)
    count = count + 1
    ---@class Periodical.obj
    local interface = {}

    interface.id = "Periodical" .. tostring(count)
    interface.func = func

    ---@param ticks number
    pings[interface.id] = function(ticks)
        interface.tickCounter = ticks
    end

    interface.pingTicks = pings[interface.id]

    ---@return self
    function interface:resetTickCounter()
        if self.maxTicks == nil or self.minTicks == self.maxTicks then
            self.tickCounter = self.minTicks
        else
            self.pingTicks(math.random(self.minTicks, self.maxTicks))
        end
        return self
    end

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

    ---@overload fun(ticks: integer): Periodical.obj
    ---@param minTicks integer
    ---@param maxTicks integer
    ---@return self
    function interface:timing(minTicks, maxTicks) return self:setTiming(minTicks, maxTicks) end --- Alias

    ---@param cond fun(): boolean
    ---@return self
    function interface:setCondition(cond)
        self.conditionFunc = cond
        return self
    end

    ---@param cond fun(): boolean
    ---@return self
    function interface:condition(cond) return self:setCondition(cond) end --- Alias

    ---@return Periodical.obj
    function interface:register()
        Periodical.objs[self.id] = self
        return self
    end

    return interface:setCondition(world.exists):setTiming(100)
end

return Periodical
