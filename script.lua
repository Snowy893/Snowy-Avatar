local smoothie = require("lib.thirdparty.Smoothie")
local animatedText = require("lib.thirdparty.animatedText")
local depthEffect = require("lib.thirdparty.depth_effect")
local afk = require("lib.afk")
local doRandomly = require("lib.doRandomly")

local page = action_wheel:newPage()
local tickCounter = 0
local wasAimingLastTick = false

animatedText.new("afk", models.model.root.Body, vec(-7, 4, -6), vec(0.3, 0.3, 0.3), "BILLBOARD", "")

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
	depthEffect.apply(models.model.root.Head.Eyes.LeftEye.layer4, -16)
}

------------------------------------------------------------------

nameplate.ALL:setText(toJson {
	text = "Snowy:blahaj:",
	hoverEvent = {
	  action = "show_text",
	  contents = "${name}"
	}
})

------------------------------------------------------------------

smoothie:newEye(models.model.root.Head.Eyes)
	:leftOffsetStrength(0.25)
	:rightOffsetStrength(0.25)
	:topOffsetStrength(0.5)
	:bottomOffsetStrength(0.5)

doRandomly:new(function () animations.model.blink:play() end):register()

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
	sounds:playSound("minecraft:entity.creeper.primed", player:getPos() + vec(0, 1, 0))
	animations.model.creeper:play()
end

function CreeperInstruction()
	models.model.root.Head.Eyes:setVisible(true)
	models.model.root.Head.CreeperEyes:setVisible(false)
end

local doAfkAction = page:newAction()
	:title("Do Afk Animation")
	:item("minecraft:red_bed")
	:hoverColor(1, 0, 1)
	:onToggle(pings.sendDoAfk)
	:toggled(config:load("do_afk"))

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
page:setAction(3, doAfkAction)
page:setAction(2, sadChairAction)
page:setAction(1, creeperAction)

------------------------------------------------------------------

---@param toggle boolean
local function noddingOffToggle(toggle)
	--blink.enabled = not toggle
	animations.model.afkStart:setPlaying(toggle)
	if not toggle then
		animations.model.afkLoop:stop()
		models.model.root.Head:setOffsetRot(0)
	end
end

---@param toggle boolean
local function sleepyTextToggle(toggle)
	if toggle then
		animatedText.setText("afk", {text = "Zzz", color = "#605b85"})
		for i, v in pairs(animatedText.getTask("afk").textTasks) do
			v.task:outline(true)
		end
	else
		animatedText.setText("afk", "")
	end
end

local function noddingOff(ticks, delta)
	models.model.root.Head:setOffsetRot(math.sin((ticks + delta) / 16))
end

local function sleepyText(ticks, delta)
	for i, v in pairs(animatedText.getTask("afk").textTasks) do
		animatedText.transform("afk", vec(-i * 1.1, (math.sin((ticks + delta) / 8 + i) * .5) + (i * 1.3), 0), nil, nil, v)
	end
end

---comment `:getTags()` returns the item tags, `:getTag()` or `.tag` returns data components
---@param itemStack ItemStack
---@return boolean
local function isCrossbowCharged(itemStack)
	return itemStack:getTag()["ChargedProjectiles"] ~= nil and itemStack:getTag()["ChargedProjectiles"][1] ~= nil
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

	if isCrossbowCharged(heldRightItem) then
		aiming = true
	elseif isCrossbowCharged(heldLeftItem) then
		aiming = true
	end

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
	tickCounter = tickCounter + 1
end

function events.RENDER(delta)
	for i, depthObject in pairs(depthObjects) do
		local depth = math.cos((tickCounter + delta) * 0.1 + i) * 4
   		depthObject:setDepth(depth)
	end
end

afk.register("ON_AFK_CHANGE", noddingOffToggle)
afk.register("ON_DEEP_AFK_CHANGE", sleepyTextToggle)
afk.register("ON_RENDER_AFK_LOOP", noddingOff)
afk.register("ON_RENDER_DEEP_AFK_LOOP", sleepyText)
afk.register("ON_START_AFK_LOOP", function () animations.model.afkLoop:setPlaying(true) end)
afk.register("ON_TICK_NOT_AFK", aimingAnimationChecks)
