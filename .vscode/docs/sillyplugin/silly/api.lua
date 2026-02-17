---@meta
---@diagnostic disable: duplicate-set-field

---A global api which holds the main functions of SillyPlugin.
---@class SillyAPI
local silly



---==========---
---  CHEATS  ---
---==========---



---This returns true under one of 4 conditions:
---- You are in creative mode
---- You have operator permissions
---- You you are in a singleplayer world
---- The server has §s§i§l§l§y§p§l§u§g§i§n or §s§i§y§p§u§g§i in the MOTD
function silly:cheatsEnabled() end



---@param x number
---@param y number
---@param z number
function silly:setPos(x,y,z) end
---Sets the player's position,
---can be passed as a Vector3 or 3 numbers.
---
---Keep in mind, the server may regect this change and send you back.
---
---This function requires cheatsEnabled to be true.
---@param pos Vector3
function silly:setPos(pos) end



---@param x number
---@param y number
---@param z number
function silly:setVelocity(x,y,z) end
---Sets the player's velocity,
---can be passed as a Vector3 or 3 numbers.
---
---This function requires cheatsEnabled to be true.
---@param vel Vector3
function silly:setVelocity(vel) end



---@param x number
---@param y number
function silly:setRot(x,y) end
---Sets the player's rotation,
---can be passed as a Vector2 or 2 numbers.
---
---This function requires cheatsEnabled to be true.
---@param rot Vector2
function silly:setRot(rot) end



---Toggles the creative flight trigger.
---
---This function requires cheatsEnabled to be true.
---@param state? boolean
function silly:setFly(state) end



---Toggles all block collision.
---
---This function requires cheatsEnabled to be true.
---@param state? boolean
function silly:setNoclip(state) end



---@param pos Vector3
---@param id string
function silly:setBlock(pos,id) end
---Places a client-side block in the world,
---can be passed as a BlockState, or a position and id.
---
---This function requires cheatsEnabled to be true.
---@param block BlockState
function silly:setBlock(block) end



---=================---
---  MISCELLANEOUS  ---
---=================---



---Loads an avatar from your avatars folder.
---@param path string
function silly:loadLocalAvatar(path) end

---Gets the color of another player's avatar,
---can be passed as a name or uuid.
---@param player string
function silly:getAvatarColor(player) end

---Gets the nameplate of another player,
---can be passed as a name or uuid.
---@param player string
function silly:getAvatarNameplate(player) end



---Hides a specific part of the GUI.
---@param element SillyAPI.GuiElement
---@param state? boolean
function silly:setDisableGUIElement(element,state) end

---Gets the current bumpscocity.
function silly:getBumpscocity() end
---Tells you what bumpscocity does.
function silly:whatDoesBumpscocityDo() end

---Mrrp meow :3
function silly:cat() end