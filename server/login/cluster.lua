local require = require
local pairs = pairs
local string = string
local cluster = require "skynet.cluster"
local start = require "common.service.start"
local cmds = require "common.service.cmds"

local gameserver_info = {}

cmds.acc_key = function(server, acc, key)
    local info = gameserver_info[server]
    if not info then
        return
    end
    cluster.call(server, info.watchdog, "acc_key", acc, key)
    return info.host
end

cmds.kick_acc = function(server, acc)
    local info = gameserver_info[server]
    if not info then
        return
    end
    cluster.send(server, info.watchdog, "kick_acc", acc)
end

local cluster_diff_func = function(server_host)
    for server in pairs(gameserver_info) do
        if not server_host[server] then
            gameserver_info[server] = nil
        end
    end
    for server in pairs(server_host) do
        local stype = string.sub(server, 1, 4)
        if stype ~= "game" then
            goto cont
        end
        if not gameserver_info[server] then
            local info = cluster.call(server, "@" .. server, "gameserver_info")
            gameserver_info[server] = info
        end
        ::cont::
    end
    print("gameserver_info", dump(gameserver_info))
end

start(function()
    local scluster = require "common.service.cluster"
    scluster.set_diff_func(cluster_diff_func)
end)
