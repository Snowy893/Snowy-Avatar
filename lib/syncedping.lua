---@class SyncedPing
local SyncedPing = {}
SyncedPing.ticks = 200

---@generic T
---@param pingFunc fun(...: T?)
---@param eventType "TICK"|"WORLD_TICK"
---@param ... T?
---@return fun(...: T?)
function SyncedPing:new(pingFunc, eventType, ...)
    self.pingFunc = pingFunc
    self.args = ...
    if not SyncedPing[eventType] then
        SyncedPing[eventType] = {}
        events[eventType]:register(function()
            for i, sPing in ipairs(SyncedPing[eventType]) do
                if world.getTime() % (SyncedPing.ticks + (i - 1)) == 0 then
                    sPing.pingFunc(sPing.args)
                end
            end
        end, "SyncedPings." .. eventType)
    end
    table.insert(SyncedPing[eventType], self)
    return function(...)
        self.args = ...
        self.pingFunc(...)
    end
end

return SyncedPing
