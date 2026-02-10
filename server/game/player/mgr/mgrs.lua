local require = require
local pairs = pairs
local ipairs = ipairs
local pcall = pcall
local cfg = require "common.func.cfg"

local M = {}

local inits = {}
local cfgs = {}
local ticks = {}

M.reload_cfg = function(cfgname)
    cfg.reload(cfgname, function(mnames)
        for name in pairs(mnames) do
            cfgs[name]()
        end
    end)
end

M.add_mgr = function(mgr, name, init_level)
    if mgr.init then
        init_level = init_level or 1
        inits[init_level] = inits[init_level] or {}
        inits[init_level][name] = mgr.init
    end

    if mgr.cfg then
        cfgs[name] = mgr.cfg
        cfg.cfg_func(name, mgr.cfg)
    end

    ticks[name] = mgr.tick
end

M.all_init = function(player)
    for idx, funcs in ipairs(inits) do
        for name, func in pairs(funcs) do
            func(player)
        end
    end
end

M.all_tick = function(player, tm)
    for name, func in pairs(ticks) do
        local ok, err = pcall(func, player, tm)
    end
end

return M
