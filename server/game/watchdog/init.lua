local require = require
local skynet = require "skynet"
local start = require "common.service.start"

local require_files = function()
    require "server.game.watchdog.watchdog"
end

start(function()
    require "server.game.rpc"
    skynet.timeout(100, require_files)
end)
