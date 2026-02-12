---@class SyncedPings
local SyncedPings = {}
SyncedPings.ticks = 200

---@generic T
---@param pingFunc fun(...: T?)
---@param eventType "TICK"|"WORLD_TICK"
---@param ... T?
---@return fun(...: T?)
function SyncedPings:new(pingFunc, eventType, ...)
    if not host:isHost() then return function() end end
    if eventType ~= "TICK" and eventType ~= "WORLD_TICK" then
        error("Unexpected event type: \""..tostring(eventType).."\" (Should be either \"TICK\" or \"WORLD_TICK\"!)")
    end
    self.pingFunc = pingFunc
    self.args = ...
    if not SyncedPings[eventType] then
        SyncedPings[eventType] = {}
        events[eventType]:register(function()
            for i, sPing in ipairs(SyncedPings[eventType]) do
                if world.getTime() % (SyncedPings.ticks + (i - 1)) == 0 then
                    sPing.pingFunc(sPing.args)
                end
            end
        end, "SyncedPings." .. eventType)
    end
    table.insert(SyncedPings[eventType], self)
    return function(...)
        self.args = ...
        self.pingFunc(...)
    end
end

return SyncedPings
