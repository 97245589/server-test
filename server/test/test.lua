require "common.func.tool"
local skynet = require "skynet"
require "skynet.manager"

local cfg = function()
    local cfg = require "common.func.cfg"
    while true do
        skynet.sleep(100)
        print(dump(cfg.get("item")))
        cfg.reload("item")
    end
end

local ip = function()
    local ip = require "common.func.ip"
    print("privateip", ip.private())
    print("publicip", ip.public())
end

local crc = function()
    local crc16 = require "skynet.db.redis.crc16"
    local val

    local t = skynet.now()
    for i = 1, 1000000 do
        val = crc16("watchdata" .. 10)
    end
    print(skynet.now() - t, val)
end

skynet.start(function()
    crc()
    -- ip()
    -- cfg()
    -- skynet.abort()
end)
