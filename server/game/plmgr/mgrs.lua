local skynet = require "skynet"
local db = require "common.func.ldb"
local timerf = require "common.func.timer"
local time = require "server.game.plmgr.time"
local cmds = require "common.service.cmds"

local dbdata = {}

local load = function()
    local bin = db("hget", "plmgr", "data")
    if bin then
        dbdata = skynet.unpack(bin)
    end
    dbdata.info = dbdata.info or {}
    local info = dbdata.info
    if not info.serverstart_tm then
        info.serverstart_tm = time.day_start()
    end
    time.set_startts(info.serverstart_tm)
end
load()

local M = {}
local saves = {}
M.add_mgr = function(mgr, name)
    if mgr.init then
        mgr.init(dbdata)
    end
    saves[name] = mgr.save
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

local save = function()
    -- db("hmset", "plmgr", "data", skynet.packstring(dbdata))
    for _, func in pairs(saves) do
        func()
    end
end

M.start_tick = function()
    local lastsavetm = os.time()
    skynet.fork(function()
        while true do
            local tm = os.time()
            timer.expire(tm)
            if tm - lastsavetm > 60 then
                lastsavetm = tm
                save()
            end
            skynet.sleep(100)
        end
    end)
end

cmds.exit = function()
    save()
    print("plmgr exit")
end

return M
