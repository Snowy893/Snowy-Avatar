--#region imports
local animatedText = require "lib.thirdparty.animatedText"
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
local head = root.torso.Head
local body = root.torso.waist.Body
local eyes = head.eyes
local creeperEyes = head.creepereyes:scale(1.2, 1.2, 1.2)
local skull = model.Skull
local skullEyes = skull.eyes2
local skullCreeperEyes = skull.creepereyes2:scale(1.2, 1.2, 1.2)
local rightArm = root.torso.waist.RightArm
local leftArm = root.torso.waist.LeftArm
local rightItemPivot = rightArm.RightItemPivot
local leftItemPivot = leftArm.LeftItemPivot

eyes.righteye.background:setPrimaryRenderType("EMISSIVE_SOLID")
eyes.lefteye.background:setPrimaryRenderType("EMISSIVE_SOLID")
skullEyes.righteye2.background:setPrimaryRenderType("EMISSIVE_SOLID")
skullEyes.lefteye2.background:setPrimaryRenderType("EMISSIVE_SOLID")

------------------------------------------------------------------

local name = "Snowy :blahaj:"
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

---@param toggle boolean
local onSleep = util.onchange(function(toggle)
	animations.model.afkLoop:setPlaying(toggle)
	if toggle then
		animatedText.setText("sleeping", { text = "Zzz", color = "#605b85" })
		animatedText.applyFunc("sleeping", function(task)
			task:outline(true)
		end)
	else
		animatedText.setText("sleeping", "")
	end
end)

---@param vehicle Entity?
local onVehicle = util.onchange(function(vehicle)
	-- local isBoat = vehicle and vehicle:getType():find("boat")
	-- -- local isDriving = vehicle and vehicle:getControllingPassenger() == player
	
	-- if host:isHost() then
	-- 	   avatar:store("isInBoat", util.toboolean(isBoat))
	-- end

	-- renderer:setRenderVehicle(not isBoat)

	-- -- models.model.boat:setVisible(isBoat and isDriving)
end)

---@alias Hand
---| { RIGHT: boolean, LEFT: boolean }

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
---@param parts ModelPart[]
---@return {[string]: ModelPart[]}
local layerObjects = (function(parts)
	local tbl = {}
	for _, part in ipairs(parts) do
		local partName = part:getName()
		
		tbl[partName] = {}

		local index = 1
		local layer = part["layer" .. index] or part["depthLayer" .. index]

		while layer do
			table.insert(tbl[partName], layer)
			index = index + 1
			layer = part["layer" .. index] or part["depthLayer" .. index]
		end
	end
	return tbl
end)({ eyes.righteye, eyes.lefteye })

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

animatedText.new(
	"afk",
	body,
	vec(-7, 5.5, -6),
	vec(0.35, 0.35, 0.35),
	"BILLBOARD",
	""
)

animatedText.new(
	"sleeping",
	body,
	vec(0, 5, -6),
	vec(0.35, 0.35, 0.35),
	"BILLBOARD",
	""
)

vanilla_model.PLAYER:setVisible(false)
root.sadchair:setVisible(false)
creeperEyes:setVisible(false)
skullCreeperEyes:setVisible(false)

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
    local sleeping = player:getPose() == "SLEEPING"
	local crouching = player:isCrouching()
    local vehicle = player:getVehicle()
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
	local hand = (mainHandActive ~= leftHanded) and { RIGHT = true } or { LEFT = true } ---@type Hand

	local doubleCrouchHand ---@type Hand
	local singleCrouchHand ---@type Hand
	local spyglassHand ---@type Hand
	local bowCrouchHand ---@type Hand

	if useAction == "SPYGLASS" then
		spyglassHand = hand
	elseif crouching then
		if useAction == "BOW" then
			bowCrouchHand = hand
		elseif util.checkUseAction("TOOT_HORN", "SPEAR", "BLOCK") then
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
    onSleep(sleeping)
    onVehicle(vehicle)
end

function events.render(delta, context)
	local time = world.getTime(delta)

	if player:getPose() == "SLEEPING" then
		animatedText.applyFunc("sleeping", function(_, i)
			return vec(-i * 1.1, (math.sin(time / 8 + i) * .5) + (i * 1.3), 0)
		end)
	end

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

afk.new(210)
	:register("ON_CHANGE", function(toggle)
    	if toggle then
			animatedText.setText("afk", { text = "Zzz", color = "#605b85" })
			animatedText.applyFunc("afk", function(task)
				task:outline(true)
			end)
		else
			animatedText.setText("afk", "")
		end
    end)
	:register("ON_RENDER_LOOP", function(delta)
		animatedText.applyFunc("afk", function(_, i)
			return vec(-i * 1.1, (math.sin(world.getTime(delta) / 8 + i) * .5) + (i * 1.3), 0)
		end)
	end)

---@param id Minecraft.dimensionID
enviLib.register("DIMENSION", function(id)
	local endIndex = select(2, id:find(":"))
	local dimension = id:sub(endIndex + 1)

	local switch = {
		the_end = function()
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
		end,
		the_nether = function()
			eyeColor:color({ color = vec(0.91, 0.65, 0.88) })
			eyeColor:color({
				color = vec(0.82, 0.2, 0.75),
				type = "depthBackground",
			})
		end,
		overworld = function()
			eyeColor:color({ color = vec(0.85, 0.66, 1) })
			eyeColor:color({
				color = vec(0.75, 0.52, 0.9),
				type = "depthBackground",
			})
		end,
    }
	
	if switch[dimension] then switch[dimension]()
	else switch.overworld() end
end)

---@param headPos Vector3
table.insert(patpat.head.oncePat, function(_, headPos)
	animations.model.skullPat:stop()
	animations.model.skullPat:play()
	headPos.x_z = headPos.x_z + 0.5
	sounds:playSound("minecraft:entity.bat.hurt", headPos, 0.15)
end)

table.insert(patpat.player.onPat, function()
	---@type Minecraft.soundID
	local sound = math.random(10) == 10 and "minecraft:entity.bat.hurt" or "minecraft:entity.cat.purr"
	sounds:playSound(sound, util.eyePos(player), 0.15)
end)
