local util = require "lib.util"
local carRoot = models.model.star
local carBody = carRoot
local exhaust = carBody.particle_exhaust
local carBackfire
local mountID = "boat"
local HUD = models.model.HUD
local sweep = animations.model.needle_sweep

-- ===============================================================
-- Action Wheel Setup
-- ===============================================================

local actionPage = action_wheel:newPage()
action_wheel:setPage(actionPage)

local state = {
    indicator = false,
    alwaysShowHUD = false,
    showCarModel = false,
    hidePlayerModel = false,
    rideHeight = 0,
}

local rideHeightAction
local suppressActionCallback = false

local function updateRideHeightTitle()
    if rideHeightAction then
        rideHeightAction:setTitle(
            "Adjust Vehicle Height (Scroll me, Click to reset) [§e" .. state.rideHeight .. "§r]"
        )
    end
end

---@type {
---     key: string,
---     title: string,
---     item: Minecraft.itemID,
---     toggleItem: Minecraft.itemID,
---     ping: string,
---}[]
local toggleDefinitions = {
    {
        key = "indicator",
        title = "Indicator Sound",
        item = "barrier",
        toggleItem = "note_block",
        ping = "toggleIndicator",
    },
    {
        key = "alwaysShowHUD",
        title = "Always Show HUD",
        item = "oak_boat",
        toggleItem = "player_head",
        ping = "toggleAlwaysShowHUD",
    },
    {
        key = "showCarModel",
        title = "Always Show Vehicle Model",
        item = "minecart",
        toggleItem = "furnace_minecart",
        ping = "toggleShowCarModel",
    },
    {
        key = "hidePlayerModel",
        title = "Hide PlayerModel",
        item = "grass_block",
        toggleItem = "glass_bottle",
        ping = "playerModelToggleAction",
    },
}

local toggleActions = {}
local pingByKey = {}
for _, def in ipairs(toggleDefinitions) do
    pingByKey[def.key] = def.ping
end

---@param action Action
---@param toggled boolean
local function setActionToggle(action, toggled)
    if not action then
        return
    end
    suppressActionCallback = true
    action:setToggled(toggled)
    suppressActionCallback = false
end

---@param key string
---@param value any
---@param fromPing boolean
local function applyToggle(key, value, fromPing)
    if state[key] == value then
        return
    end

    state[key] = value

    if key == "hidePlayerModel" then
        vanilla_model.ALL:setVisible(not value)
    end

    setActionToggle(toggleActions[key], value)

    if not fromPing then
        local pingName = pingByKey[key]
        if pingName then
            pings[pingName](value)
        end
    end
end

for _, def in ipairs(toggleDefinitions) do
    local action = actionPage:newAction()
        :title(def.title)
        :item(def.item)
        :toggleItem(def.toggleItem)
        :setOnToggle(function(value)
            if suppressActionCallback then
                return
            end
            applyToggle(def.key, value, false)
        end)

    toggleActions[def.key] = action
end

for _, def in ipairs(toggleDefinitions) do
    pings[def.ping] = function(value)
        applyToggle(def.key, value, true)
    end
end

local RIDE_HEIGHT_STEP = 0.2
rideHeightAction = actionPage:newAction()
    :title("Adjust Vehicle Height (Scroll me, Click to reset) [§e0§r]")
    :item("scaffolding")

---@param value number
---@param fromPing boolean
local function applyRideHeight(value, fromPing)
    if state.rideHeight == value then
        return
    end

    state.rideHeight = value
    updateRideHeightTitle()

    if not fromPing then
        pings.setRideHeight(value)
    end
end

function rideHeightAction.scroll(direction)
    local newHeight = state.rideHeight + (direction * RIDE_HEIGHT_STEP)
    applyRideHeight(newHeight, false)
end

function rideHeightAction.leftClick()
    applyRideHeight(0, false)
end

---@param value number
function pings.setRideHeight(value)
    applyRideHeight(value, true)
end

