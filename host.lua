if not host:isHost() then return end

local util = require "lib.util"
local syncedPings = require "lib.syncedpings"

local page = action_wheel:newPage()
local sadChair = models.model.root.sadchair
local hasSuperSecretShaders = client.compareVersions(client.getVersion(), "1.20.5") ~= 1
local unlockCursorKey = "key.mouse.4" ---@type Minecraft.keyCode

syncedPings.ticks = 4 * 20

action_wheel:setPage(page)

---@param toggle boolean
function pings.sadChair(toggle)
    sadChair:setVisible(toggle)
    animations.model.sadChair:setPlaying(toggle)
end

function pings.creeper()
    SnowyCreeperEyesVisible(true)
    if player:isLoaded() then
        sounds:playSound("minecraft:entity.creeper.primed", util.eyePos(player))
    end
    animations.model.creeper:play()
end

if hasSuperSecretShaders then
    page:newAction()
        :title("Dithering")
        :item("minecraft:apple")
        :hoverColor(1, 0, 1)
        :onToggle(function(toggle)
            renderer:setPostEffect(toggle and "notch" or nil)
        end)
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

keybinds:newKeybind("unlockCursor", unlockCursorKey)
    :onPress(function()
        host.unlockCursor = not host.unlockCursor
    end)