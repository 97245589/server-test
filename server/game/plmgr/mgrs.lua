local pairs = pairs
local inits = {}
local ticks = {}
local mgrs  = {}

local M     = {}

M.add_mgr   = function(mgr, name)
    inits[name] = mgr.init
    ticks[name] = mgr.tick
    mgrs[name] = mgr
end

M.all_init  = function(data)
    for k, func in pairs(inits) do
        func(data)
    end
end

M.all_tick  = function(tm)
    for k, tick in pairs(ticks) do
        tick(tm)
    end
end

return M
