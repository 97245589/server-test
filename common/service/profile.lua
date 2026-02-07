local require = require
local profile = require "skynet.profile"

local func_cost = {}

local M = {}

M.add_profile = function(name, func, ...)
    profile.start()
    func(...)
    local t = profile.stop()
    local cost = func_cost[name] or 0
    func_cost[name] = cost + t
end

M.func_cost = function()
    return func_cost
end

M.reset = function()
    func_cost = {}
end

return M
