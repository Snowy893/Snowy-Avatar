---@class SkullTouch
local skullTouch = {}
skullTouch.ALL = {}

---@type Skull[]
local skulls = {}

---@type boolean[]
local playerWasSwinging = {}

---@param tbl table
---@return Skull
local function createSkull(tbl)
    ---@class Skull
    ---@field pos Vector3
    ---@field id Minecraft.blockID
    local skull = {}

    for k, v in pairs(tbl) do
        skull[k] = v
    end

    return skull
end

---@param func function
function skullTouch:register(func)
    table.insert(skullTouch.ALL, func)
end

events.SKULL_RENDER:register(function(_, block)
    if block == nil then return end
    local pos = block:getPos()

    for _, skull in pairs(skulls) do
        if pos == skull.pos then
            return
        end
    end

    table.insert(skulls, createSkull({ pos = block:getPos(), id = block.id }))
end, "SkullTouch")

local function tick()
    for _, playr in pairs(world.getPlayers()) do
        local uuid = playr:getUUID()
        local wasSwinging = playerWasSwinging[uuid]

        if wasSwinging == nil then
            wasSwinging = false
            playerWasSwinging[uuid] = wasSwinging
        end

        if playr:getSwingTime() == 1 then
            if not wasSwinging then
                for i, skull in ipairs(skulls) do
                    local worldSkull = world.getBlockState(skull.pos)

                    if worldSkull.id ~= "minecraft:player_head" and worldSkull.id ~= "minecraft:player_wall_head" then
                        table.remove(skulls, i)
                        goto continue
                    end

                    local target = playr:getTargetedBlock(true, 4)

                    if target ~= nil and target:getPos() == skull.pos then
                        for _, func in pairs(skullTouch.ALL) do func(skull) end
                    end

                    ::continue::
                end

                playerWasSwinging[uuid] = true
            end
        else
            if wasSwinging then
                playerWasSwinging[uuid] = false
            end
        end
    end
    if world.getTime() % 300 == 0 then
        if next(skulls) ~= nil then
            skulls = {}
        end
    end
end

events.TICK:register(function ()
    tick()
end, "SkullTouch")

events.WORLD_TICK:register(function()
    if not player:isLoaded() then tick() end
end, "SkullTouch")

return skullTouch