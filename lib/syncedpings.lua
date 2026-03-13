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
    self.timer = 0
    table.insert(objs, self)
    return function(...)
        self.args = ...
        self.pingFunc(...)
    end
end

events.TICK:register(function()
    for i, obj in ipairs(objs) do
        obj.timer = obj.timer + 1
        if obj.timer == SyncedPings.ticks + (i - 1) == 0 then
            obj.timer = 0
            obj.pingFunc(obj.args)
        end
    end
end, "SyncedPings")

return SyncedPings
