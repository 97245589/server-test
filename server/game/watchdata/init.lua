local skynet = require "skynet"
local start = require "common.service.start"

start(function()
    require "server.game.rpc"
    skynet.timeout(0, function()
        require "server.game.watchdata.watchdata"
    end)
end)
