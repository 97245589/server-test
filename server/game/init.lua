local require = require
local pairs = pairs
local skynet = require "skynet"
require "common.func.tool"

skynet.start(function()
    local service_num = {
        player = 3,
        watchdog = 1,
        watchdata = 2,
        cluster = 1,
        plmgr = 1,
        mapmgr = 1,
    }
    local addrs = {}

    for name, num in pairs(service_num) do
        local init = "server/game/" .. name .. "/init"
        if num == 1 then
            addrs[name] = skynet.newservice(init)
        else
            for i = 1, num do
                addrs[name .. i] = skynet.newservice(init)
            end
        end
    end

    for name, addr in pairs(addrs) do
        skynet.send(addr, "lua", "service_addrs", addrs, service_num)
    end

    -- print("rpc addrs", dump(addrs))
    skynet.exit()
end)
