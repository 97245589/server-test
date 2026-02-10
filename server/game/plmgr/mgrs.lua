local pairs = pairs
local pcall = pcall
local inits = {}
local ticks = {}

local M     = {}

M.add_mgr   = function(mgr, name)
    inits[name] = mgr.init
    ticks[name] = mgr.tick
end

M.all_init  = function(data)
    for k, func in pairs(inits) do
        func(data)
    end
end

M.all_tick  = function(tm)
    for k, tick in pairs(ticks) do
        local ok, err = pcall(tick, tm)
        if not ok then
            print("tick err", k, err)
        end
    end
end

return M
