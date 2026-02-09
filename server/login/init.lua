local require = require
local skynet = require "skynet"
local cmds = require "common.service.cmds"
local cluster = require "skynet.cluster"
local start = require "common.service.start"

local acc_gameserver = {}
cmds.acc_gameserver = function(acc, server)
    local bserver = acc_gameserver[acc]
    if bserver then
        cluster.send(server, "watchdog", "kick_acc", acc)
    end
    acc_gameserver[acc] = acc_gameserver
end

start(function()
    require "server.login.logind"
    skynet.newservice("server/login/cluster")
end)
