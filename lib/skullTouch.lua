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

events.TICK:register(function ()
    for _, p in pairs(world.getPlayers()) do
        local uuid = p:getUUID()
        local wasSwinging = playerWasSwinging[uuid]
        if wasSwinging == nil then
            wasSwinging = false
            playerWasSwinging[uuid] = wasSwinging
        end
        if p:getSwingTime() == 1 then
            if not wasSwinging then
                for i, skull in ipairs(skulls) do
                    local target = p:getTargetedBlock(true, 4)
                    if target ~= nil and target:getPos() == skull.pos then
                        if target.id == "minecraft:player_head" or target.id == "minecraft:player_wall_head" then
                            for _, func in pairs(skullTouch.ALL) do func(skull) end
                        else
                            table.remove(skulls, i)
                        end
                    end
                    playerWasSwinging[uuid] = true
                end
            end
        else
            if wasSwinging then
                playerWasSwinging[uuid] = false
            end
        end
    end
    if world.getTime() % 300 == 0 then
        skulls = {}
    end
end, "SkullTouch")

return skullTouch