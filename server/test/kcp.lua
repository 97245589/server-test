local skynet = require "skynet"
local socket = require "skynet.socket"
local kcp = require "lgame.kcp"

local child = ...
if child then
    local client = function(name)
        local host, kclient
        host = socket.udp(function(str, from)
            -- print("client recv", str, from)
            kclient:input(str)
            kclient:update(skynet.now())
        end)
        socket.udp_connect(host, "0.0.0.0", 8765)
        kclient = kcp.client(1, host)
        for i = 1, 1000, 2 do
            kclient:send(name .. " " .. i)
            kclient:send(name .. " " .. i + 1)
            kclient:update(skynet.now())
            skynet.sleep(1)
        end
    end

    skynet.start(function()
        skynet.fork(client, child)
    end)
else
    local server = function()
        local kcps = {}
        local host
        host = socket.udp(function(str, from)
            if not kcps[from] then
                local kserver = kcp.server(1, host, from)
                kcps[from] = {
                    kserver = kserver,
                    heartbeat = nil
                }
            end

            local kcpdata = kcps[from]
            kcpdata.heartbeat = os.time()
            local kserver = kcpdata.kserver
            kserver:input(str)
            while true do
                local data = kserver:recv()
                if data then
                    print("recv from", socket.udp_address(from), data)
                else
                    break
                end
            end
            kserver:update(skynet.now())
        end, "0.0.0.0", 8765)
    end

    skynet.start(function()
        skynet.fork(server)
        for i = 1, 2 do
            skynet.newservice("server/test/kcp", "child" .. i)
        end
    end)
end
