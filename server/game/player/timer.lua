local timerf = require "common.func.timer"
local players = require "server.game.player.player_mgr".players

local enums = {
    test = 1
}
local handle = {}

local cb = function(id, cmd, ...)
    local player = players[id]
    if not player then
        print("timer no player", id)
        return
    end
    local func = handle[cmd]
    if not func then
        print("timer no handle func", cmd)
        return
    end
    func(player, ...)
end
local timer = timerf(cb)

return {
    timer = timer,
    handle = handle,
    enums = enums
}
