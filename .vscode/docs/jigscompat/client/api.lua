---@meta _
---@diagnostic disable: duplicate-set-field


---==================================================================================================================---
---  CLIENTAPI                                                                                                       ---
---==================================================================================================================---

---An API for getting information from the Minecraft game client.
---@class ClientAPI
local ClientAPI


---===== GETTERS =====---

---Gets if a mod with the specified ID is loaded.
---@param id JigCompats.supportedModList
---@return boolean
---@nodiscard
function ClientAPI.isModLoaded(id) end