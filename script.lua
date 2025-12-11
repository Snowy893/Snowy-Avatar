--#region imports
local smoothie = require "lib.thirdparty.Smoothie"
local animatedText = require "lib.thirdparty.animatedText"
local depthEffect = require "lib.thirdparty.depth_effect"
local util = require "lib.util"
local afk = require "lib.afk"
local periodical = require "lib.periodical"
local enviLib = require "lib.envi_lib"
local colorParts = require "lib.color_parts"
local skullTouch = require "lib.skull_touch"
--#endregion
local page = action_wheel:newPage()

local isAfk = false

local onSleep = util:onChange(function (toggle)
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

local onAiming = util:onChange(function (toggle)
	animations.model.aiming:setPlaying(toggle)
end)

local eyes = { models.model.root.Head.Eyes.RightEye, models.model.root.Head.Eyes.LeftEye, models.model.Skull.Eyes2.RightEye2, models.model.Skull.Eyes2.LeftEye2 }

local creeperEyes = { models.model.root.Head.CreeperEyes, models.model.Skull.CreeperEyes2 }

---@type auria.depth_effect.obj[]
local depthObjects = {}
---@type ModelPart[]
local layerObjects = {}

for _, eye in pairs(eyes) do
	local index = 1
	local layer = eye["layer" .. tostring(index)] or eye["depthLayer" .. tostring(index)]

	while layer do
		table.insert(layerObjects, layer)

		index = index + 1
		layer = eye["layer" .. tostring(index)] or eye["depthLayer" .. tostring(index)]
	end
end

local onPermissionChange = util:onChange(function(toggle)
	local initalDepthIncrement = 16

	if toggle then
		for _, eye in pairs(eyes) do
			local index = 1
			local layer = eye["layer" .. tostring(index)] or eye["depthLayer" .. tostring(index)]

			local depthIncrement = initalDepthIncrement

			while layer do
				if not eye["layer" .. tostring(index + 1)] then depthIncrement = -
					initalDepthIncrement end

				table.insert(depthObjects, depthEffect.apply(layer, depthIncrement))

				depthIncrement = depthIncrement * 2
				index = index + 1
				layer = eye["layer" .. tostring(index)] or eye["depthLayer" .. tostring(index)]
			end
		end
	else
		for _, depthObj in pairs(depthObjects) do depthObj:remove() end
		depthObjects = {}
		return
	end
end)

local eyeColorParts = colorParts:new(eyes)

animatedText.new("afk", models.model.root.Body, vec(-7, 5.5, -6), vec(0.35, 0.35, 0.35),
		"BILLBOARD", "")
animatedText.new("sleeping", models.model.root.Head, vec(0, 5, -6), vec(0.35, 0.35, 0.35),
		"BILLBOARD", "")

vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(true)

models.model.root.SadChair:setVisible(false)
models.model.root.Head.CreeperEyes:setVisible(false)

models.model.root.Head.Eyes:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")
models.model.Skull.Eyes2:setPrimaryRenderType("CUTOUT")
models.model.root.Head.CreeperEyes:setPrimaryRenderType("EYES")
models.model.Skull.CreeperEyes2:setPrimaryRenderType("EMISSIVE")

------------------------------------------------------------------

smoothie:newEye(models.model.root.Head.Eyes)
		:leftOffsetStrength(0.25)
		:rightOffsetStrength(0.25)
		:topOffsetStrength(0.25)
		:bottomOffsetStrength(0.25)

periodical:new(function() animations.model.blink:play() end, "WORLD_TICK")
		:condition(function()
			if player:isLoaded() then
				return not isAfk and player:getPose() ~= "SLEEPING"
			else
				return true
			end
		end)
		:timing(100, 300)
		:register()

------------------------------------------------------------------

action_wheel:setPage(page)

---@param toggle boolean
local function notchShader(toggle)
	if toggle then
		renderer:setPostEffect("notch")
	else
		renderer:setPostEffect()
	end
end

---@param toggle boolean
function pings.sadChair(toggle)
	models.model.root.SadChair:setVisible(toggle)
	animations.model.sadChair:setPlaying(toggle)
end

function pings.creeper()
	models.model.root.Head.Eyes:setVisible(false)
	models.model.root.Head.CreeperEyes:setVisible(true)
	models.model.Skull.Eyes2:setVisible(false)
	models.model.Skull.CreeperEyes2:setVisible(true)
	sounds:playSound("minecraft:entity.creeper.primed", player:getPos():add(vec(0, 1, 0)))
	animations.model.creeper:play()
end

function CreeperInstruction()
    models.model.root.Head.Eyes:setVisible(true)
	models.model.root.Head.CreeperEyes:setVisible(false)
	models.model.Skull.Eyes2:setVisible(true)
	models.model.Skull.CreeperEyes2:setVisible(false)
end

page:setKeepSlots(false)

page:newAction()
		:title("Dither")
		:item("minecraft:apple")
		:hoverColor(1, 0, 1)
		:onToggle(notchShader)

page:newAction()
		:title("Sad Chair")
		:item("minecraft:smooth_quartz_stairs")
		:hoverColor(1, 0, 1)
		:onToggle(pings.sadChair)

page:newAction()
		:title("Creeper")
		:item("minecraft:creeper_head")
		:hoverColor(1, 0, 1)
		:onLeftClick(pings.creeper)

------------------------------------------------------------------

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
	onSleep:check(player:getPose() == "SLEEPING")
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
	local hasPermission = util.comparePermissionLevel("HIGH")
	onPermissionChange:check(hasPermission)
	if hasPermission then
		for i, depthObject in pairs(depthObjects) do
			local depth = math.cos(world.getTime(delta) * 0.1 + i) * 4
			depthObject:setDepth(depth)
		end
	else
		for i, layer in pairs(layerObjects) do
			local depth = math.cos(world.getTime(delta) * 0.1 + i) * 4
			layer:setPos(depth)
		end
	end
end

------------------------------------------------------------------

afk:new(180)
		:register("ON_CHANGE", function(toggle)
			isAfk = toggle
			animations.model.afkStart:setPlaying(toggle)
			if not toggle then
				animations.model.afkLoop:stop()
				models.model.root.Head:setOffsetRot(0)
			end
		end)
		:register("ON_RENDER_LOOP", function(delta)
			if animations.model.afkStart:isStopped() then
				animations.model.afkLoop:play()
			end
			models.model.root.Head:setOffsetRot(math.sin(world.getTime(delta) / 14))
		end)
		:register("ON_TICK_NOT_AFK", function()
			local aiming = false

			if util.isHandEmpty() and util.isHandEmpty(true) then
				aiming = false
				goto continue
			end

			local heldItem = player:getHeldItem()
			local heldOffhandItem = player:getHeldItem(true)

			aiming = util.isCrossbowCharged(heldItem) or util.isCrossbowCharged(heldOffhandItem)

			if not aiming then
				aiming = util.isRangedWeaponDrawn(heldItem) or util.isRangedWeaponDrawn(heldOffhandItem)
			end

			::continue::
			onAiming:check(aiming)
		end)

afk:new(210)
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

enviLib:register("DIMENSION", function(dimension)
	local _, endIndex = dimension:find(":")
	dimension = dimension:sub(endIndex + 1, dimension:len())
	
	util.switch(dimension, {
		the_end = function()
			for _, creeperEye in pairs(creeperEyes) do
				creeperEye:color()
				creeperEye:color(0.81, 0.96, 0.99)
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
			for _, creeperEye in pairs(creeperEyes) do
				creeperEye:color()
				creeperEye:color(vec(0.82, 0.2, 0.75))
			end
			eyeColorParts:color({ color = vec(0.91, 0.65, 0.88) })
			eyeColorParts:color({
				color = vec(0.82, 0.2, 0.75),
				type = "depthBackground",
			})
		end,
		default = function()
			for _, creeperEye in pairs(creeperEyes) do
				creeperEye:color()
				creeperEye:color(vec(0.85, 0.66, 1))
			end
			eyeColorParts:color({ color = vec(0.85, 0.66, 1) })
			eyeColorParts:color({
				color = vec(0.75, 0.52, 0.9),
				type = "depthBackground",
			})
		end
	})
end)

---@param skull Skull
skullTouch:register(function(skull)
	if animations.model.skullPat:isPlaying() then
		animations.model.skullPat:stop()
	end
	animations.model.skullPat:play()

	local pos = skull.position
	pos.xz = pos.xz + 0.5
	sounds:playSound("minecraft:entity.bat.hurt", pos, 0.15)
end)