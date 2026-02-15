local skynet = require "skynet"
local db = require "common.func.ldb"
local timerf = require "common.func.timer"
local time = require "server.game.plmgr.time"

local dbdata = {}
local savefields = { "info", "player" }

local load = function()
    local arrbin = db("hmget", "plmgr", table.unpack(savefields))
    for idx, field in ipairs(savefields) do
        local vbin = arrbin[idx]
        dbdata[field] = vbin and skynet.unpack(vbin) or {}
    end
    local info = dbdata.info
    if not info.serverstart_tm then
        info.serverstart_tm = time.day_start()
    end
    time.set_server_start_ts(info.serverstart_tm)
end
load()

local M = {}
local tickfuncs = {}
M.add_mgr = function(mgr, name)
    if mgr.init then
        mgr.init(dbdata)
    end
    if mgr.tick then
        tickfuncs[name] = mgr.tick
    end
end

local timerhandle = {}
local timer = timerf(function(id, cmd, ...)
    -- print("timer", cmd, ...)
    local func = timerhandle[cmd]
    if not func then
        print("timer cannot have cmd", cmd, ...)
        return
    end
    func(...)
end)
M.timer = {
    handle = timerhandle,
    add = function(tm, cmd, ...)
        timer.add(1, tm, cmd, ...)
    end
}

M.start_tick = function()
    local save = function()
        local arr = { "plmgr" }
        for idx, field in ipairs(savefields) do
            print("plmgr save", field)
            table.insert(arr, field)
            table.insert(arr, skynet.packstring(dbdata[field]))
        end
        db("hmset", table.unpack(arr))
    end

    local lastsavetm = os.time()
    skynet.fork(function()
        while true do
            skynet.sleep(100)
            local tm = os.time()
            timer.expire(tm)
            for name, tickfunc in pairs(tickfuncs) do
                tickfunc(tm)
            end
            if tm - lastsavetm > 30 then
                lastsavetm = tm
                -- save()
            end
        end
    end)
end

return M
