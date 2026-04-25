-- Figura CuriosAPIAPI v1.0.0 by Snowy893
-- Curios API Mod can be found here: https://modrinth.com/mod/curios

---@class CuriosAPIAPI
local CuriosAPIAPI = {}

---@alias Curios.slotID
---| "head"
---| "necklace"
---| "back"
---| "rings"
---| "hands"
---| "waist"
---| "belt"
---| "talisman"
---| "feet"
---| "charm"

---@alias Curios.dropRule
---| "DEFAULT"
---| "ALWAYS_DROP"
---| "ALWAYS_KEEP"
---| "DESTROY"

---@alias Curios.Data {
---     Identifier: Curios.slotID,
---     StacksHandler: {
---         Cosmetics: {
---             Items: ItemStack[],
---             Size: integer,
---         },
---         Visible: 0|1, -- Doesn't actually change when visibility is toggled
---         HasCosmetic: 0|1, -- Doesn't actually change when visibility is toggled
---         Stacks: {
---             Items: ItemStack[],
---             Size: integer,
---         },
---         SavedBaseSize: integer,
---         DropRule: Curios.dropRule,
---         RenderToggle: 0|1, -- Doesn't actually change when visibility is toggled
---         Renders: {
---             Renders: ({
---                 Render: (0|1), -- Actually changes when visibility is toggled
---                 Slot: integer,
---             }?)[],
---             Size: integer,
---         },
---     },
---}[]

---@alias Curios.Slot {
---     items: ItemStack[]?,
---     visible: boolean, -- True if visibility is on, false if visibility is off or if no items are equipped in the slot.
---     dropRule: Curios.dropRule,
---}

---@alias Curios.Inventory { [Curios.slotID]: Curios.Slot }

---@param entity Entity
---@return Curios.Data?
function CuriosAPIAPI.getCuriosData(entity)
    if not client.isModLoaded("curios") then return nil end
    local nbt = entity:getNbt()
    ---@type Curios.Data?
    return nbt.ForgeCaps
        and nbt.ForgeCaps["curios:inventory"]
        and nbt.ForgeCaps["curios:inventory"].Curios
        or nil
end

---@param entity Entity? -- Uses `player` by default
---@return boolean
function CuriosAPIAPI.wearingAny(entity)
    local curios = CuriosAPIAPI.getCuriosData(entity or player)
    if not curios then return false end

    for _, v in ipairs(curios) do
        local items = v.StacksHandler.Stacks.Items
        if next(items) ~= nil then
            local toggled = false

            for _, render in ipairs(v.StacksHandler.Renders.Renders) do
                if render.Render == 1 then
                    toggled = true
                end
            end

            if toggled then return true end
        end
    end
    return false
end

---@param slot Curios.slotID
---@param entity Entity? -- Uses `player` by default
---@return Curios.Slot?
function CuriosAPIAPI.getSlot(slot, entity)
    local curios = CuriosAPIAPI.getCuriosData(entity or player)
    if not curios then return nil end

    for _, v in ipairs(curios) do
        if v.Identifier == slot then
            ---@type Curios.Slot
            local slotData = {
                items = v.StacksHandler.Stacks.Items,
                dropRule = v.StacksHandler.DropRule,
            }
            
            local toggled = false

            for _, render in ipairs(v.StacksHandler.Renders.Renders) do
                if render.Render == 1 then
                    toggled = true
                    break
                end
            end

            slotData.visible = toggled and next(slotData.items) ~= nil

            return slotData
        end
    end

    return nil
end

---@param entity Entity? -- Uses `player` by default
---@return Curios.Inventory?
function CuriosAPIAPI.getInventory(entity)
    local curios = CuriosAPIAPI.getCuriosData(entity or player)
    if not curios then return nil end

    local inv = {}

    for _, v in ipairs(curios) do
        inv[v.Identifier] = {}
        local slot = inv[v.Identifier]

        slot.items = v.StacksHandler.Stacks.Items
        slot.visible = false
        slot.dropRule = v.StacksHandler.DropRule

        for _, render in ipairs(v.StacksHandler.Renders.Renders) do
            if render.Render == 1 then
                slot.visible = true
                break
            end
        end
    end

    return next(inv) ~= nil and inv or nil
end

return CuriosAPIAPI