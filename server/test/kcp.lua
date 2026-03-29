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
        local send = function(kid, str)
            socket.write(host, str)
        end
        socket.udp_connect(host, "0.0.0.0", 8765)
        core = lkcp.create(1, host, send)
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
        local kid_kcp = {}
        local host
        local send = function(kid, str)
            local kcp = kid_kcp[kid]
            if kcp then
                socket.sendto(host, kcp.from, str)
            end
        end
        local delkcp = function(kid)
            local kcp = kid_kcp[kid]
            kid_kcp[kid] = nil
            if kcp then
                from_kcp[kcp.from] = nil
            end
        end

        local id = 0
        local genid = function()
            id = id + 1
            if id > 0xffffff then
                id = 0
            end
            return id
        end
        local getkcp = function(from)
            if not from_kcp[from] then
                local kid = genid()
                local kcp = {
                    from = from,
                    id = kid,
                    core = lkcp.create(1, kid, send)
                }
                from_kcp[from] = kcp
                kid_kcp[kid] = kcp
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
