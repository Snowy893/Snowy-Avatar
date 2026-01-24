---@class ColorParts
local colorParts = {}

local hasDepthEffect = require("lib.thirdparty.depth_effect") ~= nil

---@param parts ModelPart[]
---@return ColorParts.obj
function colorParts.new(parts)
    ---@class ColorParts.obj
    local module = {}

    local layers = {}
    for _, v in ipairs(parts) do
        local index = 1
        local layer = v["layer" .. tostring(index)]
        while layer do
            table.insert(layers, layer)
            index = index + 1
            layer = v["layer" .. tostring(index)]
        end
    end

    local switch = {}

    if not hasDepthEffect then
        switch.default = function(tbl)
            for _, part in ipairs(parts) do
                part:color()
                part:color(tbl.color)
            end
        end

        switch.all = switch.default -- Alias
    else
        switch.depthLayer = function(tbl)
            local layer = tbl.depthLayer or tbl.layer
            for _, part in ipairs(parts) do
                if part[layer] then
                    part[layer]:color(tbl.color)
                end
            end
        end
        switch.layer = switch.depthLayer -- Alias

        switch.depthLayers = function(tbl)
            for _, part in ipairs(layers) do
                part:color()
                part:color(tbl.color)
            end
        end
        switch.layers = switch.depthLayers -- Alias

        switch.depthBackground = function(tbl)
            for _, part in ipairs(parts) do
                local background = part.bg or part.background
                background:color()
                background:color(tbl.color)
            end
        end
        switch.background = switch.depthBackground -- Alias

        switch.default = function(tbl)
            for _, v in ipairs(parts) do
                v:color()
                v:color(tbl.color)
            end
            module:color({ color = tbl.color, type = "depthLayers" })
            module:color({ color = tbl.color, type = "depthBackground" })
        end
        switch.all = switch.default -- Alias
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
        if switch[tbl.type] then switch[tbl.type](tbl)
        else switch.default(tbl) end
    end

    return module
end

return colorParts