--#region imports
local smoothie = require("lib.thirdparty.Smoothie")
local animatedText = require("lib.thirdparty.animatedText")
local depthEffect = require("lib.thirdparty.depth_effect")

local util = require("lib.util")
local afk = require("lib.afk")
local doRandomly = require("lib.doRandomly")
local enviLib = require("lib.enviLib")
--#endregion

local page = action_wheel:newPage()
local isAfk = false
local wasAimingLastTick = false
local wasSleeping = false

animatedText.new("afk", models.model.root.Body, vec(-7, 5.5, -6), vec(0.35, 0.35, 0.35),
	"BILLBOARD", "")
animatedText.new("sleeping", models.model.root.Head, vec(0, 5, -6), vec(0.35, 0.35, 0.35),
	"BILLBOARD", "")

vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(true)

models.model.root.SadChair:setVisible(false)
models.model.root.Head.CreeperEyes:setVisible(false)

models.model.root.Head.Eyes:setPrimaryRenderType("CUTOUT_EMISSIVE_SOLID")
models.model.root.Head.CreeperEyes:setPrimaryRenderType("EYES")

local depthObjects = {
	depthEffect.apply(models.model.root.Head.Eyes.RightEye.layer1, 64),
	depthEffect.apply(models.model.root.Head.Eyes.RightEye.layer2, 32),
	depthEffect.apply(models.model.root.Head.Eyes.RightEye.layer3, 16),
	depthEffect.apply(models.model.root.Head.Eyes.RightEye.layer4, -16),
	depthEffect.apply(models.model.root.Head.Eyes.LeftEye.layer1, 64),
	depthEffect.apply(models.model.root.Head.Eyes.LeftEye.layer2, 32),
	depthEffect.apply(models.model.root.Head.Eyes.LeftEye.layer3, 16),
	depthEffect.apply(models.model.root.Head.Eyes.LeftEye.layer4, -16),
}

------------------------------------------------------------------

nameplate.ALL:setText(toJson {
	text = "Snowy:blahaj:",
	hoverEvent = {
		action = "show_text",
		contents = "${name}",
	},
})

------------------------------------------------------------------

smoothie:newEye(models.model.root.Head.Eyes)
	:leftOffsetStrength(0.25)
	:rightOffsetStrength(0.25)
	:topOffsetStrength(0.5)
	:bottomOffsetStrength(0.5)

doRandomly.new(function() animations.model.blink:play() end)
	:setCondition(function() return not isAfk and player:getPose() ~= "SLEEPING" end)
	:register()

------------------------------------------------------------------

action_wheel:setPage(page)

---@param toggle boolean
function pings.sadChair(toggle)
	models.model.root.SadChair:setVisible(toggle)
	animations.model.sadChair:setPlaying(toggle)
end

function pings.creeper()
	models.model.root.Head.Eyes:setVisible(false)
	models.model.root.Head.CreeperEyes:setVisible(true)
	sounds:playSound("minecraft:entity.creeper.primed", player:getPos():add(vec(0, 1, 0)))
	animations.model.creeper:play()
end

function CreeperInstruction()
	models.model.root.Head.Eyes:setVisible(true)
	models.model.root.Head.CreeperEyes:setVisible(false)
end

local sadChairAction = page:newAction()
	:title("Sad Chair")
	:item("minecraft:smooth_quartz_stairs")
	:hoverColor(1, 0, 1)
	:onToggle(pings.sadChair)

local creeperAction = page:newAction()
	:title("Creeper")
	:item("minecraft:creeper_head")
	:hoverColor(1, 0, 1)
	:onLeftClick(pings.creeper)

page:setKeepSlots(false)
page:setAction(2, sadChairAction)
page:setAction(1, creeperAction)

------------------------------------------------------------------

local function resetEyeColor()
	util.deepLoop(models.model.root.Head.Eyes:getChildren(), function(part)
		part.background:setColor()
		for i = 1, 4 do
			part["layer" .. tostring(i)]:setColor()
		end
	end)
end

---@param tbl table
local function setEyeColor(tbl)
	resetEyeColor()
    for _, value in ipairs(tbl) do
        if value.type == "eyes" then
            util.deepLoop(models.model.root.Head.Eyes:getChildren(), function(part)
                part.background:setColor(value.color)
				for i = 1, 4 do
					part["layer"..tostring(i)]:setColor(value.color)
				end
            end)
        elseif value.type == "layers" then
            for i = 1, 4 do
				models.model.root.Head.Eyes.RightEye["layer" .. tostring(i)]:setColor(value.color)
				models.model.root.Head.Eyes.LeftEye["layer" .. tostring(i)]:setColor(value.color)
            end
        elseif value.type:find("layer") then
			models.model.root.Head.Eyes.RightEye[value.type]:setColor(value.color)
			models.model.root.Head.Eyes.LeftEye[value.type]:setColor(value.color)
		elseif value.type == "background" then
			models.model.root.Head.Eyes.RightEye.background:setColor(value.color)
			models.model.root.Head.Eyes.LeftEye.background:setColor(value.color)
		end
	end
