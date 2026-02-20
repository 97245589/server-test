local require = require
local pairs = pairs
local skynet = require "skynet"
require "skynet.manager"
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

    skynet.dispatch("lua", function()
        skynet.retpack(true)
        skynet.fork(function()
            print("gameserver start exit")
            for _, addr in pairs(addrs) do
                skynet.call(addr, "lua", "exit")
            end
            print("gameserver exit succ waiting db")
            local db = require "common.func.ldb"
            db("exit")
            skynet.sleep(100)
            skynet.abort()
        end)
    end)
end)
