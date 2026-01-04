--#region imports
local smoothie = require "lib.thirdparty.Smoothie"
local animatedText = require "lib.thirdparty.animatedText"
local depthEffect = require "lib.thirdparty.depth_effect"
local runLater = require "lib.thirdparty.runLater"
local util = require "lib.util"
local afk = require "lib.afk"
local periodical = require "lib.periodical"
local enviLib = require "lib.envilib"
local colorParts = require "lib.colorparts"
local patpat = require "lib.thirdparty.patpat"
local syncedpings = require "lib.syncedpings"
--#endregion
local root = models.model.root
local head = root.Torso.Head
local body = root.Torso.Waist.Body
local eyes = head.Eyes
local creeperEyes = head.CreeperEyes
local skull = models.model.Skull
local skullEyes = skull.Eyes2
local skullCreeperEyes = skull.CreeperEyes2
local sadChair = root.SadChair

local isAfk = false

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

local onAiming = util.onChange(function (toggle)
	animations.model.aiming:setPlaying(toggle)
end)

local creeperEyeParts = { creeperEyes, skull.CreeperEyes2 }

---@type auria.depth_effect.obj[]
local depthObjects = {}
---@type table[]
local layerObjects = (function(parts)
	local tbl = {}
	for _, part in pairs(parts) do
		tbl[part:getName()] = {}

		local index = 1
		local layer = part["layer" .. index] or part["depthLayer" .. index]

		while layer do
			table.insert(tbl[part:getName()], layer)
			index = index + 1
			layer = part["layer" .. index] or part["depthLayer" .. index]
		end
	end
	return tbl
end)({ eyes.RightEye, eyes.LeftEye, })

local initalDepthIncrement = 16

local onPermissionChange = util.onChange(function(toggle)
	if toggle then
		local index = 0

		for _, tbl in pairs(layerObjects) do
			index = index + 1

			runLater(index, function ()
				local depthIncrement = initalDepthIncrement

				for i, layer in ipairs(tbl) do
					layer:setPos()

					if tbl[i + 1] == nil then
						depthIncrement = -initalDepthIncrement
					end

					table.insert(depthObjects, depthEffect.apply(layer, depthIncrement))

					depthIncrement = depthIncrement * 2
				end
			end)
		end
	else
		for _, depthObj in pairs(depthObjects) do
			depthObj:remove()
		end

		depthObjects = {}

		return
	end
end)

local eyeColorParts = colorParts:new({ eyes.RightEye, eyes.LeftEye, skullEyes.RightEye2, skullEyes.LeftEye2 })

animatedText.new("afk", body, vec(-7, 5.5, -6), vec(0.35, 0.35, 0.35),
	"BILLBOARD", "")
animatedText.new("sleeping", body, vec(0, 5, -6), vec(0.35, 0.35, 0.35),
    "BILLBOARD", "")

syncedpings.ticks = 100

vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(true)

skull:setVisible(true)
sadChair:setVisible(false)
creeperEyes:setVisible(false)
skullCreeperEyes:setVisible(false)

eyes:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")
skullEyes:setPrimaryRenderType("EMISSIVE")
creeperEyes:setPrimaryRenderType("EYES")
skullCreeperEyes:setPrimaryRenderType("EMISSIVE")

------------------------------------------------------------------

smoothie:newEye(eyes)
	:leftOffsetStrength(0.25)
	:rightOffsetStrength(0.25)
	:topOffsetStrength(0.25)
	:bottomOffsetStrength(0.25)

periodical:new(function() animations.model.blink:play() end, "WORLD_TICK")
	:condition(function()
		return (not player:isLoaded()) or (not isAfk and player:getPose() ~= "SLEEPING")
	end)
	:timing(100, 300)
	:register()

------------------------------------------------------------------

---This is global because it runs in `animations.model.creeper`'s instruction keyframe
function CreeperEyesVisible(toggle)
	eyes:setVisible(not toggle)
	creeperEyes:setVisible(toggle)
	skullEyes:setVisible(not toggle)
	skullCreeperEyes:setVisible(toggle)
end

if host:isHost() then
	local page = action_wheel:newPage()

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
		sadChair:setVisible(toggle)
		animations.model.sadChair:setPlaying(toggle)
	end

	function pings.creeper()
		CreeperEyesVisible(true)
		sounds:playSound("minecraft:entity.creeper.primed", player:getPos():add(vec(0, 1, 0)))
		animations.model.creeper:play()
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
        :onToggle(syncedpings:new(pings.sadChair, false))

	page:newAction()
		:title("Creeper")
		:item("minecraft:creeper_head")
		:hoverColor(1, 0, 1)
		:onLeftClick(pings.creeper)
end

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
	
    local hasPermission = util.comparePermissionLevel("HIGH")
	
    onPermissionChange(hasPermission)
	
	if hasPermission then
		for i, depthObject in ipairs(depthObjects) do
			local depth = math.cos(world.getTime(delta) * 0.1 + i) * 4
			depthObject:setDepth(depth)
		end
	else
		for _, tbl in pairs(layerObjects) do
			for i, layer in ipairs(tbl) do
				local depth = math.cos(world.getTime(delta) * 0.1 + i) / 6
				layer:setPos(vec(layer:getPos().x, layer:getPos().y, depth))
			end
		end
	end
end

------------------------------------------------------------------

afk.new(180)
	:register("ON_CHANGE", function(toggle)
		isAfk = toggle
		animations.model.afkStart:setPlaying(toggle)
		if not toggle then
			animations.model.afkLoop:stop()
			head:setOffsetRot(0)
		end
	end)
	:register("ON_RENDER_LOOP", function(delta)
		if animations.model.afkStart:isStopped() then
			animations.model.afkLoop:play()
		end
		head:setOffsetRot(math.sin(world.getTime(delta) / 14))
	end)
	:register("ON_TICK_NOT_AFK", function()
		local aiming = false
		local heldItem = player:getHeldItem()
		local heldOffhandItem = player:getHeldItem(true)

		if util.isItemEmpty(heldItem) and util.isItemEmpty(heldOffhandItem) then
			goto continue
		end

		aiming = util.isCrossbowCharged(heldItem) or util.isCrossbowCharged(heldOffhandItem)

		if not aiming then
			aiming = util.isRangedWeaponDrawn(heldItem) or util.isRangedWeaponDrawn(heldOffhandItem)
		end

		::continue::
		onAiming(aiming)
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

table.insert(patpat.oncePat, function()
	sounds:playSound("minecraft:entity.cat.purr", player:getPos(), 0.15)
end)