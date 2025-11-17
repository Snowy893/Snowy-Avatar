---@class Afk
local afk = {}

---@alias Afk.event
---| "ON_AFK_CHANGE"
---| "ON_DEEP_AFK_CHANGE"
---| "ON_START_AFK_LOOP"
---| "ON_RENDER_AFK_LOOP"
---| "ON_RENDER_DEEP_AFK_LOOP"
---| "ON_TICK_NOT_AFK"

local afkEvents = {
    ON_AFK_CHANGE = {},
    ON_DEEP_AFK_CHANGE = {},
    ON_START_AFK_LOOP = {},
    ON_RENDER_AFK_LOOP = {},
    ON_RENDER_DEEP_AFK_LOOP = {},
    ON_TICK_NOT_AFK = {}
}

local afkCheckTickRate = 5
local afkDelay = 180*afkCheckTickRate
local deepAfkDelay = 60*afkCheckTickRate + afkDelay

local doAfk = nil
local isAfk = false
local wasAfk = false
local isDeepAfk = false
local wasDeepAfk = false
local loopAfk = false

local tickCounter = 0
local afkTime = 0
local oldAfkTime = 0
local position
local rotation
local oldPosition
local oldRotation

---@param event? Afk.event
---@param func function
function afk.register(event, func)
    table.insert(afkEvents[event], func)
end

---@param state boolean
function afk.setLoopAfk(state)
    loopAfk = state
end

---@param state boolean
function pings.sendDoAfk(state)
    if doAfk == state then return end
    doAfk = state
    if host:isHost() then config:save("do_afk", state) end
    if not state then
        for _, func in pairs(afkEvents["ON_AFK_CHANGE"]) do func(false) end
        for _, func in pairs(afkEvents["ON_DEEP_AFK_CHANGE"]) do func(false) end
        loopAfk = false
        isAfk = false
		wasAfk = false
		isDeepAfk = false
		wasDeepAfk = false
    end
end

function StartInstruction()
    for _, func in pairs(afkEvents["ON_AFK_LOOP_START"]) do func() end
	loopAfk = true
end

function events.ENTITY_INIT()
    if doAfk == nil then pings.sendDoAfk(config:load("do_afk")) end
end

function events.TICK()
    if doAfk and tickCounter % afkCheckTickRate == 0 then
        if (position == oldPosition) and (rotation == oldRotation) then afkTime = afkTime + 1 else afkTime = 0 end

        wasAfk = isAfk
        wasDeepAfk = isDeepAfk
        oldPosition = position
        oldRotation = rotation
        position = user:getPos()
        rotation = user:getRot()

        if afkTime ~= 0 then
            if afkTime >= afkDelay then
                isAfk = true
                if afkTime >= deepAfkDelay then
                    isDeepAfk = true
                end
            end
        else
            if oldAfkTime ~= 0 then
                isAfk = false
                isDeepAfk = false
            end
        end

        oldAfkTime = afkTime

        if isAfk ~= wasAfk then
            if not isAfk then loopAfk = false end
            for _, func in pairs(afkEvents["ON_AFK_CHANGE"]) do func(isAfk) end
        end
        if isDeepAfk ~= wasDeepAfk then
            for _, func in pairs(afkEvents["ON_DEEP_AFK_CHANGE"]) do func(isDeepAfk) end
        end
	end
    if not doAfk or not isAfk then for _, func in pairs(afkEvents["ON_TICK_NOT_AFK"]) do func() end end
    tickCounter = tickCounter + 1
end

function events.RENDER(delta, context)
    if not loopAfk then return end
    for _, func in pairs(afkEvents["ON_RENDER_AFK_LOOP"]) do func(tickCounter, delta, context) end
    if not isDeepAfk then return end
    for _, func in pairs(afkEvents["ON_RENDER_DEEP_AFK_LOOP"]) do func(tickCounter, delta, context) end
end

return afk