function pings.accel(state) ---@diagnostic disable-line: redefined-local
    accelState = state
end

updateRideHeightTitle()

-- ===============================================================
-- Simulation Configuration
-- ===============================================================

local IDLE_RPM = 800
local MAX_RPM = 9000
local RPM_ACCEL_BASE_RATE = 175
local RPM_DECEL_RATE = 0.08

local SHIFT_UP_RPM = MAX_RPM * (7500 / 9000)
local SHIFT_UP_TARGET_RPM = MAX_RPM * (5000 / 9000)
local SHIFT_DOWN_BLIP_RPM = MAX_RPM * (6000 / 9000)

---@type number[]
local gearShiftDownSpeed = {
    0,
    8,
    15,
    22,
    30,
}

---@type number[]
local gearRatio = {
    4.0,
    2.8,
    1.9,
    1.3,
    1.0,
}

local BACKFIRE_TRIGGER_HIGH_RPM = MAX_RPM * (7000 / 9000)
local BACKFIRE_TRIGGER_LOW_RPM = MAX_RPM * (6500 / 9000)
local GEAR_LIGHT_TRIGGER_RPM = MAX_RPM * (6500 / 9000)

local STEERING_SENSITIVITY = 45
local MAX_STEER_ANGLE = 60

local REAR_LOCK_MIN_SPEED = 7
local REAR_LOCK_CHANCE = 0.1
local REAR_LOCK_DURATION = 4

local WHEEL_ANIM_NORMAL_SPEED_FACTOR = 0.3
local WHEEL_ANIM_SPIN_FACTOR = 0.4

local BODY_ROLL_FACTOR = -0.15
local BODY_ROLL_SMOOTH_FACTOR = 0.4

local TACHO_SMOOTH_FACTOR = 0.8
local BOOST_SMOOTH_FACTOR = 0.1
local TACHO_MAX_ANGLE = 180
local TACHO_ANGLE_PER_RPM = TACHO_MAX_ANGLE / MAX_RPM

local BOOST_ANGLE_MAP = {
    IDLE = 0,
    ACCEL = 60,
    ENGINE_BRAKE = -20,
}

-- carBackfire:setPrimaryRenderType("EMISSIVE")

-- ===============================================================
-- Simulation State
-- ===============================================================

local engineRPM = 0
local prevEngineRPM = 0
local backfire = false
local backfireTimer = 0
local currentGear = 1
local isEngineOn = false
local prevSpeedMps = 0
local valveTriggered = false
local wheelSpinRate = 0
local steerAngle = 0
local isVehicleOnGround = false
local prevVehicleOnGround = true

local wheelZFrontRight = 8
local wheelZFrontLeft = -8
local AIR_WHEEL_Z = 6
local GROUND_WHEEL_Z = 8
local WHEEL_Z_SMOOTH = 0.5

local wheelZRearLeft = 8
local wheelZRearRight = -8

local landingBump = 0
local landingBumpTarget = 0
local AIR_HOLD_AMOUNT = 0.8
local LANDING_SINK_AMOUNT = -2
local LANDING_SMOOTH_UP = 0.1
local LANDING_SMOOTH_DOWN = 0.45
local LANDING_SMOOTH_SETTLE = 0.2

local isRearWheelLocked = false
local rearWheelLockTimer = 0
local frontWheelAnimSpeed = 0
local rearWheelAnimSpeed = 0
local currentBodyRoll = 0
local tachoAngle = 0
local boostAngle = BOOST_ANGLE_MAP.IDLE

local accelState = false
local prevAccelPressed = false
local syncTimer = 0

local engineLow = sounds["sounds.low"]
local engineLowLow = sounds["sounds.lowlow"]
local turboValves = {
    sounds["sounds.valve1"],
    sounds["sounds.valve2"],
    sounds["sounds.valve3"],
}

local accel = keybinds:fromVanilla("key.forward")

-- ===============================================================
-- Simulation Helpers
-- ===============================================================

