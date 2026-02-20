---@class SyncedPings
local SyncedPings = {}
SyncedPings.ticks = 200

local objs = {}

---@generic T
---@param pingFunc fun(...: T?)
---@param ... T?
---@return fun(...: T?)
function SyncedPings:new(pingFunc, ...)
    if not host:isHost() then return function() end end
    self.pingFunc = pingFunc
    self.args = ...
    table.insert(objs, self)
    return function(...)
        self.args = ...
        self.pingFunc(...)
    end
end

events.TICK:register(function()
    local time = world.getTime()
    for i, sPing in ipairs(objs) do
        if time % (SyncedPings.ticks + (i - 1)) == 0 then
            sPing.pingFunc(sPing.args)
        end
    end
end, "SyncedPings")

return SyncedPings
