---@class ColorParts
local colorParts = {}

local util = require "lib.util"

---@param parts ModelPart[]
---@return ColorParts.Obj
function colorParts:new(parts)
    ---@class ColorParts.Obj
    local interface = {}

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

    ---@param type string
    ---@param color? Vector3 Resets color multiplier if nil
    function interface:color(type, color)
        if type == "layers" then type = "depthLayers" end
        util.switch(type, {
            all = function ()
                for _, v in pairs(parts) do
                    v:color()
                    v:color(color)
                end
                interface:color("depthLayers", color)
                interface:color("depthBackground", color)
            end,
            depthLayers = function ()
                for _, v in pairs(layers) do
                    v:color()
                    v:color(color)
                end
            end,
            depthBackground = function ()
                for _, v in pairs(parts) do
                    local bg = v.bg or v.background
                    bg:color()
                    bg:color(color)
                end
            end,
            default = function ()
                if type:find("layer") or type:find("depthLayer") then
                    for _, v in pairs(parts) do
                        if v[type] then
                            v[type]:color(color)
                        end
                    end
                    return
                end
                error("Invalid color type: "..tostring(type))
            end
        })
    end

    return interface
end



return colorParts