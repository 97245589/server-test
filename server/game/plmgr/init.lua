local skynet = require "skynet"
local start = require "common.service.start"

local require_files = function()
    require "server.game.plmgr.player"

    local mgrs = require "server.game.plmgr.mgrs"
    local tick = require "server.game.plmgr.tick"
    mgrs.all_init(tick.get_dbdata())
    tick.start_tick()
end

start(function()
    require "server.game.rpc"
    skynet.timeout(50, require_files)
end)
