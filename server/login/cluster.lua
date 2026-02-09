local require = require
local pairs = pairs
local string = string
local cluster = require "skynet.cluster"
local start = require "common.service.start"

local gameserver_publichost = {}

local cluster_diff_func = function(diff)
    local upd = diff.upd
    if upd then
        for server in pairs(upd) do
            local servertype = string.sub(server, 1, 2)
            if servertype == "ga" then
                local serverhost = cluster.call(server, "@" .. server, "public_host")
                gameserver_publichost[server] = serverhost
            end
        end
    end
    local del = diff.del
    if del then
        for server in pairs(del) do
            local servertype = string.sub(server, 1, 2)
            if servertype == "ga" then
                gameserver_publichost[server] = nil
            end
        end
    end

    print("diff", dump(diff))
    print("gameserver_publichost", dump(gameserver_publichost))
end

start(function()
    local scluster = require "common.service.cluster"
    scluster.set_diff_func(cluster_diff_func)
end)
