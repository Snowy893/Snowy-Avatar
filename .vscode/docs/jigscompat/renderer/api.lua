---@meta _
---@diagnostic disable: duplicate-set-field


---==================================================================================================================---
---  RENDERERAPI                                                                                                     ---
---==================================================================================================================---

---An API related to rendering and the camera.
---@class RendererAPI
local RendererAPI


---===== GETTERS =====---

---Gets if you should play the Chain Conveyor riding animation.
---
---Returns `false` if RendererAPI:setSkyhookAnimation is set to false.
---@return boolean
---@nodiscard
function RendererAPI:shouldSkyhookAnimation() end

---Gets if you should hide in a box when using Cardboard Armor.
---
---Returns `false` if RendererAPI:setCardboardBox is set to false.
---@return boolean
---@nodiscard
function RendererAPI:shouldCardboardBox() end


---===== SETTERS =====---

---Sets if you should play the Chain Conveyor riding animation.
---
---If `state` is `nil`, it will default to `false`.
---@generic self
---@param self self
---@param state? boolean
---@return self
function RendererAPI:setSkyhookAnimation(state) end

---Sets if you should hide in a box when using Cardboard Armor.  
---This will also disable the first person overlay.
---
---If `state` is `nil`, it will default to `false`.
---@generic self
---@param self self
---@param state? boolean
---@return self
function RendererAPI:setCardboardBox(state) end
