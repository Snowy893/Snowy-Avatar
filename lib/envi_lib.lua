---@class EnviLib
local enviLib = {}

enviLib.DIMENSION = { ON_CHANGE = {}, REGISTERED = {} }
enviLib.BIOME = { ON_CHANGE = {}, REGISTERED = {} }

local util = require "lib.util"

---@alias EnviLib.Type string
---| "DIMENSION"
---| "BIOME"

---@overload fun(type, func)
---@param type EnviLib.Type
---@param func function
---@param id string
function enviLib:register(type, func, id)
    if id == nil then
        table.insert(enviLib[type].ON_CHANGE, func)
    else
        if not util.contains(enviLib[type].REGISTERED, id) then
            table.insert(enviLib[type].REGISTERED, id)
        end
        table.insert(enviLib[type][id], func)
    end
end

---@param type EnviLib.Type
---@param currentEnvi string | table
---@param oldID string
local function onChange(type, currentEnvi, oldID)
    local id = currentEnvi
    if type == "BIOME" then id = currentEnvi.id end
    for _, func in pairs(enviLib[type].ON_CHANGE) do func(currentEnvi) end
    for _, registeredId in pairs(enviLib[type].REGISTERED) do
        for _, func in pairs(enviLib[type][registeredId]) do
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
    onDimensionChange:check(world.getDimension())
    onBiomeChange:setExtraParam(biome):check(biome.id)
end, "EnviLib")

return enviLib
