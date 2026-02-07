local require = require
local skynet = require "skynet"
local start = require "common.service.start"

local require_files = function()
    require "server.game.player.client"
    require "server.game.player.tick"

    require "server.game.player.cmd.cmds"
    require "server.game.player.cmd.req"
    require "server.game.player.mgr.role"
    require "server.game.player.mgr.item"
end

start(function()
    require "server.game.rpc"
    skynet.timeout(0, require_files)
end)
