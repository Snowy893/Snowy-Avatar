if not host:isHost() then return end

local rightItemPart = models.model.ItemRight:setPos(10.1, 0, 1.8):setRot(0, -10, 0)
local rightItem = rightItemPart:newItem("rightItem")
    :setDisplayMode("FIRST_PERSON_RIGHT_HAND")
    :setRot(0, 180, 0)
local leftItemPart = models.model.ItemLeft:setPos(-10.1, 0, 1.8):setRot(0, 10, 0)
local leftItem = leftItemPart:newItem("leftItem")
    :setDisplayMode("FIRST_PERSON_LEFT_HAND")
    :setRot(0, 180, 0)

function events.item_render(item, mode, _, _, _, lefthanded)
    if not player:isLoaded() then return end
    if not mode:find("FIRST_PERSON") then return end

    if player:isLeftHanded() == lefthanded and item.id == "hunters_return:mini_crossbow" then
        local part = lefthanded and leftItemPart or rightItemPart
        local task = lefthanded and leftItem or rightItem
        task:setItem(item)
        return part
    end
end
