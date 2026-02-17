---@meta _
---@diagnostic disable: duplicate-set-field



---@class Event.Error: Event
local EventError

---Registers a function to be run when this event triggers.
---
---Functions are run in the order they are registered.
---
---If a name is given, you can choose to remove the function later with `:remove(name)`
---@generic self
---@param self self
---@param func Event.Error.func
---@param name? string
---@return self
function EventError:register(func, name) end