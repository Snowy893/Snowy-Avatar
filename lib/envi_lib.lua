local util = require "lib.util"
---@class EnviLib
local enviLib = {}

local metaEvent = {
    __call = function(tbl, ...)
        for _, func in pairs(tbl) do func(...) end
    end
}

local enviLibEvents = {
    DIMENSION = {
        ON_CHANGE = setmetatable({}, metaEvent),
        REGISTERED = {},
    },
    BIOME = {
        ON_CHANGE = setmetatable({}, metaEvent),
        REGISTERED = {},
    },
}

---@alias EnviLib.Type string
---| "DIMENSION"
---| "BIOME"

---@param type EnviLib.Type
---@param func function
---@param id? string
function enviLib:register(type, func, id)
    if not id then
        table.insert(enviLibEvents[type].ON_CHANGE, func)
    else
        if not util.contains(enviLib[type].REGISTERED, id) then
            table.insert(enviLibEvents[type].REGISTERED, id)
        end
        table.insert(enviLibEvents[type][id], func)
    end
end

---@param type EnviLib.Type
---@param currentEnvi string | table
---@param oldID string
local function onChange(type, currentEnvi, oldID)
    local id = currentEnvi
    if type == "BIOME" then id = currentEnvi.id end
    enviLibEvents[type].ON_CHANGE(currentEnvi)
    for _, registeredId in pairs(enviLibEvents[type].REGISTERED) do
        for _, func in pairs(enviLibEvents[type][registeredId]) do
            if oldID == registeredId or id == registeredId then
                func(currentEnvi, registeredId == id)
            end
        end
    end
end

---@param dim Minecraft.dimensionID
---@param oldDim Minecraft.dimensionID
local onDimensionChange = util:onChange(function(dim, oldDim)
    onChange("DIMENSION", dim, oldDim)
end)

---@param oldBiomeID Minecraft.biomeID
---@param biome Biome
local onBiomeChange = util:onChange(function(_, oldBiomeID, biome)
    onChange("BIOME", biome, oldBiomeID)
end)

events.TICK:register(function()
    local biome = world.getBiome(player:getPos())
    onDimensionChange(world.getDimension())
    onBiomeChange:setExtraParam(biome)(biome.id)
end, "EnviLib")

return enviLib
