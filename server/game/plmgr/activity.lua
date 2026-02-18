local print = print
local pairs = pairs
local mgrs = require "server.game.plmgr.mgrs"
local cfgf = require "common.func.cfg"
local time = require "server.game.plmgr.time"
local enums = require "server.game.plmgr.enums"
local rpc = require "server.game.rpc"
local actimpl = require "server.game.plmgr.actimpl"

local timer = mgrs.timer

local __testactcfg = {
    [100] = {
        time = { year = 2026, month = 2, day = 13 },
        duration = { day = 3 },
    },
    [200] = {
        afterstart = {},
        duration = { day = 3 },
    },
}

local dbacttm
local M = {}

M.init = function(dbdata)
    dbdata.activity = dbdata.activity or {}
    local dbactivity = dbdata.activity
    dbactivity.acttm = dbactivity.acttm or {}
    dbacttm = dbactivity.acttm
    dbactivity.actdata = dbactivity.actdata or {}
    actimpl.setdb(dbactivity.actdata)

    local init_one = function(actid, cfg)
        local act = dbacttm[actid]
        if not act then
            local starttm, endtm = time.startendtm(cfg)
            if not starttm then
                return
            end
            timer.add(starttm, enums.timer_activity, enums.open, actid)
        else
            timer.add(act.endtm, enums.timer_activity, enums.close, actid)
        end
    end
    for actid, cfg in pairs(__testactcfg) do
        init_one(actid, cfg)
    end

    rpc.send_all("player", "actopens", dbacttm)
end

local impl = actimpl.impl
local actopen = function(actid)
    if dbacttm[actid] then
        print("activity open err", actid)
        return
    end
    local cfg = __testactcfg[actid]
    local starttm, endtm = time.startendtm(cfg)
    if not starttm then
        print("activity open time err", actid)
        return
    end
    dbacttm[actid] = {
        id = actid,
        starttm = starttm,
        endtm = endtm
    }
    timer.add(endtm, enums.timer_activity, enums.close, actid)
    local act = dbacttm[actid]
    rpc.send_all("player", "actopen", actid, act)
    if impl[actid] then
        impl[actid].open(act)
    end
    print("acttm open", actid, act.starttm, act.endtm)
end
local actclose = function(actid)
    local act = dbacttm[actid]
    print("acttm close", actid, act.starttm, act.endtm)
    dbacttm[actid] = nil
    rpc.send_all("player", "actclose", actid, act)
    if impl[actid] then
        impl[actid].close(act)
    end
    local cfg = __testactcfg[actid]
    if not cfg then
        return
    end
    local starttm, endtm = time.startendtm(cfg)
    if not starttm then
        return
    end
    timer.add(starttm, enums.timer_activity, enums.open, actid)
end

timer.handle[enums.timer_activity] = function(m, actid)
    if m == enums.open then
        actopen(actid)
    elseif m == enums.close then
        actclose(actid)
    else
        print("timer acttm mark err", m)
    end
end

mgrs.add_mgr(M, "activity")
return M
