local skynet = require "skynet"
local socket = require "skynet.socket"
local lkcp = require "lgame.kcp"

local child = ...
if child then
    local client = function(name)
        local host, core
        host = socket.udp(function(str, from)
            core:input(str)
            core:update(skynet.now())
        end)
        socket.udp_connect(host, "0.0.0.0", 8765)
        core = lkcp.create(10, 0, function(kid, str)
            socket.write(host, str)
        end)
        for i = 1, 300, 2 do
            core:send(name .. " " .. i)
            core:send(name .. " " .. i + 1)
            core:update(skynet.now())
            skynet.sleep(1)
        end
    end
    skynet.start(function()
        skynet.fork(client, child)
    end)
else
    local server = function()
        local from_kcp = {}
        local host

        local getkcp = function(from)
            if not from_kcp[from] then
                local kcp = {
                    core = lkcp.create(10, 0, function(id, str)
                        socket.sendto(host, from, str)
                    end)
                }
                from_kcp[from] = kcp
            end
            return from_kcp[from]
        end
        host = socket.udp(function(str, from)
            local kcp  = getkcp(from)
            local core = kcp.core
            core:input(str)
            while true do
                local data = core:recv()
                if data then
                    print("recv", socket.udp_address(from), data)
                else
                    break
                end
            end
            core:update(skynet.now())
        end, "0.0.0.0", 8765)
    end

    skynet.start(function()
        skynet.fork(server)
        for i = 1, 2 do
            skynet.newservice("server/test/kcp", "child" .. i)
        end
    end)
end
