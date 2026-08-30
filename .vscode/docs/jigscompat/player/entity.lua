---@meta _
---@diagnostic disable: duplicate-set-field


---==================================================================================================================---
---  ENTITY                                                                                                          ---
---==================================================================================================================---

---A Minecraft entity.
---@class Entity
local Entity

---==================================================================================================================---
---  LIVINGENTITY extends ENTITY                                                                                     ---
---==================================================================================================================---

---A living Minecraft entity.
---@class LivingEntity: Entity
local LivingEntity


---===== GETTERS =====---

---Returns true if this entity is riding a Chain Conveyor.
---@return boolean
---@nodiscard
function LivingEntity:isRidingChainConveyor() end

---Returns true if this entity is in stealth using Cardboard Armor.
---@return boolean
---@nodiscard
function LivingEntity:isCardboardStealth() end