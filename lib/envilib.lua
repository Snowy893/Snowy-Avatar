local util = require "lib.util"
---@class EnviLib
local enviLib = {}

local enviLibEvents = {
    DIMENSION = {
        ON_CHANGE = util.functiontable(),
        REGISTERED = {}
    },
    BIOME = {
        ON_CHANGE = util.functiontable(),
        REGISTERED = {}
    },
}

---@alias EnviLib.Type string
---| "DIMENSION"
---| "BIOME"

---@overload fun(type: EnviLib.Type, func: fun(environment: Minecraft.dimensionID | Biome))
---@param type EnviLib.Type
---@param func fun(environment: Minecraft.dimensionID | Biome, enteredOrExited: boolean)
---@param id? string
function enviLib.register(type, func, id)
    if not id then
        table.insert(enviLibEvents[type].ON_CHANGE, func)
    else
        if not enviLibEvents[type][id] then
            table.insert(enviLibEvents[type].REGISTERED, id)
            enviLibEvents[type][id] = util.functiontable()
        end
        table.insert(enviLibEvents[type][id], func)
    end
end

---@param type EnviLib.Type
---@param currentEnvi Minecraft.dimensionID | Biome
---@param oldID Minecraft.dimensionID | Minecraft.biomeID
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
local onDimensionChange = util.onchange(function(dim, oldDim)
    enviChange("DIMENSION", dim, oldDim)
end)

---@param oldBiomeID Minecraft.biomeID
---@param biome Biome
local onBiomeChange = util.onchange(function(_, oldBiomeID, biome)
    enviChange("BIOME", biome, oldBiomeID)
end)

events.TICK:register(function()
    local dimension = world.getDimension()
    local biome = world.getBiome(player:getPos())
    onDimensionChange(dimension)
    onBiomeChange(biome.id, biome)
end, "EnviLib")

return enviLib
