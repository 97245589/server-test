local require = require
local skynet = require "skynet"
local start = require "common.service.start"
local cmds = require "common.service.cmds"

local loginserver
local gameservers = {}

start(function()
    local scluster = require "common.service.cluster"

    local server_host = scluster.get_server_host()
    local server_hearbeat = {}

    cmds.heartbeat = function(server, host)
        server_host[server] = host
        server_hearbeat[server] = os.time()
        local servertype = string.sub(server, 1, 2)
        if servertype == "ga" then
            gameservers[server] = host
            return
        elseif servertype == "lo" then
            loginserver = host
            return gameservers
        end
    end

    skynet.fork(function()
        while true do
            skynet.sleep(100)
            local nowtm = os.time()
            for server, tm in pairs(server_hearbeat) do
                if nowtm > tm + 6 then
                    server_host[server] = nil
                    server_hearbeat[server] = nil

                    local servertype = string.sub(server, 1, 2)
                    if servertype == "ga" then
                        gameservers[server] = nil
                    elseif servertype == "lo" then
                        loginserver = nil
                    end
                end
            end
            print("server_host info", dump(server_host))
        end
    end)
end)
