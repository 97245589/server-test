local skynet = require "skynet"
local start = require "common.service.start"

local require_files = function()
    require "server.game.plmgr.mgrs"
    require "server.game.plmgr.player"
end

start(function()
    require "server.game.rpc"
    skynet.timeout(50, require_files)
end)
