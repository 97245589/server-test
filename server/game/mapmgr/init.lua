local skynet = require "skynet"
local start  = require "common.service.start"

start(function()
    require "server.game.rpc"
end)
