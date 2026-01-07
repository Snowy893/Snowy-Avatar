---@class LoadedPings
local loadedPings = {}
local _loadedPings = {}

setmetatable(loadedPings, {
    __index = _loadedPings,
    __newindex = function(_, index, value)
        pings[index] = value
        local function func(...)
            if player:isLoaded() then
                pings[index](...)
            end
        end
        tbl[index] = func
    end
})

rawset(_G, "loadedPings", loadedPings)
