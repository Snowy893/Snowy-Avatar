local squapi = require("lib.SquAPI")
local animatedText = require("lib.animatedText")
local afk = require("afk")

local page = action_wheel:newPage()
local wasAimingLastTick = false

animatedText.new("afk", models.model.root.Body, vec(-7, 4, -6), vec(0.3, 0.3, 0.3), "BILLBOARD", "")

vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(true)

models.model.root.SadChair:setVisible(false)
models.model.root.Head.CreeperEyes:setVisible(false)

models:setSecondaryRenderType("EYES")

------------------------------------------------------------------

nameplate.ALL:setText(toJson {
	text = "Snowy:blahaj:",
	hoverEvent = {
	  action = "show_text",
	  contents = "${name}"
	}
})

------------------------------------------------------------------

---@diagnostic disable-next-line: undefined-field
squapi.eye:new(
	models.model.root.Head.Eyes, --element
	.25,                      --(.25)leftdistance
	.25                       --(1.25)rightdistance
)

---@diagnostic disable-next-line: undefined-field
local blink = squapi.randimation:new(animations.model.blink)

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
local function afkAnimationToggle(toggle)
	blink.enabled = not toggle
	animations.model.afkStart:setPlaying(toggle)
	if not toggle then
		animations.model.afkLoop:stop()
		models.model.root.Head:setOffsetRot(0)
	end
end

---@param toggle boolean
local function deepAfkAnimationToggle(toggle)
	if toggle then
		animatedText.setText("afk", {text = "Zzz", color = "#605b85"})
		for i, v in pairs(animatedText.getTask("afk").textTasks) do
			v.task:outline(true)
		end
	else
		animatedText.setText("afk", "")
	end
end

local function noddingOff(tickCounter, delta)
	models.model.root.Head:setOffsetRot(math.sin((tickCounter + delta) / 16))
end

local function sleepyText(tickCounter, delta)
	for i, v in pairs(animatedText.getTask("afk").textTasks) do
		animatedText.transform("afk", vec(-i * 1.1, (math.sin((tickCounter + delta) / 8 + i) * .5) + (i * 1.3), 0), nil, nil, v)
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

afk.register("ON_AFK_CHANGE", afkAnimationToggle)
afk.register("ON_DEEP_AFK_CHANGE", deepAfkAnimationToggle)
afk.register("ON_RENDER_AFK_LOOP", noddingOff)
afk.register("ON_RENDER_DEEP_AFK_LOOP", sleepyText)
afk.register("ON_START_AFK_LOOP", function () animations.model.afkLoop:setPlaying(true) end)
afk.register("ON_TICK_NOT_AFK", aimingAnimationChecks)
