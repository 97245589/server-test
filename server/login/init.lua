local require = require
local skynet = require "skynet"
local cmds = require "common.service.cmds"
local start = require "common.service.start"

local cluster_addr
local acc_gameserver = {}

cmds.acc_gameserver = function(acc, server)
    local bserver = acc_gameserver[acc]
    if bserver then
        skynet.send(cluster_addr, "lua", "kick_acc", server, acc)
    end
    acc_gameserver[acc] = acc_gameserver
end

start(function()
    local logind_start = require "server.login.logind"
    cluster_addr = skynet.newservice("server/login/cluster")
    logind_start(cluster_addr)
end)