---@param onGround boolean
local function updateLandingBump(onGround)
    if onGround and not prevVehicleOnGround then
        landingBumpTarget = LANDING_SINK_AMOUNT
    elseif not onGround then
        landingBumpTarget = AIR_HOLD_AMOUNT
    else
        landingBumpTarget = 0
    end

    local smooth = LANDING_SMOOTH_UP
    if landingBumpTarget < landingBump then
        smooth = LANDING_SMOOTH_DOWN
    elseif landingBumpTarget == 0 then
        smooth = LANDING_SMOOTH_SETTLE
    end

    landingBump = landingBump + (landingBumpTarget - landingBump) * smooth
end

---@param playerPos Vector3
---@param accelerating boolean
local function updateEngineSounds(playerPos, accelerating)
    engineLow:pos(playerPos)
    engineLowLow:pos(playerPos)

    engineLow:setPitch((engineRPM / 2000) ^ 1.1)
    engineLow:setVolume(accelerating and 0.7 or 0.2)

    engineLowLow:setPitch((engineRPM / 4000) + 1)
    engineLowLow:setVolume(accelerating and 0.8 or 0.3)
end

---@param speedMps number
local function updateWheelSteering(speedMps)
    if speedMps <= 0.1 then
        return
    end

    local velocity = player:getVelocity()
    local flatVelocity = vec(velocity.x, 0, velocity.z)
    local yaw = math.rad(player:getBodyYaw())
    local bodyDir = vec(math.sin(yaw), 0, -math.cos(yaw))
    local rightDir = vec(bodyDir.z, 0, -bodyDir.x)
    local sidewaysSpeed = flatVelocity:dot(rightDir)

    steerAngle = -math.max(-MAX_STEER_ANGLE,
        math.min(MAX_STEER_ANGLE, sidewaysSpeed * STEERING_SENSITIVITY))
end

---@param speedMps number
---@param accelerating boolean
---@param currentTime number
local function updateWheelAnimations(speedMps, accelerating, currentTime)
    local speedBased = speedMps * WHEEL_ANIM_NORMAL_SPEED_FACTOR
    local spinBased = 0

    if accelerating and speedMps < 40 then
        wheelSpinRate = (engineRPM / IDLE_RPM) * WHEEL_ANIM_SPIN_FACTOR
        spinBased = wheelSpinRate
    end

    local baseSpeed = math.max(speedBased, spinBased)

    if currentTime > rearWheelLockTimer then
        isRearWheelLocked = false
    end

    if not isRearWheelLocked and speedMps >= REAR_LOCK_MIN_SPEED and (speedMps - prevSpeedMps) < -0.1 then
        if math.random() < REAR_LOCK_CHANCE then
            isRearWheelLocked = true
            rearWheelLockTimer = currentTime + REAR_LOCK_DURATION
        end
    end

    frontWheelAnimSpeed = baseSpeed
    rearWheelAnimSpeed = isRearWheelLocked and 0 or baseSpeed
end

---@param onGround boolean
local function updateWheelOffsets(onGround)
    local targetFrontRight = onGround and GROUND_WHEEL_Z or -AIR_WHEEL_Z
    local targetFrontLeft = onGround and -GROUND_WHEEL_Z or AIR_WHEEL_Z
    wheelZFrontRight = wheelZFrontRight + (targetFrontRight - wheelZFrontRight) * WHEEL_Z_SMOOTH
    wheelZFrontLeft = wheelZFrontLeft + (targetFrontLeft - wheelZFrontLeft) * WHEEL_Z_SMOOTH

    local targetRearLeft = onGround and GROUND_WHEEL_Z or -AIR_WHEEL_Z
    local targetRearRight = onGround and -GROUND_WHEEL_Z or AIR_WHEEL_Z
    wheelZRearLeft = wheelZRearLeft + (targetRearLeft - wheelZRearLeft) * WHEEL_Z_SMOOTH
    wheelZRearRight = wheelZRearRight + (targetRearRight - wheelZRearRight) * WHEEL_Z_SMOOTH
