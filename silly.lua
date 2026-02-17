if not client.isModLoaded("sillyplugin") and not client.isModLoaded("goofyplugin") and not client.isModLoaded("extura") then return end

local lift = require("lib.thirdparty.Lift")

lift.config.enabled = true

local blacklist = {
    
}

local whitelistCache = {

}

function events.tick()
    if world.getTime() % 60 ~= 0 then return end
    for name, _ in pairs(world.getPlayers()) do
        if not blacklist[name] and not whitelistCache[name] then
            table.insert(lift.config.whitelist, name)
            whitelistCache[name] = true
        end
    end
end