--#region imports
local animatedText = require "lib.thirdparty.animatedText"
local depthEffect = require "lib.thirdparty.depth_effect"
local patpat = require "lib.thirdparty.patpat"
local util = require "lib.util"
local afk = require "lib.afk"
local periodical = require "lib.periodical"
local enviLib = require "lib.envilib"
local colorParts = require "lib.colorparts"
--#endregion
local model = models.model
local root = model.root
local head = root.torso.Head
local body = root.torso.waist.Body
local eyes = head.eyes
local creeperEyes = head.creepereyes
local skull = model.Skull
local skullEyes = skull.eyes2
local skullCreeperEyes = skull.creepereyes2
local rightArm = root.torso.waist.RightArm
local leftArm = root.torso.waist.LeftArm
local rightItemPivot = rightArm.RightItemPivot
local leftItemPivot = leftArm.LeftItemPivot

local isAfk = false

---@param toggle boolean
local onSleep = util.onChange(function (toggle)
	animations.model.afkLoop:setPlaying(toggle)
	if toggle then
		animatedText.setText("sleeping", { text = "Zzz", color = "#605b85" })
		for _, v in pairs(animatedText.getTask("afk").textTasks) do
			v.task:outline(true)
		end
	else
		animatedText.setText("sleeping", "")
	end
end)

---@param vehicle Entity?
local onVehicle = util.onChange(function(vehicle)
	-- local isBoat = vehicle and vehicle:getType():find("boat")
	-- -- local isDriving = vehicle and vehicle:getControllingPassenger() == player
	
	-- if host:isHost() then
	-- 	avatar:store("isInBoat", util.toboolean(isBoat))
	-- end

	-- renderer:setRenderVehicle(not isBoat)

	-- -- models.model.boat:setVisible(isBoat and isDriving)
end)

---@param toggle boolean
local onAiming = util.onChange(function (toggle)
	animations.model.aiming:setPlaying(toggle)
end)

---@param state Hand
local onAimingBowWhileCrouching = util.onChange(function(state)
	local rot = vec(15, 50, 15)
	local pos = vec(-2.5, 0, -1)
	if state == 1 then
		rightItemPivot:setRot(rot)
		rightItemPivot:setPos(pos)
		leftItemPivot:setRot()
		leftItemPivot:setPos()
	elseif state == -1 then
		leftItemPivot:setRot(vec(rot.x, -rot.y, -rot.z))
		leftItemPivot:setPos(vec(-pos.x, pos.y, pos.z))
		rightItemPivot:setRot()
		rightItemPivot:setPos()
	else
		rightItemPivot:setRot()
		rightItemPivot:setPos()
		leftItemPivot:setRot()
		leftItemPivot:setPos()
	end
end)

---@param state Hand
local onSpyglass = util.onChange(function(state)
	local pos = vec(0, 0, -11.2)
	local scale = vec(1.95, 0.95, 1)
	if state == 1 then
		eyes.righteye:setPos(pos)
		eyes.righteye:setScale(scale)
		eyes.lefteye:setPos()
		eyes.lefteye:setScale()
		animations.model.squintleft:play()
		animations.model.squintright:stop()
	elseif state == -1 then
		eyes.lefteye:setPos(pos)
		eyes.lefteye:setScale(scale)
		eyes.righteye:setPos()
        eyes.righteye:setScale()
		animations.model.squintright:play()
		animations.model.squintleft:stop()
	else
		eyes.righteye:setPos()
		eyes.righteye:setScale()
		eyes.lefteye:setPos()
		eyes.lefteye:setScale()
		animations.model.squintleft:stop()
		animations.model.squintright:stop()
	end
end)

---@param state boolean
local onCrossbowChargedWhileCrouching = util.onChange(function(state)
	local armRot = state and 20 or nil
	vanilla_model.RIGHT_ARM:setOffsetRot(armRot)
	vanilla_model.LEFT_ARM:setOffsetRot(armRot)
end)

