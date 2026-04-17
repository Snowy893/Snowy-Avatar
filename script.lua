--#region imports
local depthEffect = require "lib.thirdparty.depth_effect"
local patpat = require "lib.thirdparty.patpat"
local util = require "lib.util"
local originsapi = require "lib.thirdparty.OriginsAPI"
local afk = require "lib.afk"
local periodical = require "lib.periodical"
local enviLib = require "lib.envilib"
local colorlib = require "lib.colorlib"
--#endregion
local model = models.model
local root = model.root
local head = root.Head
local body = root.Body
local eyes = head.eyes
local creeperEyes = head.creepereyes:scale(1.2, 1.2, 1.2)
local skull = model.Skull
local skullEyes = skull.eyes2
local skullCreeperEyes = skull.creepereyes2:scale(1.2, 1.2, 1.2)
local rightArm = root.RightArm
local leftArm = root.LeftArm
local rightItemPivot = rightArm.RightItemPivot
local leftItemPivot = leftArm.LeftItemPivot
local rods = root.blazebornRods:scale(0.7, 0.7, 0.7):setPrimaryRenderType("TRANSLUCENT")

vanilla_model.PLAYER:setVisible(false)
eyes.righteye.background:setPrimaryRenderType("EMISSIVE_SOLID")
eyes.lefteye.background:setPrimaryRenderType("EMISSIVE_SOLID")
skullEyes.righteye2.background:setPrimaryRenderType("EMISSIVE_SOLID")
skullEyes.lefteye2.background:setPrimaryRenderType("EMISSIVE_SOLID")

------------------------------------------------------------------

local name = "Snowy"
local nameColor = "#6600cc"
local nameOutlineColor = colorlib.lighten(vectors.hexToRGB(nameColor) * 255, -25)
local plate = {
	text = name,
	color = nameColor,
}

nameplate.ENTITY:setOutline(true)
nameplate.ENTITY:setOutlineColor(nameOutlineColor / 255)
nameplate.ALL:setText(toJson(plate))

local onTeamChange = util.onchange(function(teamColor)
	local outline

	plate.hoverEvent.contents = player:getName()

	if teamColor then
		local rgb = colorlib.vanillaColors[teamColor]
		local lighten = teamColor == "black" and 30 or -35

        plate.color = teamColor
		outline = colorlib.lighten(rgb, lighten)
	else
		plate.color = nameColor
		outline = nameOutlineColor
	end

	nameplate.ALL:setText(toJson(plate))
	nameplate.ENTITY:setOutlineColor(outline / 255)
end, true)

function events.entity_init()
	plate.hoverEvent = {
		action = "show_text",
		contents = player:getName(),
	}
	nameplate.ALL:setText(toJson(plate))
end

------------------------------------------------------------------

---@alias Hand { RIGHT: boolean, LEFT: boolean }

