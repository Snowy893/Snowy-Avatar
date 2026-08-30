---@diagnostic disable: duplicate-set-field, duplicate-doc-field
---@meta

---@class EventsAPI
local event = {}



---This event is a SillyPlugin feature and should not be used without it installed.
---
---This event runs when your avatar encounters an error.
---> ```lua
---> (callback) function(msg: string)
---> ```
---> ***
---> A callback that is given a received error message's contents.
---> 
---> Returning true acts as if the errored thread was pcalled.
event.ERROR = nil ---@type Event.Error | Event.Error.func

---This event is a SillyPlugin feature and should not be used without it installed.
---
---This event runs when your avatar encounters an error.
---> ```lua
---> (callback) function(msg: string)
---> ```
---> ***
---> A callback that is given a received error message's contents.
---> 
---> Returning true acts as if the errored thread was pcalled.
event.error = nil ---@type Event.Error | Event.Error.func