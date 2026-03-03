---@type Vector3[]
local skullPositions = {}

function events.tick()
    for _, pos in pairs(skullPositions) do
        local id = world.getBlockState(pos).id
        if id ~= "minecraft:player_head" or id ~= "minecraft:player_wall_head" then
            skullPositions[tostring(pos)] = nil
        end
    end
end

function events.skull_render(_, block)
    if not block then return end
    local pos = block:getPos()
    local index = tostring(pos)
    if not skullPositions[index] then
        skullPositions[index] = pos
    end
end

return skullPositions