---@param hand Hand
local onAimingBowWhileCrouching = util.onchange(function(hand)
	local rot = vec(30, 50, 30)
	local pos = vec(-2.5, 0, -0.5)
	if hand and hand.RIGHT then
		rightItemPivot:setRot(rot)
		rightItemPivot:setPos(pos)
		leftItemPivot:setRot()
		leftItemPivot:setPos()
	elseif hand and hand.LEFT then
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

---@param hand Hand
local onSpyglass = util.onchange(function(hand)
	local pos = vec(0, 0, -11.2)
	local scale = vec(1.95, 0.95, 1)
	if hand and hand.RIGHT then
		eyes.righteye:setPos(pos)
		eyes.righteye:setScale(scale)
		eyes.lefteye:setPos()
		eyes.lefteye:setScale()
		animations.model.squintleft:play()
		animations.model.squintright:stop()
	elseif hand and hand.LEFT then
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

---@param hand Hand
local onCrouchArmOffsetRot = util.onchange(function(hand)
	local rightRot = (hand and hand.RIGHT) and 20 or nil
	local leftRot = (hand and hand.LEFT) and 20 or nil
	vanilla_model.RIGHT_ARM:setOffsetRot(rightRot)
	vanilla_model.LEFT_ARM:setOffsetRot(leftRot)
end)

------------------------------------------------------------------

---@type auria.depth_effect.obj[]
local depthObjects = {}
---@type {[string]: ModelPart[]}
local layerObjects = {}
do
	local parts = { eyes.righteye, eyes.lefteye }
	for _, part in ipairs(parts) do
		local partName = part:getName()

		layerObjects[partName] = {}

		local index = 1
		local layer = part["layer" .. index] or part["depthLayer" .. index]

		while layer do
			table.insert(layerObjects[partName], layer)
			index = index + 1
			layer = part["layer" .. index] or part["depthLayer" .. index]
		end
	end
end

for _, obj in pairs(layerObjects) do
    for _, layer in ipairs(obj) do
        table.insert(depthObjects, depthEffect.apply(layer, 1))
    end
end

------------------------------------------------------------------

local eyeColor = colorlib.newColorMulti({
	eyes.righteye,
	eyes.lefteye,
	skullEyes.righteye2,
	skullEyes.lefteye2,
	creeperEyes,
	skullCreeperEyes
})

------------------------------------------------------------------

local isAfk = false

periodical.new(function() animations.model.blink:play() end)
	:condition(function() return not isAfk and player:getPose() ~= "SLEEPING" end)
	:timing(100, 300)
	:register()

------------------------------------------------------------------

---This is global because it runs in `animations.model.creeper`'s instruction keyframe
---@param toggle boolean
function SnowyCreeperEyesVisible(toggle)
	eyes:setVisible(not toggle)
	creeperEyes:setVisible(toggle)
	skullEyes:setVisible(not toggle)
	skullCreeperEyes:setVisible(toggle)
end

------------------------------------------------------------------

function util.tick()
	local crouching = player:isCrouching()
	local team = player:getTeamInfo()
    local color = team and team.color
	
	local useAction = player:getActiveItem():getUseAction()
	local useTime = player:getActiveItemTime()

	if useTime == 80 and (useAction == "BOW" or useAction == "SPEAR") then
		animations.model.aiming:play()
	elseif useTime < 80 then
		animations.model.aiming:stop()
	end
	
	local leftHanded = player:isLeftHanded()
	local mainHandActive = player:getActiveHand() == "MAIN_HAND"
	local hand = mainHandActive ~= leftHanded and { RIGHT = true } or { LEFT = true } ---@type Hand

	local doubleCrouchHand ---@type Hand
	local singleCrouchHand ---@type Hand
	local spyglassHand ---@type Hand
	local bowCrouchHand ---@type Hand

	if useAction == "SPYGLASS" then
		spyglassHand = hand
	elseif crouching then
		if useAction == "BOW" then
			bowCrouchHand = hand
		elseif util.compare(useAction, "TOOT_HORN", "SPEAR", "BLOCK") then
			singleCrouchHand = hand
		else
			local rightItem = player:getHeldItem(leftHanded)
			local leftItem = player:getHeldItem(not leftHanded)
			if util.crossbowCharged(rightItem) or util.crossbowCharged(leftItem) then
				doubleCrouchHand = { RIGHT = true, LEFT = true }
			end
		end
	end

	onAimingBowWhileCrouching(bowCrouchHand)
	onSpyglass(spyglassHand)
	onCrouchArmOffsetRot(singleCrouchHand or not bowCrouchHand and doubleCrouchHand)

    onTeamChange(color)
end

function events.render(delta, context)
	local time = world.getTime(delta)

	if context == "FIRST_PERSON" then return end

    local cameraPos = client.getCameraPos()
    local eyePos = util.eyePos(player, delta)
	local distance = math.abs((cameraPos - eyePos):length())

	for i, depthObject in ipairs(depthObjects) do
		local depth = math.cos(time * 0.1 + i) * distance
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

local dimenions = {}

function dimenions.the_end()
	eyeColor:color({ color = vec(0.81, 0.96, 0.99) })
	eyeColor:color({
		color = vec(0.35, 0.1, 0.35),
		type = "depthBackground",
	})
	eyeColor:color({
		color = vec(1, 1, 1),
		type = "layer",
		layer = "layer1",
	})
end

function dimenions.the_nether()
	eyeColor:color({ color = vec(0.91, 0.65, 0.88) })
	eyeColor:color({
		color = vec(0.82, 0.2, 0.75),
		type = "depthBackground",
	})
end

function dimenions.overworld()
	eyeColor:color({ color = vec(0.85, 0.66, 1) })
	eyeColor:color({
		color = vec(0.75, 0.52, 0.9),
		type = "depthBackground",
	})
end

---@param id Minecraft.dimensionID
enviLib.register("DIMENSION", function(id)
	local endIndex = select(2, id:find(":"))
	local dimension = id:sub(endIndex + 1)
	
	if dimenions[dimension] then dimenions[dimension]()
	else dimenions.overworld() end
end)

---@param headPos Vector3
table.insert(patpat.head.oncePat, function(_, headPos)
	headPos.x_z = headPos.x_z + 0.5
	sounds:playSound("minecraft:entity.bat.hurt", headPos, 0.15)
end)

table.insert(patpat.player.onPat, function()
	---@type Minecraft.soundID
	local sound = math.random(10) == 10 and "minecraft:entity.bat.hurt" or "minecraft:entity.cat.purr"
	sounds:playSound(sound, util.eyePos(player), 0.15)
end)

do
	local floatSound = sounds["minecraft:entity.blaze.shoot"]

	---@type Util.AmbientParticle
	local steam = {
		id = client.isModLoaded("farmersdelight")
			and "farmersdelight:steam"
			or "minecraft:campfire_cosy_smoke",
		offset = vec(0, 0.5, 0),
		radius = 0.5,
		velocity = 0.01,
	}

	function steam.condition()
		steam.rate = player:isInWater() and 5 or 2.5
		return player:isWet()
	end

	---@type Util.AmbientParticle
	local flame = {
		id = "minecraft:flame",
		offset = vec(0, 1, 0),
		radius = 0.5,
		velocity = 0.005,
	}

	local strength

	---@param level number?
	function pings.strength(level)
		strength = level
	end

	if host:isHost() then
		util.tick:register(function()
			for _, effect in ipairs(host:getStatusEffects()) do
				if util.getEffect(effect.name) == "effect.minecraft.strength" then
					pings.strength(effect.amplifier)
				end
				return
			end
			pings.strength()
		end, 80)
	end

	function flame.condition()
		flame.id = strength and (strength > 0 or math.random(4) == 1)
			and "minecraft:soul_fire_flame"
			or "minecraft:flame"
		flame.rate = player:isWet() and 0.5 or (player:isOnFire() and 6 or 1)
		return world.exists()
	end

	util.newAmbientParticles(steam)
	util.newAmbientParticles(flame)

	local lastFloat = 0
	local lastBeenOnFire = false
	local lastFireTicks = 0
	local fireTicks = 0

	function util.tick()
		local float = originsapi.getPowerData(player, "snowy:blaze_float_resource") or 0
		local leftHanded = player:isLeftHanded()
		local modelType = player:getModelType() == "DEFAULT"
		local typeOffset = modelType and 0 or 0.5
		local handedOffset = leftHanded and (-6 + typeOffset) or (6 - typeOffset)
		local isOnFire = player:isOnFire()

		lastFireTicks = fireTicks

		if isOnFire then
			fireTicks = math.min(30, fireTicks + 1)
			renderer:setPrimaryFireTexture(strength and strength > 0
				and "minecraft:textures/block/soul_fire_1" or nil)
			renderer:setSecondaryFireTexture(strength and strength > 0
				and "snowy:textures/block/soul_fire_1" or nil)
		else
			fireTicks = math.max(-10, fireTicks - 1)
		end

		local beenOnFire = fireTicks > 20 or (isOnFire and float > 0)

		if float == 100 and lastFloat ~= 100 then
			util.playSound(floatSound)
			util.particleExplosion(flame.id,
				player:getPos():add(0, 1, 0),
				0,
				vec(0.1, 0.1, 0.1),
				20
			)
		end

		if fireTicks > lastFireTicks then
			animations.model.blazeborn_rods_transition:stop()
		end

		if beenOnFire then
			rods:setParentType(leftHanded and "LeftArm" or "RightArm")
			rods:setPos(handedOffset)

			rods:setOpacity((float > 0 or strength) and 0.8 or 0.7)

			local floatBonus = float > 0 and 0.15 or 0
			local strengthBonus = strength and 0.15 or 0
			local speed = 0.5 + floatBonus + strengthBonus

			animations.model.blazeborn_rods:setSpeed(leftHanded and -speed or speed)
		end

		if beenOnFire then
			rods:setVisible(beenOnFire)
		end

		animations.model.blazeborn_rods:setPlaying(beenOnFire)

		if not beenOnFire and lastBeenOnFire then
			animations.model.blazeborn_rods_transition:stop()
			animations.model.blazeborn_rods_transition:play()
		end

		if fireTicks == -10 then
			rods:setVisible(false)
		end

		lastFloat = float
		lastBeenOnFire = beenOnFire
	end
end
