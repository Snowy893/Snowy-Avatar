local util = require "lib.util"
---@class EnviLib
local enviLib = {}

local enviLibEvents = {
    DIMENSION = {
        ON_CHANGE = util.functionTable(),
        REGISTERED = {}
    },
    BIOME = {
        ON_CHANGE = util.functionTable(),
        REGISTERED = {}
    },
}

---@alias EnviLib.Type string
---| "DIMENSION"
---| "BIOME"

---@param type EnviLib.Type
---@param func function
---@param id? string
function enviLib.register(type, func, id)
    if not id then
        table.insert(enviLibEvents[type].ON_CHANGE, func)
    else
        if not enviLibEvents[type][id] then
            table.insert(enviLibEvents[type].REGISTERED, id)
            enviLibEvents[type][id] = util.functionTable()
        end
        table.insert(enviLibEvents[type][id], func)
    end
end

---@param type EnviLib.Type
---@param currentEnvi string | table
---@param oldID string
local function enviChange(type, currentEnvi, oldID)
    local id = currentEnvi
    if type == "BIOME" then id = currentEnvi.id end
    enviLibEvents[type].ON_CHANGE(currentEnvi)
    for _, registeredId in pairs(enviLibEvents[type].REGISTERED) do
        if oldID == registeredId or id == registeredId then
            enviLibEvents[type][registeredId](currentEnvi, registeredId == id)
        end
    end
end

---@param dim Minecraft.dimensionID
---@param oldDim Minecraft.dimensionID
local onDimensionChange = util.onChange(function(dim, oldDim)
    enviChange("DIMENSION", dim, oldDim)
end)

---@param oldBiomeID Minecraft.biomeID
---@param biome Biome
local onBiomeChange = util.onChange(function(_, oldBiomeID, biome)
    enviChange("BIOME", biome, oldBiomeID)
end)

events.TICK:register(function()
    local biome = world.getBiome(player:getPos())
    onDimensionChange(world.getDimension())
    onBiomeChange(biome.id, biome)
end, "EnviLib")

return enviLib