end

local function updateBodyRoll()
    local safeSteer = steerAngle or 0
    local safeFactor = BODY_ROLL_FACTOR or -0.15
    local safeSmooth = BODY_ROLL_SMOOTH_FACTOR or 0.4

    local targetRoll = -safeSteer * safeFactor
    currentBodyRoll = currentBodyRoll + (targetRoll - currentBodyRoll) * safeSmooth
    carBody:setRot(0, 0, currentBodyRoll)
end

---@param accelerating boolean
---@param acceleration number
---@param speedMps number
local function updateBoostNeedle(accelerating, acceleration, speedMps)
    local targetBoost

    if accelerating then
        targetBoost = BOOST_ANGLE_MAP.ACCEL
        valveTriggered = false
    elseif acceleration < -0.01 and speedMps > 4.0 then
        targetBoost = BOOST_ANGLE_MAP.ENGINE_BRAKE
        if prevEngineRPM > 5000 and not valveTriggered then
            valveTriggered = true
            local valve = turboValves[math.random(#turboValves)]
            valve:pos(player:getPos())
            valve:setPitch(3.2 - math.random())
            valve:setVolume(0.2)
            valve:stop()
            valve:play()
        end
    else
        targetBoost = BOOST_ANGLE_MAP.IDLE
    end

    return targetBoost
end

-- ===============================================================
-- Event Handlers
-- ===============================================================

function events.tick()
    if not player:isLoaded() then
        return
    end

    local vehicle = player:getVehicle()
    local controlledVehicle = player:getControlledVehicle()
    local isPlayerOnGround = player:isOnGround()
    local vehicleIsBoat = false
    local inVehicle = false

    if vehicle then
        vehicleIsBoat = vehicle:getType():find(mountID) ~= nil
        isVehicleOnGround = vehicle:isOnGround()

        if vehicleIsBoat and controlledVehicle then
            inVehicle = true
        end
    else
        isVehicleOnGround = isPlayerOnGround
    end



    if host:isHost() then
        local isPressed = accel:isPressed()
        if isPressed ~= prevAccelPressed then
            pings.accel(isPressed)
            accelState = isPressed
            prevAccelPressed = isPressed
            syncTimer = 0
        else
            syncTimer = syncTimer + 1
            if syncTimer >= 40 then
                pings.accel(isPressed)
                syncTimer = 0
            end
        end
        -- Ensure host always has the correct state immediately
        accelState = isPressed
    end

    local accelerating = accelState
    local currentTime = world.getTime()

    updateLandingBump(isVehicleOnGround)

    local velocity = player:getVelocity()
    local speedMps = velocity:length() * 20
    local kmph = speedMps / 1000
    local mph = util.kilometerstomiles(kmph)
    local acceleration = speedMps - prevSpeedMps

    local showCar = false
    local showHUD = false

    if inVehicle then
        showCar = true
        showHUD = true
    elseif state.showCarModel then
        showCar = true
        showHUD = true
    elseif state.alwaysShowHUD then
        showHUD = true
    end

    HUD:setVisible(showHUD)

    local wantEngine = showHUD or showCar

    if wantEngine and not isEngineOn then
        isEngineOn = true
        currentGear = 1
        engineRPM = IDLE_RPM
        prevSpeedMps = 0
        currentBodyRoll = 0

        engineLow:play():loop(true)
        engineLowLow:play():loop(true)

        if showCar then
            if not state.hidePlayerModel then
                vanilla_model.LEFT_LEG:setVisible(false)
                vanilla_model.LEFT_PANTS:setVisible(false)
                vanilla_model.RIGHT_LEG:setVisible(false)
                vanilla_model.RIGHT_PANTS:setVisible(false)
            end

            local frontForward = animations.model.front_forward
            local rearForward = animations.model.rear_forward
            if frontForward then
                frontForward:play()
            end
            if rearForward then
                rearForward:play()
            end

            if sweep then
                sweep:setLoop("ONCE")
                sweep:setSpeed(2)
                sweep:play()
            end
        end
    elseif not wantEngine and isEngineOn then
        isEngineOn = false
        engineRPM = 0
        currentGear = 1
        currentBodyRoll = 0
        carBody:setRot(0, 0, 0)
        carBody:setPos(0, 0, 0)
        carRoot:setPos(0, 0, 0)

        engineLow:stop()
        engineLowLow:stop()
    end

    carRoot:setVisible(showCar)
    renderer:setRenderVehicle(not showCar)

    if state.hidePlayerModel then
        vanilla_model.ALL:setVisible(false)
    else
        vanilla_model.ALL:setVisible(true)
        vanilla_model.LEFT_LEG:setVisible(not showCar)
        vanilla_model.LEFT_PANTS:setVisible(not showCar)
        vanilla_model.RIGHT_LEG:setVisible(not showCar)
        vanilla_model.RIGHT_PANTS:setVisible(not showCar)
    end

    if showCar then
        carRoot:setScale(3.5, 3.5, 3.5)

        if inVehicle then
            carRoot:setPos(0, 11 + state.rideHeight, 0)
        else
            carRoot:setPos(0, 4.5 + state.rideHeight, 0)
        end

        carBody:setPos(0, landingBump, 0)
        vanilla_model.ALL:setPos(0, state.rideHeight, 0)
    else
        carBody:setPos(0, 0, 0)
        vanilla_model.ALL:setPos(0, 0, 0)
    end

    if isEngineOn then
        if currentGear < 5 and engineRPM >= SHIFT_UP_RPM then
            currentGear = currentGear + 1
            engineRPM = SHIFT_UP_TARGET_RPM
        end

        if currentGear > 1 and speedMps < gearShiftDownSpeed[currentGear] then
            local rpmBeforeShift = engineRPM
            currentGear = currentGear - 1
            if rpmBeforeShift < SHIFT_DOWN_BLIP_RPM then
                engineRPM = math.min(SHIFT_DOWN_BLIP_RPM, MAX_RPM)
                sounds:playSound(
                    "entity.firework_rocket.blast",
                    player:getPos(),
                    1,
                    math.random(8, 20) / 5,
                    false
                )
            end
        end

        if accelerating then
            local rpmIncrease = RPM_ACCEL_BASE_RATE * (gearRatio[currentGear] / gearRatio[1]) *
            (1 + (engineRPM / 14000))
            engineRPM = engineRPM + rpmIncrease
        else
            local targetRPM = IDLE_RPM + (speedMps * 40 / gearRatio[currentGear])
            if acceleration < -0.01 and engineRPM > targetRPM then
                engineRPM = engineRPM + (targetRPM - engineRPM) * RPM_DECEL_RATE
            elseif engineRPM > IDLE_RPM then
                engineRPM = engineRPM - 50
            end
        end

        engineRPM = math.max(IDLE_RPM, math.min(MAX_RPM, engineRPM))

        if prevEngineRPM >= BACKFIRE_TRIGGER_HIGH_RPM and engineRPM <= BACKFIRE_TRIGGER_LOW_RPM and engineRPM < prevEngineRPM then
            backfire = true
            sounds:playSound(
                "entity.firework_rocket.blast",
                player:getPos(),
                1,
                math.random(8, 20) / 5,
                false
            )
            backfireTimer = currentTime + 0.05
        end

        if backfire and currentTime > backfireTimer then
            backfire = false
        end

        prevEngineRPM = engineRPM

        if engineRPM > GEAR_LIGHT_TRIGGER_RPM then
            HUD.gear_indicator_lit:setVisible(true)
            if state.indicator then
                local gearSound = sounds["block.note_block.bit"]
                if gearSound then
                    gearSound:play():loop(false)
                    gearSound:pos(player:getPos())
                    gearSound:setPitch(2)
                end
            end
        else
            HUD.gear_indicator_lit:setVisible(false)
        end

        updateEngineSounds(player:getPos(), accelerating)
    else
        HUD.gear_indicator_lit:setVisible(false)
    end

    if showCar and isEngineOn then
        updateWheelSteering(speedMps)
        updateBodyRoll()
        updateWheelAnimations(speedMps, accelerating, currentTime)
        updateWheelOffsets(isVehicleOnGround)

        -- carRoot.wheel_FR:setRot(0, steerAngle, wheelZFrontRight)
        -- carRoot.wheel_FL:setRot(0, steerAngle, wheelZFrontLeft)
        -- carRoot.wheel_RL:setRot(0, 0, -wheelZRearLeft)
        -- carRoot.wheel_RR:setRot(0, 0, -wheelZRearRight)

        -- local frontForward = animations.model.front_forward
        -- local rearForward = animations.model.rear_forward
        -- if frontForward then
        --     frontForward:setSpeed(frontWheelAnimSpeed)
        -- end
        -- if rearForward then
        --     rearForward:setSpeed(rearWheelAnimSpeed)
        -- end

        if carBackfire then
            carBackfire.right_bf:setScale(1, 0.5 + math.random() * 0.7, 0.5 + math.random() * 0.7)
            carBackfire.left_bf:setScale(1, 0.5 + math.random() * 0.7, 0.5 + math.random() * 0.7)
            carBackfire:setVisible(backfireTimer > currentTime)
        end
    end

    if isEngineOn and showHUD then
        if not (sweep and sweep:isPlaying()) then
            local targetTacho = engineRPM * TACHO_ANGLE_PER_RPM
            local targetBoost = updateBoostNeedle(accelerating, acceleration, speedMps)

            tachoAngle = tachoAngle + (targetTacho - tachoAngle) * TACHO_SMOOTH_FACTOR
            boostAngle = boostAngle + (targetBoost - boostAngle) * BOOST_SMOOTH_FACTOR

            if HUD.rpm_needle then
                HUD.rpm_needle:setRot(0, 0, tachoAngle)
            end
            if HUD.boost_needle then
                HUD.boost_needle:setRot(0, 0, boostAngle)
            end

            local gearUV = (currentGear * 5) - 5
            HUD.gear_display:setUVPixels(0, gearUV)
        else
            HUD.rpm_needle:setRot(0, 0, 0)
            HUD.boost_needle:setRot(0, 0, 0)
            HUD.gear_display:setUVPixels(0, 0)
        end
    end

    if isEngineOn then
        prevSpeedMps = speedMps
    else
        prevSpeedMps = 0
    end

    prevVehicleOnGround = isVehicleOnGround
end

-- ===============================================================
-- Particle Effects
-- ===============================================================

-- function events.post_render()
--     if not isEngineOn then
--         return
--     end

--     local velocity = player:getVelocity()
--     local speed = velocity:length()
--     local yaw = math.rad(player:getBodyYaw())
--     local bodyDir = vec(math.sin(yaw), 0.17, -math.cos(yaw))
--     local dir = velocity:normalize()

--     -- if (wheelSpinRate > 2.3 and rearWheelAnimSpeed > 2 and accel:isPressed())
--     --     or (steerAngle > 15 and rearWheelAnimSpeed > 3) and not isVehicleOnGround then
--     --     local car = models.model.root.Car
--     --     local wheelRL = car.wheel_RL
--     --     local wheelRR = car.wheel_RR

--     --     local wheelParticles = {
--     --         wheelRL.wheelparticle_L1,
--     --         wheelRL.wheelparticle_L2,
--     --         wheelRL.wheelparticle_L3,
--     --         wheelRL.wheelparticle_L4,
--     --         wheelRR.wheelparticle_R1,
--     --         wheelRR.wheelparticle_R2,
--     --         wheelRR.wheelparticle_R3,
--     --         wheelRR.wheelparticle_R4,
--     --     }

--     --     local selected = wheelParticles[math.random(#wheelParticles)]
--     --     local aroundTireParticle = particles["poof"]

--     --     local offset = (dir * speed * 0.8) + vec(0, 0.05, 0)
--     --     local power = dir * speed * math.random() / 3
--     --     local spawnPos = selected:partToWorldMatrix():apply() + offset

--     --     local blockState = world.getBlockState(car:partToWorldMatrix():apply() - vec(0, 1, -4))
--     --     if blockState:getID() ~= "minecraft:air" and blockState:hasCollision() then
--     --         local scale = math.min(2,
--     --             ((wheelSpinRate / 160) * steerAngle) + (engineRPM / MAX_RPM / currentGear))
--     --         aroundTireParticle:spawn()
--     --             :setColor(0.9, 0.9, 0.9)
--     --             :setScale(scale)
--     --             :setPos(spawnPos)
--     --             :setVelocity(power)
--     --     end
--     -- end

--     -- if wheelSpinRate > 2 and rearWheelAnimSpeed > 1 and accel:isPressed() then
--     --     local car = models.model.root.Car
--     --     local wheelParticles = {
--     --         car.wheel_groundparticle_R,
--     --         car.wheel_groundparticle_L,
--     --     }

--     --     local selected = wheelParticles[math.random(#wheelParticles)]
--     --     local blockState = world.getBlockState(selected:partToWorldMatrix():apply() - vec(0, 0.1, 0))
--     --     local blockID = blockState:getID()

--     --     if blockID ~= "minecraft:air"
--     --         and blockID ~= "minecraft:cave_air"
--     --         and blockID ~= "minecraft:void_air"
--     --         and blockID ~= "minecraft:moving_piston"
--     --         and blockID ~= "minecraft:light"
--     --         and blockID ~= "minecraft:barrier"
--     --         and blockID ~= "minecraft:structure_void"
--     --         and blockState:hasCollision() then
--     --         local block = "minecraft:block " .. blockID
--     --         local normalized = velocity:normalize()
--     --         local offset = (normalized * speed * 0.8)
--     --             + vec(math.random(-10, 10) * 0.015, 0.05, math.random(-10, 10) * 0.015)
--     --         local power = bodyDir * engineRPM / 3000 *
--     --         vec(math.random() / 3, math.random(), math.random() / 3)
--     --         local spawnPos = selected:partToWorldMatrix():apply() + offset

--     --         local groundParticle = particles[block]
--     --         groundParticle:spawn()
--     --             :setColor(0.7, 0.7, 0.7)
--     --             :setScale(0.3)
--     --             :setPos(spawnPos)
--     --             :setVelocity(power)
--     --     end
--     -- end

--     if isEngineOn and backfire then
--         local exhaustPart = {
--             exhaust.leftexh,
--             exhaust.rightexh,
--         }

--         local selected = exhaustPart[math.random(#exhaustPart)]
--         local exhaustParticle = particles["smoke"]
--         local randomOffset = vec((math.random() - 0.5) * 0.3, (math.random() - 0.5) * 0.1,
--             (math.random() - 0.5) * 0.3)

--         local offset = (dir * speed * 0.2) + randomOffset
--         local power = bodyDir * vec(math.random() / 3, math.random() / 3, math.random() / 3)
--         local spawnPos = selected:partToWorldMatrix():apply() + offset

--         exhaustParticle:spawn()
--             :setColor(0.1, 0.1, 0.1)
--             :setScale(1)
--             :setPos(spawnPos)
--             :setVelocity(power)
--             :setLifetime(4 + math.random() * 4)
--     end
-- end

-- ===============================================================
-- HUD Placement
-- ===============================================================

local lastSize
function events.render()
    local size = -client.getScaledWindowSize()
    if size == lastSize then return end
    HUD:setScale(7)
    HUD:setPos(size.x / 1.2, size.y / 1.1, 0)
    size = lastSize
end
