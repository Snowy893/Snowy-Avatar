if not host:isHost() then return end

local syncedPings = require "lib.syncedpings"

local unlockCursorKey = "key.mouse.4" ---@type Minecraft.keyCode
local page = action_wheel:newPage()
local sadChair = models.model.root.sadchair
local hasSuperSecretShaders = client.compareVersions(client.getVersion(), "1.20.5") ~= 1
local rightItemPart = models.model.root.ItemRight
local leftItemPart = models.model.root.ItemLeft
local rightItem = rightItemPart:newItem("rightItem")
local leftItem = leftItemPart:newItem("leftItem")

syncedPings.ticks = 4 * 20

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
    :onToggle(syncedPings:new(pings.sadChair, "TICK", false))

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

-- -- rightItemPart:setRot(-70, 30, -12)
-- -- rightItemPart:setPos(-1.5, -5, 0)

-- events.ENTITY_INIT:register(function()
--     events.ITEM_RENDER:register(function(item, mode, pos, rot, scale, lefthanded)
--         local firstPerson = mode:find("FIRST_PERSON")
--         local usingBow = item:getUseAction() == "BOW"
--         if not (firstPerson and usingBow and player:getActiveItemTime() > 0 and player:isCrouching()) then return end
        
--         local bow

--         if lefthanded then
--             leftItem:setItem(item)
--             bow = leftItemPart
--         else
--             rightItem:setItem(item)
--             bow = rightItemPart
--         end

--         return bow
--     end)
-- end)