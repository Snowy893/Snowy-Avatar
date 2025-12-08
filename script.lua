--#region imports
local smoothie = require "lib.thirdparty.Smoothie"
local animatedText = require "lib.thirdparty.animatedText"
local depthEffect = require "lib.thirdparty.depth_effect"
local util = require "lib.util"
local afk = require "lib.afk"
local periodical = require "lib.periodical"
local enviLib = require "lib.enviLib"
local colorParts = require "lib.colorParts"
local skullTouch = require "lib.skullTouch"
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

local eyes = { models.model.root.Head.Eyes.RightEye, models.model.root.Head.Eyes.LeftEye, models.model.root.Skull.Eyes2.RightEye2, models.model.root.Skull.Eyes2.LeftEye2 }

local creeperEyes = {models.model.root.Head.CreeperEyes, models.model.root.Skull.CreeperEyes2}

local depthObjects = {}

local onPermissionChange = util:onChange(function(toggle)
	if toggle then
		local depthIncrement = 16
		for i, eye in pairs(eyes) do
			local index = 1
			local layer = eye["layer" .. tostring(index)]
			while layer do
				if not eye["layer" .. tostring(index + 1)] then depthIncrement = -depthIncrement end
				if util.comparePermissionLevel("HIGH") then
					table.insert(depthObjects, depthEffect.apply(layer, depthIncrement))
				else
					table.insert(depthObjects, layer)
				end
				depthIncrement = depthIncrement * 2
				index = index + 1
				layer = eye["layer" .. tostring(index)]
			end
		end
	elseif next(depthObjects) ~= nil then
		for _, depthObj in pairs(depthObjects) do depthObj:remove() end
		depthObjects = {}
	end
end)

local eyeColor = colorParts:new(eyes)

animatedText.new("afk", models.model.root.Body, vec(-7, 5.5, -6), vec(0.35, 0.35, 0.35),
	"BILLBOARD", "")
animatedText.new("sleeping", models.model.root.Head, vec(0, 5, -6), vec(0.35, 0.35, 0.35),
	"BILLBOARD", "")

vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(true)

models.model.root.SadChair:setVisible(false)
models.model.root.Head.CreeperEyes:setVisible(false)

models.model.root.Head.Eyes:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")
models.model.root.Skull.Eyes2:setPrimaryRenderType("CUTOUT")
models.model.root.Head.CreeperEyes:setPrimaryRenderType("EYES")
models.model.root.Skull.CreeperEyes2:setPrimaryRenderType("EMISSIVE")

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
	models.model.root.Skull.Eyes2:setVisible(false)
	models.model.root.Skull.CreeperEyes2:setVisible(true)
	sounds:playSound("minecraft:entity.creeper.primed", player:getPos():add(vec(0, 1, 0)))
	animations.model.creeper:play()
end

function CreeperInstruction()
    models.model.root.Head.Eyes:setVisible(true)
	models.model.root.Head.CreeperEyes:setVisible(false)
	models.model.root.Skull.Eyes2:setVisible(true)
	models.model.root.Skull.CreeperEyes2:setVisible(false)
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

---`:getTags()` returns the item tags, `:getTag()` or `.tag` returns data components
---@param itemStack ItemStack
---@return boolean
local function isCrossbowCharged(itemStack)
	return itemStack:getTag().ChargedProjectiles ~= nil and
		itemStack:getTag().ChargedProjectiles[1] ~= nil
end

---Checks if the player is using an item with `action` that is either `"BOW"` or `"SPEAR"`. EXCLUDES CROSSBOWS!
---@param itemStack ItemStack
---@return boolean
local function isRangedWeaponDrawn(itemStack)
	if player:isUsingItem() then
		local useAction = itemStack:getUseAction()
		if (useAction == "BOW") or (useAction == "SPEAR") then return true end
	end
	return false
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
	onSleep:check(player:getPose() == "SLEEPING")
end

function events.RENDER(delta)
	local hasPermission = util.comparePermissionLevel("HIGH")
	onPermissionChange:check(hasPermission)
	if not hasPermission then return end
	for i, depthObject in pairs(depthObjects) do
		local depth = math.cos(world.getTime(delta) * 0.1 + i) * 4
		depthObject:setDepth(depth)
	end
end

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
		local leftHanded = player:isLeftHanded()
		local heldRightItem = player:getHeldItem(leftHanded)
		local heldLeftItem = player:getHeldItem(not leftHanded)

		aiming = isCrossbowCharged(heldRightItem) or isCrossbowCharged(heldLeftItem)

		if not aiming then
			aiming = isRangedWeaponDrawn(heldRightItem) or isRangedWeaponDrawn(heldLeftItem)
		end

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
			animatedText.transform("afk",
				vec(-i * 1.1, (math.sin(world.getTime(delta) / 8 + i) * .5) + (i * 1.3), 0), nil, nil,
				v)
		end
	end)

enviLib:register("DIMENSION", function(dim)
	local _, endIndex = dim:find(":")
    dim = dim:sub(endIndex + 1, dim:len())
	util.switch(dim, {
		the_end = function()
			for _, creeperEye in pairs(creeperEyes) do
				creeperEye:color()
				creeperEye:color(0.81, 0.96, 0.99)
			end
			eyeColor:color("all", vec(0.81, 0.96, 0.99))
			eyeColor:color("depthBackground", vec(0.35, 0.1, 0.35))
			eyeColor:color("layer1", vec(1, 1, 1))
		end,
		the_nether = function()
			for _, creeperEye in pairs(creeperEyes) do
				creeperEye:color()
				creeperEye:color(vec(0.82, 0.2, 0.75))
			end
			eyeColor:color("all", vec(0.91, 0.65, 0.88))
			eyeColor:color("depthBackground", vec(0.82, 0.2, 0.75))
		end,
		default = function()
			for _, creeperEye in pairs(creeperEyes) do
				creeperEye:color()
				creeperEye:color(vec(0.85, 0.66, 1))
			end
			eyeColor:color("all", vec(0.85, 0.66, 1))
			eyeColor:color("depthBackground", vec(0.75, 0.52, 0.9))
		end
	})
end)

skullTouch:register(function(skull)
	if animations.model.skullPat:isPlaying() then
		animations.model.skullPat:stop()
	end
	animations.model.skullPat:play()
	sounds:playSound(
		"minecraft:entity.bat.hurt",
		vec(skull.pos.x + 0.5, skull.pos.y, skull.pos.z + 0.5),
		0.15
	)
end)