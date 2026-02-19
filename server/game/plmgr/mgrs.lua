local skynet = require "skynet"
local db = require "common.func.ldb"
local timerf = require "common.func.timer"
local time = require "server.game.plmgr.time"

local dbdata = {}
local savefields = { "info", "player", "activity" }

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
    time.set_startts(info.serverstart_tm)
end
load()

local M = {}
local ticksave = {}
M.add_mgr = function(mgr, name)
    if mgr.init then
        mgr.init(dbdata)
    end
    ticksave[name] = mgr.ticksave
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
            if field and dbdata[field] then
                table.insert(arr, field)
                table.insert(arr, skynet.packstring(dbdata[field]))
                -- print("plmgr field", field, dump(dbdata[field]))
            end
        end
        -- db("hmset", table.unpack(arr))
    end

    local lastsavetm = os.time()
    skynet.fork(function()
        while true do
            local tm = os.time()
            timer.expire(tm)
            if tm - lastsavetm > 60 then
                lastsavetm = tm
                save()
                for _, func in pairs(ticksave) do
                    func()
                end
            end
            skynet.sleep(100)
        end
    end)
end

return M
