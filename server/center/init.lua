local require = require
local os = os
local pairs = pairs
local skynet = require "skynet"
local start = require "common.service.start"
local cmds = require "common.service.cmds"

local loginserver
local gameserver = {}

start(function()
    local print = print
    local dump = dump
    local scluster = require "common.service.cluster"

    local server_host = scluster.get_server_host()
    local server_hearbeat = {}

    cmds.heartbeat = function(server, host)
        local servertype = string.sub(server, 1, 4)
        if servertype == "game" then
        elseif servertype == "logi" then
        end
        server_host[server] = host
        server_hearbeat[server] = os.time()
        return server_host
    end

    skynet.fork(function()
        while true do
            skynet.sleep(100)
            local nowtm = os.time()
            for server, tm in pairs(server_hearbeat) do
                if nowtm > tm + 6 then
                    server_host[server] = nil
                    server_hearbeat[server] = nil
                end
            end
            print("server_host info", dump(server_host))
        end
    end)
end)
