---@class ManuelAnimation Thanks manuel!
local anim = {}

function anim:new()
    local keyframes = {}
    local frame = 0
    local length = 0
    local loop = false
    local playing = false

    function events.TICK()
        if not playing then return end
        if keyframes[frame] then keyframes[frame]() end
        frame = frame + 1
        if frame > length then
            frame = 0
            if not loop then playing = false end
        end
    end

    ---@class ManuelAnimation.obj
    local module = {}

    module = {
        keyframe = function(time, func)
            length = math.max(length, time)
            keyframes[time] = func
            return module
        end,
        restart = function()
            playing = true
            frame = 0
            return module
        end,
        play = function()
            playing = true
            return module
        end,
        stop = function()
            playing = false
            frame = 0
            return module
        end,
        setPlaying = function(state)
            playing = state
            if not state then module.frame = 0 end
            return module
        end,
        setTime = function(time)
            module.frame = time
            return module
        end,
        loop = function(state)
            loop = state
            return module
        end,
        isPlaying = function() return playing end,
    }

    return module
end

return anim