end

---comment `:getTags()` returns the item tags, `:getTag()` or `.tag` returns data components
---@param itemStack ItemStack
---@return boolean
local function isCrossbowCharged(itemStack)
	return itemStack:getTag()["ChargedProjectiles"] ~= nil and
		itemStack:getTag()["ChargedProjectiles"][1] ~= nil
end

---comment Checks if the player is using an item with `action` that is either `"BOW"` or `"SPEAR"`. EXCLUDES CROSSBOWS!
---@param itemStack ItemStack
---@return boolean
local function isRangedWeaponDrawn(itemStack)
	if player:isUsingItem() then
		local useAction = itemStack:getUseAction()
		if (useAction == "BOW") or (useAction == "SPEAR") then return true end
	end
	return false
end

local function aimingAnimationChecks()
	local aiming = false
	local leftHanded = player:isLeftHanded()
	local heldRightItem = player:getHeldItem(leftHanded)
	local heldLeftItem = player:getHeldItem(not leftHanded)

	aiming = isCrossbowCharged(heldRightItem) or isCrossbowCharged(heldLeftItem)

	if not aiming then
		aiming = isRangedWeaponDrawn(heldRightItem) or isRangedWeaponDrawn(heldLeftItem)
	end

	if aiming then
		if not wasAimingLastTick then
			animations.model.aiming:play()
			wasAimingLastTick = true
		end
	else
		if wasAimingLastTick then
			animations.model.aiming:stop()
			wasAimingLastTick = false
		end
	end
end

function events.TICK()
    if player:getPose() == "SLEEPING" then
        if not wasSleeping then
            animations.model.afkLoop:play()
            animatedText.setText("sleeping", { text = "Zzz", color = "#605b85" })
            for _, v in pairs(animatedText.getTask("afk").textTasks) do
                v.task:outline(true)
            end
            wasSleeping = true
        end
    else
        if wasSleeping then
            animations.model.afkLoop:stop()
            animatedText.setText("sleeping", "")
            wasSleeping = false
        end
    end
end

function events.RENDER(delta)
	if player:getPose() == "SLEEPING" then
		for i, v in pairs(animatedText.getTask("sleeping").textTasks) do
			animatedText.transform(
				"sleeping", vec(-i * 1.1,
					(math.sin((world.getTime(delta)) / 8 + i) * .5) + (i * 1.3), 0),
				nil, nil, v
			)
		end
	else
		animatedText.setText("sleeping", "")
	end
	for i, depthObject in pairs(depthObjects) do
		local depth = math.cos((world.getTime(delta)) * 0.1 + i) * 4
		depthObject:setDepth(depth)
	end
end

afk.new(180)
	:register("ON_CHANGE", function (toggle)
		isAfk = toggle
		animations.model.afkStart:setPlaying(toggle)
		if not toggle then
			animations.model.afkLoop:stop()
			models.model.root.Head:setOffsetRot(0)
		end
	end)
	:register("ON_RENDER_LOOP", function (delta)
		if animations.model.afkStart:isStopped() then
			animations.model.afkLoop:play()
		end
		models.model.root.Head:setOffsetRot(math.sin(world.getTime(delta) / 14))
	end)
	:register("ON_TICK_NOT_AFK", aimingAnimationChecks)

afk.new(210)
	:register("ON_CHANGE", function (toggle)
		if toggle then
			animatedText.setText("afk", { text = "Zzz", color = "#605b85" })
			for i, v in pairs(animatedText.getTask("afk").textTasks) do
				v.task:outline(true)
			end
		else
			animatedText.setText("afk", "")
		end
	end)
	:register("ON_RENDER_LOOP", function (delta)
		for i, v in pairs(animatedText.getTask("afk").textTasks) do
			animatedText.transform("afk",
				vec(-i * 1.1, (math.sin(world.getTime(delta) / 8 + i) * .5) + (i * 1.3), 0), nil, nil, v)
		end
    end)

enviLib.register("DIMENSION", function(dim)
	if dim == "minecraft:overworld" then
        resetEyeColor()
    elseif dim == "minecraft:the_nether" then
        setEyeColor({
            {type = "eyes", color = vec(1, 0.42, 0.75)}
		})
    elseif dim == "minecraft:the_end" then
        setEyeColor({
            {type = "layers", color = vec(1, 0.5, 0.85)},
			{type = "background", color = vec(0.45, 0.45, 0.45)}
		})
	end
end)
