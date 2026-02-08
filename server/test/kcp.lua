local skynet = require "skynet"
local socket = require "skynet.socket"
local kcp = require "kcp"

local child = ...
if child then
    local client = function(name)
        local host, kclient
        host = socket.udp(function(str, from)
            -- print("client recv", str, from)
            kclient:recv(str)
        end)
        socket.udp_connect(host, "0.0.0.0", 8765)
        kclient = kcp.client(1, host)
        for i = 1, 1000 do
            skynet.sleep(1)
            kclient:send(name .. " " .. i)
            kclient:update(i)
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
                print("fromlen", #from)
                local kserver = kcp.server(1, host, from)
                kcps[from] = {
                    kserver = kserver,
                    heartbeat = nil
                }
            end

            local kcpdata = kcps[from]
            kcpdata.heartbeat = os.time()
            local kserver = kcpdata.kserver
            local data = kserver:recv(str)
            print("recv from", socket.udp_address(from), data)
            kserver:update(i)
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
