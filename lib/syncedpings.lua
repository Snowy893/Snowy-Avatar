---@class SyncedPings
local SyncedPings = {}
---@type SyncedPings[]
SyncedPings.ALL = {}
SyncedPings.ticks = 200

---@generic T
---@param pingFunc fun(...: T?)
---@param ... T?
---@return fun(...: T?)
function SyncedPings:new(pingFunc, ...)
    self.pingFunc = pingFunc
    self.args = ...
    table.insert(SyncedPings.ALL, self)
    return function (...)
        self.args = ...
        self.pingFunc(...)
    end
end

events.WORLD_TICK:register(function()
    for i, sPing in ipairs(SyncedPings.ALL) do
        if world.getTime() % (SyncedPings.ticks + (i - 1)) == 0 then
            sPing.pingFunc(sPing.args)
        end
    end
end, "SyncedPings")

return SyncedPings