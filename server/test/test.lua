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
    local func1 = function()
        print("func1", skynet.now())
        skynet.sleep(200)
    end
    local func2 = function()
        print("func2", skynet.now())
    end
    cs(func1)
    cs(func1)
    cs(func2)

    -- skynet.fork(func1)
    -- skynet.fork(func1)
    -- skynet.fork(func2)
end

skynet.start(function()
    cs()
    -- cfg()
    -- skynet.abort()
end)
