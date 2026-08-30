--#region imports
local depthEffect = require "lib.thirdparty.depth_effect"
local patpat = require "lib.thirdparty.patpat"
local util = require "lib.util"
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
local creeperEyes = head.creeperEyes:scale(1.2, 1.2, 1.2)
local skull = model.Skull
local skullEyes = skull.eyes2
local skullCreeperEyes = skull.creeperEyes2:scale(1.2, 1.2, 1.2)
local rightArm = root.RightArm
local leftArm = root.LeftArm
local rightItemPivot = rightArm.RightItemPivot
local leftItemPivot = leftArm.LeftItemPivot

vanilla_model.PLAYER:setVisible(false)
eyes.rightEye.background:setPrimaryRenderType("EMISSIVE_SOLID")
eyes.leftEye.background:setPrimaryRenderType("EMISSIVE_SOLID")
skullEyes.rightEye2.background:setPrimaryRenderType("EMISSIVE_SOLID")
skullEyes.leftEye2.background:setPrimaryRenderType("EMISSIVE_SOLID")

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
		eyes.rightEye:setPos(pos)
		eyes.rightEye:setScale(scale)
		eyes.leftEye:setPos()
		eyes.leftEye:setScale()
		animations.model.squintLeft:play()
		animations.model.squintRight:stop()
	elseif hand and hand.LEFT then
		eyes.leftEye:setPos(pos)
		eyes.leftEye:setScale(scale)
		eyes.rightEye:setPos()
		eyes.rightEye:setScale()
		animations.model.squintRight:play()
		animations.model.squintLeft:stop()
	else
		eyes.rightEye:setPos()
		eyes.rightEye:setScale()
		eyes.leftEye:setPos()
		eyes.leftEye:setScale()
		animations.model.squintLeft:stop()
		animations.model.squintRight:stop()
	end
end)

---@param hand Hand
local onCrouchArmOffsetRot = util.onchange(function(hand)
	local rightRot = hand.RIGHT and 20 or nil
	local leftRot = hand.LEFT and 20 or nil
	vanilla_model.RIGHT_ARM:setOffsetRot(rightRot)
	vanilla_model.LEFT_ARM:setOffsetRot(leftRot)
end)

------------------------------------------------------------------

---@type auria.depth_effect.obj[]
local depthObjects = {}
table.insert(depthObjects, depthEffect.apply(eyes.rightEye.layer1, 1))
table.insert(depthObjects, depthEffect.apply(eyes.leftEye.layer1, 1))

------------------------------------------------------------------

local eyeColor = colorlib.newColorMulti({
	eyes.rightEye,
	eyes.leftEye,
	skullEyes.rightEye2,
	skullEyes.leftEye2,
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
	
	local mainHandActive = player:getActiveHand() == "MAIN_HAND"
	local leftHanded = player:isLeftHanded()
	local activeHand = mainHandActive ~= leftHanded and "RIGHT" or "LEFT"

	local crouchHand = {} ---@type Hand
	local spyglassHand = {} ---@type Hand
	local bowCrouchHand = {} ---@type Hand
	local rightArmRot = vectors.vec3(0, 0, 0)
	local leftArmRot = vectors.vec3(0, 0, 0)

	if useAction == "SPYGLASS" then
		spyglassHand[activeHand] = true
	elseif crouching and useAction == "BOW" then
		bowCrouchHand[activeHand] = true
	elseif crouching and util.compare(useAction, "TOOT_HORN", "SPEAR", "BLOCK") then
		crouchHand[activeHand] = true
	else
		local rightItem = player:getHeldItem(leftHanded)
		local leftItem = player:getHeldItem(not leftHanded)
		if util.crossbowCharged(rightItem) or util.crossbowCharged(leftItem) then
			crouchHand.RIGHT = crouching
			crouchHand.LEFT = crouching
		end
	end

	onAimingBowWhileCrouching(bowCrouchHand)
	onSpyglass(spyglassHand)

	rightArmRot.x = crouchHand.RIGHT and 20 or 0
	leftArmRot.x = crouchHand.LEFT and 20 or 0

	vanilla_model.RIGHT_ARM:setOffsetRot(rightArmRot)
	vanilla_model.LEFT_ARM:setOffsetRot(leftArmRot)

    onTeamChange(color)
end

function events.render(delta, context)
	local time = world.getTime(delta)

	if context == "FIRST_PERSON" then return end

	local cameraPos = client.getCameraPos()
	local eyePos = util.eyePos(player, delta)
	local distance = math.abs((cameraPos - eyePos):length())

	for i, depthObject in ipairs(depthObjects) do
		local depth = math.cos(time * 0.1 + i) * math.min(1, distance / 4)
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

local dimensions = {}

function dimensions.the_end()
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

function dimensions.the_nether()
	eyeColor:color({ color = vec(0.91, 0.65, 0.88) })
	eyeColor:color({
		color = vec(0.82, 0.2, 0.75),
		type = "depthBackground",
	})
end

function dimensions.overworld()
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
	
	if dimensions[dimension] then dimensions[dimension]()
	else dimensions.overworld() end
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

avatar:store("patpat.yesPats", true)
