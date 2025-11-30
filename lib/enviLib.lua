---@class EnviLib
local enviLib = {}

enviLib.DIMENSION = { ON_CHANGE = {} }
enviLib.BIOME = { ON_CHANGE = {} }

enviLib.CACHE = { DIMENSION = {}, BIOME = {} }

local util = require "lib.util"

local current = {}
local old = {}

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
        if not util.contains(enviLib.CACHE[type], id) then
            table.insert(enviLib.CACHE[type], id)
        end
        table.insert(enviLib[type][id], func)
    end
end

---@param type EnviLib.type
---@param currentEnvi any
local function onChange(type, currentEnvi)
    local id
    if type == "BIOME" then id = currentEnvi.id else id = currentEnvi end
    for _, func in pairs(enviLib[type].ON_CHANGE) do func(currentEnvi) end
    for _, value in pairs(enviLib.CACHE[type]) do
        for _, func in pairs(enviLib[type][value]) do
            if old[type] == value or id[type] == value then
                func(currentEnvi, value == id)
            end
        end
    end
end

events.TICK:register(function()
    current.DIMENSION = world.getDimension()
    local biome = world.getBiome(player:getPos())
    current.BIOME = biome.id

    if old.DIMENSION ~= current.DIMENSION then onChange("DIMENSION", current.DIMENSION) end
    if old.BIOME ~= current.DIMENSION then onChange("BIOME", biome) end

    old.DIMENSION = current.DIMENSION
    old.BIOME = current.BIOME
end, "EnviLib.tick")

return enviLib