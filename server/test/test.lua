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

local cs = function()
    local queue = require "skynet.queue"
    local cs = queue()
    local v
    local func1 = function()
        v = 1
        print("func1", skynet.now())
        skynet.sleep(50)
        print("func1 after sleep", v)
    end
    local func2 = function()
        v = 2
        print("func2", skynet.now())
    end
    skynet.fork(func1)
    skynet.fork(func2)
    
    skynet.sleep(100)
    skynet.fork(cs, func1)
    skynet.fork(cs, func2)
end

skynet.start(function()
    cs()
    -- cfg()
    -- skynet.abort()
end)
