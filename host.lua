if not host:isHost() then return end

local util = require "lib.util"
local syncedPings = require "lib.syncedpings"

local page = action_wheel:newPage()
local sadChair = models.model.root.sadchair
local hasSuperSecretShaders = client.compareVersions(client.getVersion(), "1.20.5") ~= 1
local unlockCursorKey = "key.mouse.4" ---@type Minecraft.keyCode
local offsetShield = config:load("shouldOffsetShield") or true

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
    :title("Adjust Shield")
    :item("minecraft:shield")
    :hoverColor(1, 0, 1)
    :toggled(true)
    :onToggle(function(toggle)
        offsetShield = toggle
        config:save("shouldOffsetShield", toggle)
    end)

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

local itemRightPart = models.model.ItemRight
local itemLeftPart = models.model.ItemLeft
local taskRight = itemRightPart:newItem("right")
    :setDisplayMode("FIRST_PERSON_RIGHT_HAND")
    :setRot(0, 180, 0)
local taskLeft = itemLeftPart:newItem("left")
    :setDisplayMode("FIRST_PERSON_LEFT_HAND")
    :setRot(0, 180, 0)

function events.entity_init()
    function events.item_render(item, mode, pos, rot, scale, lefthanded)
        if not offsetShield then return end
        if not mode:find("FIRST_PERSON") then return end
        if item:getUseAction() ~= "BLOCK" then return end

        local part = lefthanded and itemLeftPart or itemRightPart
        local task = lefthanded and taskLeft or taskRight
        local offset = player:isUsingItem()
            and (lefthanded and -4.5 or -6.24)
            or  (lefthanded and -3.5 or -3.7)

        task:setPos(0, offset, 0)
        task:setItem(item)

        return part
    end
end
