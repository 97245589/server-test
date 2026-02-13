local skynet = require "skynet"
local db = require "common.func.ldb"
local timerf = require "common.func.timer"

local dbdata = {}
local savefields = {
    player = 1
}
local load = function()
    local arr = db("hgetall", "plmgr")
    for i = 1, #arr do
        local k = arr[i]
        local vbin = arr[i + 1]
        dbdata[k] = skynet.unpack(vbin)
    end
end

local save = function()
    local arr = { "plmgr" }
    for k in pairs(savefields) do
        table.insert(arr, k)
        table.insert(arr, skynet.packstring(dbdata[k]))
    end
    db("hmset", table.unpack(arr))
end

local M = {}

local timerhandle = {}
local timer = timerf(function(id, cmd, ...)
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

M.add_mgr = function(mgr, name)
    if mgr.init then
        mgr.init(dbdata)
    end
end

local lastsavetm = os.time()
skynet.fork(function()
    while true do
        skynet.sleep(100)
        local tm = os.time()
        if tm - lastsavetm > 30 then
            lastsavetm = tm
            timer.expire(tm)
            -- save()
        end
    end
end)

return M