local creeperEyeParts = { creeperEyes, skull.CreeperEyes2 }

---@type auria.depth_effect.obj[]
local depthObjects = {}
---@param parts ModelPart[]
---@return ModelPart[][]
local layerObjects = (function(parts)
	local tbl = {}
	for _, part in pairs(parts) do
		local name = part:getName()
		
		tbl[name] = {}

		local index = 1
		local layer = part["layer" .. index] or part["depthLayer" .. index]

		while layer do
			table.insert(tbl[name], layer)
			index = index + 1
			layer = part["layer" .. index] or part["depthLayer" .. index]
		end
	end
	return tbl
end)({ eyes.righteye, eyes.lefteye })

local initalDepthIncrement = 16

for _, obj in pairs(layerObjects) do
	local depthIncrement = initalDepthIncrement

	for i, layer in ipairs(obj) do
		if obj[i + 1] == nil then
			depthIncrement = -initalDepthIncrement
		end

		table.insert(depthObjects, depthEffect.apply(layer, depthIncrement))

		depthIncrement = depthIncrement * 2
	end
end

local eyeColorParts = colorParts:new({ eyes.righteye, eyes.lefteye, skullEyes.righteye2, skullEyes.lefteye2 })

animatedText.new("afk", body, vec(-7, 5.5, -6), vec(0.35, 0.35, 0.35),
	"BILLBOARD", "")
animatedText.new("sleeping", body, vec(0, 5, -6), vec(0.35, 0.35, 0.35),
    "BILLBOARD", "")

vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(true)

------------------------------------------------------------------

periodical:new(function() animations.model.blink:play() end, "WORLD_TICK")
	:condition(function()
		return (not player:isLoaded()) or (not isAfk and player:getPose() ~= "SLEEPING")
	end)
	:timing(100, 300)
	:register()

------------------------------------------------------------------

---This is global because it runs in `animations.model.creeper`'s instruction keyframe
---@param toggle boolean
function CreeperEyesVisible(toggle)
	eyes:setVisible(not toggle)
	creeperEyes:setVisible(toggle)
	skullEyes:setVisible(not toggle)
	skullCreeperEyes:setVisible(toggle)
end

------------------------------------------------------------------

---@alias Hand
---| -1 -- LEFT
---| false -- NONE
---| 1 -- RIGHT

function events.ENTITY_INIT()
	nameplate.ALL:setText(toJson {
		text = "Snowy:blahaj:",
		hoverEvent = {
			action = "show_text",
			contents = player:getName(),
		},
	})
end

function events.TICK()
	local activeItem = player:getActiveItem()
	local useAction = activeItem:getUseAction()
	local leftHanded = player:isLeftHanded()
	local crouching = player:isCrouching()
	local shouldSquint = false
	local spyglassHand = false ---@type Hand
	local bowWhileCrouchingHand = false ---@type Hand
	local crossbowCharged = false
	local hand = player:getActiveHand() == "MAIN_HAND" and 1 or -1 ---@type Hand
	if leftHanded then hand = -hand end

	if crouching then
		crossbowCharged = util.crossbowCharged(player:getHeldItem(leftHanded))
			or util.crossbowCharged(player:getHeldItem(not leftHanded))
	end

	if activeItem == "minecraft:air" then goto continue end

	if useAction == "BOW" and crouching then
		bowWhileCrouchingHand = hand
	elseif useAction == "SPYGLASS" then
		spyglassHand = hand
	end

	if isAfk or spyglassHand then goto continue end

	shouldSquint = player:getActiveItemTime() >= 50 and util.checkUseAction("BOW", "SPEAR")

	::continue::
	onAiming(shouldSquint)
	onAimingBowWhileCrouching(bowWhileCrouchingHand)
	onCrossbowChargedWhileCrouching(crossbowCharged and crouching)
	onSpyglass(spyglassHand)

	onSleep(player:getPose() == "SLEEPING")
	onVehicle(player:getVehicle())
