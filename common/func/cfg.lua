local pairs = pairs
local io = io
local load = load

local cfgs = {}
local mname
local cfg_mgr = {}

local M = {}
M.loadf = function(name)
    local path = "config/" .. name .. ".lua"
    local f = io.open(path)
    local str = f:read("*a")
    f:close()
    return load(str)()
end

M.cfg_func = function(mgrname, func)
    mname = mgrname
    func()
    mname = nil
end

M.get = function(cfgname)
    if mname then
        cfg_mgr[cfgname] = cfg_mgr[cfgname] or {}
        cfg_mgr[cfgname][mname] = 1
    end

    if cfgs[cfgname] then
        return cfgs[cfgname]
    else
        local cfg = M.loadf(cfgname)
        cfgs[cfgname] = cfg
        return cfg
    end
end

M.reload = function(cfgname, func)
    cfgs[cfgname] = M.loadf(cfgname)

    local mnames = cfg_mgr[cfgname]
    if func and mnames then
        func(mnames)
    end
end

return M
