local skynet = require "skynet"
local profile = require "skynet.profile"

local func_cost = {}

skynet.fork(function()
    while true do
        skynet.sleep(100 * 60 * 5)
        print(dump(func_cost))
        func_cost = {}
    end
end)

return function(name, func, ...)
    profile.start()
    local ret = func(...)
    local t = profile.stop()
    local cost = func_cost[name] or 0
    func_cost[name] = cost + t
    return ret
end