end

function events.RENDER(delta)
	if player:getPose() == "SLEEPING" then
		for i, v in ipairs(animatedText.getTask("sleeping").textTasks) do
			animatedText.transform(
				"sleeping",
				vec(-i * 1.1, (math.sin(world.getTime(delta) / 8 + i) * .5) + (i * 1.3), 0), nil, nil,
				v
			)
		end
	end
	
	for i, depthObject in ipairs(depthObjects) do
		local depth = math.cos(world.getTime(delta) * 0.1 + i) * 4
		depthObject:setDepth(depth)
	end
end

------------------------------------------------------------------

afk.new(180)
	:register("ON_CHANGE", function(toggle)
		isAfk = toggle
		animations.model.afkStart:setPlaying(toggle)
		if not toggle then
			animations.model.afkLoop:stop()
			head:setOffsetRot()
		end
	end)
	:register("ON_RENDER_LOOP", function(delta)
		if animations.model.afkStart:isStopped() then
			animations.model.afkLoop:play()
		end
		head:setOffsetRot(math.sin(world.getTime(delta) / 14))
	end)

afk.new(210)
	:register("ON_CHANGE", function(toggle)
		if toggle then
			animatedText.setText("afk", { text = "Zzz", color = "#605b85" })
			for _, v in pairs(animatedText.getTask("afk").textTasks) do
				v.task:outline(true)
			end
		else
			animatedText.setText("afk", "")
		end
	end)
	:register("ON_RENDER_LOOP", function(delta)
		for i, v in ipairs(animatedText.getTask("afk").textTasks) do
			animatedText.transform(
				"afk",
				vec(-i * 1.1, (math.sin(world.getTime(delta) / 8 + i) * .5) + (i * 1.3), 0), nil, nil,
				v
			)
		end
	end)

---@param id Minecraft.dimensionID
enviLib.register("DIMENSION", function(id)
	local endIndex = select(2, id:find(":"))
	local dimension = id:sub(endIndex + 1)
	
	util.switch(dimension, {
		the_end = function()
			for _, part in pairs(creeperEyeParts) do
				part:color()
				part:color(0.81, 0.96, 0.99)
			end
			eyeColorParts:color({ color = vec(0.81, 0.96, 0.99) })
			eyeColorParts:color({
				color = vec(0.35, 0.1, 0.35),
				type = "depthBackground",
			})
			eyeColorParts:color({
				color = vec(1, 1, 1),
				type = "layer",
				layer = "layer1",
			})
		end,
		the_nether = function()
			for _, part in pairs(creeperEyeParts) do
				part:color()
				part:color(vec(0.82, 0.2, 0.75))
			end
			eyeColorParts:color({ color = vec(0.91, 0.65, 0.88) })
			eyeColorParts:color({
				color = vec(0.82, 0.2, 0.75),
				type = "depthBackground",
			})
		end,
		default = function()
			for _, part in pairs(creeperEyeParts) do
				part:color()
				part:color(vec(0.85, 0.66, 1))
			end
			eyeColorParts:color({ color = vec(0.85, 0.66, 1) })
			eyeColorParts:color({
				color = vec(0.75, 0.52, 0.9),
				type = "depthBackground",
			})
		end
	})
end)

---@param headPos Vector3
table.insert(patpat.head.oncePat, function(_, headPos)
	if animations.model.skullPat:isPlaying() then
		animations.model.skullPat:stop()
	end
	animations.model.skullPat:play()
	headPos.x_z = headPos.x_z + 0.5
	sounds:playSound("minecraft:entity.bat.hurt", headPos, 0.15)
end)

table.insert(patpat.player.oncePat, function()
	sounds:playSound("minecraft:entity.cat.purr", player:getPos(), 0.15)
end)