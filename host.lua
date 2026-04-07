if not host:isHost() then return end
--#region imports
local util = require "lib.util"
local syncedPings = require "lib.syncedpings"
local skullPositions = require "lib.skulls"
local runLater = require "lib.thirdparty.runLater"
--#endregion
local sadChair = models.model.root.sadchair
local unlockCursorKey = "key.mouse.4" ---@type Minecraft.keyCode
local cursorUnlocked = false

local fixShield = util.getOrDefault("shouldFixShield", true)
local lowShield = util.getOrDefault("shouldLowerShield", true)

syncedPings.ticks = 4 * 20

local page = action_wheel:newPage()
local emotePage = action_wheel:newPage()
local qolPage = action_wheel:newPage()

local laughSound = sounds["minecraft:entity.bat.ambient"]
local laughPitch = 0.5

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
    for _, pos in pairs(skullPositions) do
        local center = vec(pos.x + 0.5, pos.y, pos.z + 0.5)
        sounds:playSound("minecraft:entity.creeper.primed", center)
    end
    animations.model.creeper:play()
end

function pings.laugh()
    util.playSound(laughSound, laughPitch)
    runLater(5, function()
        util.playSound(laughSound, laughPitch)
    end)
    runLater(10, function()
        util.playSound(laughSound, laughPitch)
    end)
end

util.switchPageActions(
    page,
    qolPage,
    "QOL",
    "minecraft:shield"
)

util.switchPageActions(
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

emotePage:newAction()
    :title("Laugh")
    :item("minecraft:bat_spawn_egg")
    :hoverColor(1, 0, 1)
    :onLeftClick(pings.laugh)

local fixShieldAction = qolPage:newAction()
    :title("Adjust Shield")
    :item("minecraft:anvil")
    :hoverColor(1, 0, 1)
    :onToggle(function(toggle)
        fixShield = toggle
        config:save("shouldFixShield", toggle)
    end)
    :toggled(fixShield)

local lowShieldAction = qolPage:newAction()
    :title("Low Shield")
    :item("minecraft:magenta_glazed_terracotta")
    :hoverColor(1, 0, 1)
    :onToggle(function(toggle)
        lowShield = toggle
        config:save("shouldLowerShield", toggle)
    end)
    :toggled(lowShield)

local function checkResources()
    if fixShield or lowShield then
        for _, name in ipairs(client.getActiveResourcePacks()) do
            local n = name:lower()
            if n:find("low") and n:find("shield") then
                util.toggle(fixShieldAction, false)
                util.toggle(lowShieldAction, false)
                return
            end
        end
    end
end

checkResources()

qolPage:newAction()
    :title("Shield Fix Auto Disable")
    :item("minecraft:furnace")
    :hoverColor(1, 0, 1)
    :toggled(true)
    :onToggle(function(state)
        local func = state and events.resource_reload.register or events.resource_reload.remove
        func(events.resource_reload, checkResources)
    end)

keybinds:newKeybind("unlockCursor", unlockCursorKey)
    :onPress(function()
        cursorUnlocked = not cursorUnlocked
        host:setUnlockCursor(cursorUnlocked)
    end)

local itemRightPart = models.model.ItemRight
local itemLeftPart = models.model.ItemLeft
local taskRight = itemRightPart:newItem("right")
    :setDisplayMode("FIRST_PERSON_RIGHT_HAND")
    :setRot(0, 180, 0)
local taskLeft = itemLeftPart:newItem("left")
    :setDisplayMode("FIRST_PERSON_LEFT_HAND")
    :setRot(0, 180, 0)

function events.item_render(item, mode, _, _, _, lefthanded)
    if not fixShield and not lowShield or not mode:find("FIRST_PERSON") or item:getUseAction() ~= "BLOCK" then
        return
    end

    local part = lefthanded and itemLeftPart or itemRightPart
    local task = lefthanded and taskLeft or taskRight

    local blocking = player:isLoaded() and player:isUsingItem()
    local fixOffset = blocking and -1.742 or -0.257
    local lowOffset = blocking and -4.5 or -3.5

    local offset = ((fixShield and not lefthanded) and fixOffset or 0) + (lowShield and lowOffset or 0)

    task:setPos(0, offset, 0)
    task:setItem(item)

    return part
end
