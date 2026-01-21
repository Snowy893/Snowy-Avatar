local util = require "lib.util"
---@class ColorParts
local colorParts = {}

local hasDepthEffect = require("lib.thirdparty.depth_effect") ~= nil

---@param parts ModelPart[]
---@return ColorParts.obj
function colorParts:new(parts)
    ---@class ColorParts.obj
    local module = {}

    local layers = {}
    for _, v in pairs(parts) do
        local index = 1
        local layer = v["layer" .. tostring(index)]
        while layer do
            table.insert(layers, layer)
            index = index + 1
            layer = v["layer" .. tostring(index)]
        end
    end

    ---@alias ColorParts.type
    ---| "all"
    ---| "depthLayer"
    ---| "layer" -- Alias
    ---| "depthLayers"
    ---| "layers" -- Alias
    ---| "depthBackground"
    ---| "background" -- Alias

    ---@param tbl {
    ---     color: Vector3,
    ---     type: ColorParts.type?,
    ---     depthLayer: string?,
    ---     layer: string?, -- Alias of depthLayer
    ---}
    function module:color(tbl)
        local cases = {}

        if not hasDepthEffect then
            cases.default = function()
                for _, part in pairs(parts) do
                    part:color()
                    part:color(tbl.color)
                end
            end

            cases.all = cases.default -- Alias
        else
            cases.depthLayer = function()
                local layer = tbl.depthLayer or tbl.layer
                for _, part in pairs(parts) do
                    if part[layer] then
                        part[layer]:color(tbl.color)
                    end
                end
            end
            cases.layer = cases.depthLayer -- Alias

            cases.depthLayers = function()
                for _, part in pairs(layers) do
                    part:color()
                    part:color(tbl.color)
                end
            end
            cases.layers = cases.depthLayers -- Alias

            cases.depthBackground = function()
                for _, part in pairs(parts) do
                    local background = part.bg or part.background
                    background:color()
                    background:color(tbl.color)
                end
            end
            cases.background = cases.depthBackground -- Alias

            cases.default = function()
                for _, v in pairs(parts) do
                    v:color()
                    v:color(tbl.color)
                end
                module:color({ color = tbl.color, type = "depthLayers" })
                module:color({ color = tbl.color, type = "depthBackground" })
            end
            cases.all = cases.default -- Alias
        end

        util.switch(tbl.type, cases)
    end

    return module
end



return colorParts