local skynet = require "skynet"
local socket = require "skynet.socket"
local lkcp = require "lgame.kcp"

local child = ...
if child then
    local client = function(name)
        local host, kcp_cli
        host = socket.udp(function(str, from)
            -- print("client recv", str, from)
            kcp_cli:recv(str)
        end)
        socket.udp_connect(host, "0.0.0.0", 8765)
        kcp_cli = lkcp.client(1, host)
        for i = 1, 1000 do
            skynet.sleep(1)
            kcp_cli:send(name .. "   " .. i)
            kcp_cli:update(i)
        end
    end

    skynet.start(function()
        skynet.fork(client, child)
    end)
else
    local server = function()
        local kcps = {}
        local host
        local i = 0
        host = socket.udp(function(str, from)
            if not kcps[from] then
                local kcp = lkcp.server(1, host, from)
                kcps[from] = {
                    kcp = kcp,
                    heartbeat = skynet.now()
                }
            end
            local kcp = kcps[from].kcp
            local data = kcp:recv(str)
            print("recv from", socket.udp_address(from), data)
            kcp:update(i)
            i = i + 1
        end, "0.0.0.0", 8765)
    end

    skynet.start(function()
        skynet.fork(server)
        for i = 1, 3 do
            skynet.newservice("server/test/kcp", "child" .. i)
        end
    end)
end
