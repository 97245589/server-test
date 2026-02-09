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

skynet.start(function()
    -- ip()
    -- cfg()
    -- skynet.abort()
end)
