---@class EnviLib
local enviLib = {}

enviLib.DIMENSION = { ON_CHANGE = {}, REGISTERED = {} }
enviLib.BIOME = { ON_CHANGE = {}, REGISTERED = {} }

local util = require "lib.util"

---@alias EnviLib.type string
---| "DIMENSION"
---| "BIOME"

---@overload fun(type, func)
---@param type EnviLib.type
---@param func function
---@param id string
function enviLib.register(type, func, id)
    if id == nil then
        table.insert(enviLib[type].ON_CHANGE, func)
    else
        if not util.contains(enviLib[type].REGISTERED, id) then
            table.insert(enviLib[type].REGISTERED, id)
        end
        table.insert(enviLib[type][id], func)
    end
end

---@param type EnviLib.type
---@param currentEnvi any
---@param oldId string
local function onChange(type, currentEnvi, oldId)
    local id = currentEnvi
    if type == "BIOME" then id = currentEnvi.id end
    for _, func in pairs(enviLib[type].ON_CHANGE) do func(currentEnvi) end
    for _, registeredId in pairs(enviLib[type].REGISTERED) do
        for _, func in pairs(enviLib[type][registeredId]) do
            if oldId == registeredId or id == registeredId then
                func(currentEnvi, registeredId == id)
            end
        end
    end
end

local onDimensionChange = util.onChange(function (dim, oldDim)
    onChange("DIMENSION", dim, oldDim)
end)

local onBiomeChange = util.onChange(function (_id, oldBiome, biome)
    onChange("BIOME", biome, oldBiome)
end)

events.TICK:register(function()
    local biome = world.getBiome(player:getPos())
    onDimensionChange.check(world.getDimension())
    onBiomeChange.setExtraArg(biome).check(biome.id)
end, "EnviLib.tick")

return enviLib