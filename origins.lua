if not client.isModLoaded("origins") then return end

local originsapi = require "lib.thirdparty.OriginsAPI"
local util = require "lib.util"

local rods = models.model.root.blazebornRods:scale(0.7, 0.7, 0.7):setPrimaryRenderType("TRANSLUCENT")

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
    return originsapi.hasOrigin(player, "origins:blazeborn", "origins:origin") and player:isWet()
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
    return originsapi.hasOrigin(player, "origins:blazeborn", "origins:origin")
end

util.newAmbientParticles(steam)
util.newAmbientParticles(flame)

local lastFloat = 0
local lastBeenOnFire = false
local fireTicks = -10
local lastFireTicks = 0

function util.tick()
    if not originsapi.hasOrigin(player, "origins:blazeborn", "origins:origin") then return end

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
        rods:setVisible(true)
    end

    animations.model.blazeborn_rods:setPlaying(
        rods:getVisible() and not animations.model.blazeborn_rods_transition:isPlaying()
    )

    if not beenOnFire and lastBeenOnFire then
        animations.model.blazeborn_rods_transition:stop()
        animations.model.blazeborn_rods_transition:priority(1):play()
    end

    if animations.model.blazeborn_rods_transition:getTime() >= 0.49 or fireTicks == -10 then
        animations.model.blazeborn_rods_transition:setTime(0)
        rods:setVisible(false)
    end

    lastFloat = float
    lastBeenOnFire = beenOnFire
end

util.playerSoundReplace(sounds["minecraft:entity.blaze.hurt"], true, "hurt")
