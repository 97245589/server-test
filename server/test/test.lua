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

skynet.start(function()
    -- cfg()
    -- skynet.abort()
end)
