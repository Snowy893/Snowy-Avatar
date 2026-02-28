if not host:isHost() then return end
--#region imports
local util = require "lib.util"
local syncedPings = require "lib.syncedpings"
--#endregion
local sadChair = models.model.root.sadchair
local unlockCursorKey = "key.mouse.4" ---@type Minecraft.keyCode

for _, name in pairs(client.getActiveResourcePacks()) do
    local n = name:lower()
    if n:find("low") and n:find("shield") then
        config:save("shouldFixShield", false)
        config:save("shouldLowerShield", false)
        break
    end
end

local fixShield = config:load("shouldFixShield") or true
local lowShield = config:load("shouldLowerShield") or true

syncedPings.ticks = 4 * 20

local page = action_wheel:newPage()
local emotePage = action_wheel:newPage()
local shieldPage = action_wheel:newPage()

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

util.switchPageAction(
    page,
    shieldPage,
    "Shield",
    "minecraft:shield"
)

util.switchPageAction(
    page,
    emotePage,
    "Emotes",
    "minecraft:player_head"
)

emotePage:newAction()
    :title("Sad Chair")
    :item("minecraft:smooth_quartz_stairs")
    :hoverColor(1, 0, 1)
    :onToggle(syncedPings:new(pings.sadChair, false))

emotePage:newAction()
    :title("Creeper")
    :item("minecraft:creeper_head")
    :hoverColor(1, 0, 1)
    :onLeftClick(pings.creeper)

shieldPage:newAction()
    :title("Adjust Shield")
    :item("minecraft:shield")
    :hoverColor(1, 0, 1)
    :toggled(true)
    :onToggle(function(toggle)
        fixShield = toggle
        config:save("shouldFixShield", toggle)
    end)

shieldPage:newAction()
    :title("Low Shield")
    :item("minecraft:magenta_glazed_terracotta")
    :hoverColor(1, 0, 1)
    :toggled(true)
    :onToggle(function(toggle)
        lowShield = toggle
        config:save("shouldLowerShield", toggle)
    end)

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
        if not fixShield and not lowShield then return end
        if not mode:find("FIRST_PERSON") then return end
        if item:getUseAction() ~= "BLOCK" then return end

        local part = lefthanded and itemLeftPart or itemRightPart
        local task = lefthanded and taskLeft or taskRight

        local blocking = player:isUsingItem()
        
        local fixOffset = blocking and -1.74 or -0.2
        local lowOffset = blocking and -4.5 or -3.5

        local offset = ((fixShield and not lefthanded) and fixOffset or 0) + (lowShield and lowOffset or 0)

        task:setPos(0, offset, 0)
        task:setItem(item)

        return part
    end
end
