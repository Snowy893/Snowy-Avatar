if not client.isModLoaded("sillyplugin") and not client.isModLoaded("goofyplugin") and not client.isModLoaded("extura") then return end

local util = require "lib.util"
local lift = require "lib.thirdparty.Lift"

lift.config.enabled = true

local blacklist, whitelistCache = {}, {} ---@type {[string]: boolean}, {[string]: boolean}

util.tick:register(function()
    for name, _ in pairs(world.getPlayers()) do
        if not blacklist[name] and not whitelistCache[name] then
            table.insert(lift.config.whitelist, name)
            whitelistCache[name] = true
        end
    end
end, 600)