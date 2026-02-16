local skynet = require "skynet"
local start = require "common.service.start"

local require_files = function()
    local mgrs = require "server.game.plmgr.mgrs"
    require "server.game.plmgr.player"
    require "server.game.plmgr.activity"
    require "server.game.plmgr.rank"

    mgrs.start_tick()
end

start(function()
    require "server.game.rpc"
    skynet.timeout(50, require_files)
end)
