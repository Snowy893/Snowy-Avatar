---@type Vector3[]
local skullPositions = {}

function events.tick()
    for i, pos in ipairs(skullPositions) do
        local id = world.getBlockState(pos).id
        if id ~= "minecraft:player_head" or id ~= "minecraft:player_wall_head" then
            table.remove(skullPositions, i)
        end
    end
end

function events.skull_render(_, block)
    if not block then return end
    local pos = block:getPos()
    if not table.find(skullPositions, pos) then table.insert(skullPositions, pos) end
end

return skullPositions