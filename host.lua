if not host:isHost() then return end
--#region imports
local syncedPings = require "lib.syncedpings"
--#endregion
---@type Minecraft.keyCode
local unlockCursorKey = "key.mouse.5"
local page = action_wheel:newPage()
local sadChair = models.model.root.SadChair
local hasSuperSecretShaders = client.compareVersions(client.getVersion(), "1.20.5") ~= 1

syncedPings.ticks = 20

action_wheel:setPage(page)

---@param toggle boolean
function pings.sadChair(toggle)
    sadChair:setVisible(toggle)
    animations.model.sadChair:setPlaying(toggle)
end

function pings.creeper()
    CreeperEyesVisible(true)
    if player:isLoaded() then
        sounds:playSound("minecraft:entity.creeper.primed", player:getPos():add(vec(0, 1, 0)))
    end
    animations.model.creeper:play()
end

if hasSuperSecretShaders then
    ---@param toggle boolean
    local function notchShader(toggle)
        if toggle then
            renderer:setPostEffect("notch")
        else
            renderer:setPostEffect()
        end
    end

    page:newAction()
        :title("Dithering")
        :item("minecraft:apple")
        :hoverColor(1, 0, 1)
        :onToggle(notchShader)
end

page:newAction()
    :title("Sad Chair")
    :item("minecraft:smooth_quartz_stairs")
    :hoverColor(1, 0, 1)
    :onToggle(syncedPings:new(pings.sadChair, false))

page:newAction()
    :title("Creeper")
    :item("minecraft:creeper_head")
    :hoverColor(1, 0, 1)
    :onLeftClick(pings.creeper)

local isCursorUnlocked = false

keybinds:newKeybind("unlockCursor", unlockCursorKey)
    :onPress(function()
        isCursorUnlocked = not isCursorUnlocked
        host.unlockCursor = isCursorUnlocked
    end)