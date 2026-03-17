---@alias Hand { RIGHT: boolean, LEFT: boolean }

---@alias Util.ArrowTick.func fun(arrow: Entity): hide: boolean?

---@alias Afk.Event string
---| "ON_CHANGE"
---| "ON_RENDER_LOOP"
---| "ON_TICK_NOT_AFK"

---@alias EnviLib.Type string
---| "DIMENSION"
---| "BIOME"

---@alias ColorParts.Type string
---| "all"
---| "depthLayer"
---| "layer" -- Alias
---| "depthLayers"
---| "layers" -- Alias
---| "depthBackground"
---| "background" -- Alias