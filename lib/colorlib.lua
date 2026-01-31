---@class ColorLib
local colorlib = {}

colorlib.vanillaColors = {
    black = vec(0, 0, 0),
    dark_blue = vec(0, 0, 170),
    dark_green = vec(0, 170, 0),
    dark_aqua = vec(0, 170, 170),
    dark_red = vec(170, 0, 0),
    dark_purple = vec(170, 0, 170),
    gold = vec(255, 170, 0),
    gray = vec(170, 170, 170),
    dark_gray = vec(85, 85, 85),
    blue = vec(85, 85, 255),
    green = vec(85, 255, 85),
    aqua = vec(85, 255, 255),
    red = vec(255, 85, 85),
    light_purple = vec(255, 85, 255),
    yellow = vec(255, 255, 85),
    white = vec(255, 255, 255),
}

------------------------------------------------------------------

local hasDepthEffect = require("lib.thirdparty.depth_effect") ~= nil

---@param parts ModelPart[]
---@return ColorParts
function colorlib.newColorMulti(parts)
    ---@class ColorParts
    local interface = {}

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
            interface:color({ color = tbl.color, type = "depthLayers" })
            interface:color({ color = tbl.color, type = "depthBackground" })
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
    function interface:color(tbl)
        if switch[tbl.type] then
            switch[tbl.type](tbl)
        else
            switch.default(tbl)
        end
    end

    return interface
end

------------------------------------------------------------------

---Thanks `fabtjar` on Github!
---@overload fun(hex: string): Vector3
---@param hex string
---@param alpha number
---@return Vector4
function colorlib.hextorgb(hex, alpha)
    local redColor, greenColor, blueColor = hex:match("#?(..)(..)(..)")
    ---@diagnostic disable-next-line: param-type-mismatch
    redColor, greenColor, blueColor = tonumber(redColor, 16), tonumber(greenColor, 16), tonumber(blueColor, 16)
    if alpha == nil then
        return vec(redColor, greenColor, blueColor)
    end
    return vec(redColor, greenColor, blueColor, alpha)
end

------------------------------------------------------------------

---Thanks `atirut-w` on Github!
---@param r number
---@param g number
---@param b number
---@return string
function colorlib.rgbtohex(r, g, b)
    -- EXPLANATION:
    -- The integer form of RGB is 0xRRGGBB
    -- Hex for red is 0xRR0000
    -- Multiply red value by 0x10000(65536) to get 0xRR0000
    -- Hex for green is 0x00GG00
    -- Multiply green value by 0x100(256) to get 0x00GG00
    -- Blue value does not need multiplication.

    -- Final step is to add them together
    -- (r * 0x10000) + (g * 0x100) + b =
    -- 0xRR0000 +
    -- 0x00GG00 +
    -- 0x0000BB =
    -- 0xRRGGBB
    local rgb = (r * 0x10000) + (g * 0x100) + b
    return string.format("%x", rgb)
end

------------------------------------------------------------------

---Thanks `linuxFoolDumDum` on Reddit!

--Rounds to whole number
---@param num number
local function round(num)
    return math.floor(num + 0.5)
end

-- Converts ~~hexadecimal color~~ rgb to HSL
-- Lightness (L) is changed based on amt
-- Converts HSL back to ~~hex~~ rgb
-- amt (0-100) can be negative to darken or positive to lighten
-- The amt specified is added to the color's existing Lightness
-- e.g., (#000000, 25) L = 25 but (#404040, 25) L = 50
---@overload fun(color: Vector4, amt: number): Vector4
---@overload fun(color: Vector3, amt: number): Vector3
---@overload fun(r: number, g: number, b: number, amt: number): Vector3
---@param r number
---@param g number
---@param b number
---@param a number
---@param amt number
---@return Vector4
function colorlib.lighten(r, g, b, a, amt)
    local overload = type(r)
    if overload == "Vector4" then
        amt = g
        r, g, b, a = r:unpack()
    elseif overload == "Vector3" then
        amt = g
        r, g, b = r:unpack()
    elseif amt == nil then
        amt = a
        a = nil
    end
    
    r = r / 255
    g = g / 255
    b = b / 255

    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local c = max - min
    -----------------------------
    -- Hue
    local h
    if c == 0 then
        h = 0
    elseif max == r then
        h = ((g - b) / c) % 6
    elseif max == g then
        h = ((b - r) / c) + 2
    elseif max == b then
        h = ((r - g) / c) + 4
    end
    h = h * 60
    -----------------------------
    -- Luminance
    local l = (max + min) * 0.5
    -----------------------------
    -- Saturation
    local s
    if l <= 0.5 then
        s = c / (l * 2)
    elseif l > 0.5 then
        s = c / (2 - (l * 2))
    end
    -----------------------------
    local H, S, L, A
    H = round(h) / 360
    S = round(s * 100) / 100
    L = round(l * 100) / 100

    amt = amt / 100
    if L + amt > 1 then
        L = 1
    elseif L + amt < 0 then
        L = 0
    else
        L = L + amt
    end

    local R, G, B
    if S == 0 then
        R, G, B = round(L * 255), round(L * 255), round(L * 255)
    else
        local function hue2rgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1 / 6 then
                return p + (q - p) * (6 * t)
            end
            if t < 1 / 2 then
                return q
            end
            if t < 2 / 3 then
                return p + (q - p) * (2 / 3 - t) * 6
            end
            return p
        end
        local q
        if L < 0.5 then
            q = L * (1 + S)
        else
            q = L + S - (L * S)
        end
        local p = 2 * L - q
        R = round(hue2rgb(p, q, (H + 1 / 3)) * 255)
        G = round(hue2rgb(p, q, H) * 255)
        B = round(hue2rgb(p, q, (H - 1 / 3)) * 255)
    end

    if a ~= nil then
        A = round(a * 255)
        return vec(R, G, B, A)
    else
        return vec(R, G, B)
    end
end

------------------------------------------------------------------

return colorlib