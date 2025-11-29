---@class EnviLib
local enviLib = {}

enviLib.DIMENSION = { ON_CHANGE = {} }
enviLib.BIOME = { ON_CHANGE = {} }

enviLib.REGISTERED = { DIMENSION = {}, BIOME = {} }

local util = require "lib.util"

local currentID = {}
local oldID = {}


---@alias EnviLib.type string
---| "DIMENSION"
---| "BIOME"

---@overload fun(type, onChange)
---@param type EnviLib.type
---@param onChange function
---@param id string
function enviLib.register(type, onChange, id)
    if id == nil then
        table.insert(enviLib[type].ON_CHANGE, onChange)
    else
        if not util.contains(enviLib.REGISTERED[type], id) then
            table.insert(enviLib.REGISTERED[type], id)
        end
        table.insert(enviLib[type][id], onChange)
    end
end

---@param type EnviLib.type
---@param currentEnvi any
local function onChange(type, currentEnvi)
    local id
    if type == "BIOME" then id = currentEnvi.id else id = currentEnvi end
    for _, func in pairs(enviLib[type].ON_CHANGE) do func(currentEnvi) end
    for _, value in pairs(enviLib.REGISTERED[type]) do
        for _, func in pairs(enviLib[type][value]) do
            if oldID[type] == value or currentID[type] == value then
                func(currentEnvi, value == id)
            end
        end
    end
end

events.TICK:register(function()
    currentID.DIMENSION  = world.getDimension()
    local biome = world.getBiome(player:getPos())
    currentID.BIOME = biome.id

    if oldID.DIMENSION ~= currentID.DIMENSION then onChange("DIMENSION", currentID.DIMENSION) end
    if oldID.BIOME ~= currentID.BIOME then onChange("BIOME", biome) end

    oldID.DIMENSION = currentID.DIMENSION
    oldID.BIOME = currentID.BIOME
end, "enviLib.tick")

return enviLib