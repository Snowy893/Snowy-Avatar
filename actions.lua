--#region imports
local util = require "lib.util"
local syncedPings = require "lib.syncedpings"
local skullPositions = require "lib.skulls"
local runLater = require "lib.thirdparty.runLater"
--#endregion
local sadChair = models.model.sadChair

local page = action_wheel:newPage()

local creeperSound = sounds["minecraft:entity.creeper.primed"]:volume(1.1)
local laughSound = sounds["minecraft:entity.bat.ambient"]:volume(0.7):subtitle("Strange Laugh")
local laughPitch = 0.4

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
        util.playSound(creeperSound)
    end
    for _, pos in pairs(skullPositions) do
        local center = vec(pos.x + 0.5, pos.y, pos.z + 0.5)
        util.playSound(creeperSound, nil, center)
    end
    animations.model.creeper:play()
end

function pings.laugh()
    util.playSound(laughSound, laughPitch)
    runLater(4, function()
        util.playSound(laughSound, laughPitch)
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

page:newAction()
    :title("Laugh")
    :item("minecraft:bat_spawn_egg")
    :hoverColor(1, 0, 1)
    :onLeftClick(pings.laugh)
