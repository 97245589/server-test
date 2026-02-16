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
        time = { year = 2026, month = 2, day = 13, hour = 6 },
        duration = { day = 3 },
    },
    [200] = {
        server_start = { day = 0 },
        duration = { day = 3 },
        next = { day = 3 }
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

    local tm = os.time()
    local init_one = function(actid, cfg)
        local act = dbacttm[actid]
        if not act then
            local starttm, endtm = time.start_end(cfg)
            if not starttm then
                return
            end
            dbacttm[actid] = {
                id = actid,
                starttm = starttm,
                endtm = endtm,
                isopen = false
            }
            act = dbacttm[actid]
        end
        if act.endtm and tm >= act.endtm then
            timer.add(act.endtm, enums.timer_activity, enums.close, actid)
            return
        end

        -- print("actstartend", act.id, time.format(act.starttm), time.format(act.endtm))
        timer.add(act.starttm, enums.timer_activity, enums.open, actid)
        timer.add(act.endtm, enums.timer_activity, enums.close, actid)
    end
    for actid, cfg in pairs(__testactcfg) do
        init_one(actid, cfg)
    end

    local ret = {}
    for actid, act in pairs(dbacttm) do
        if act.isopen then
            ret[actid] = act
        end
    end
    rpc.send_all("player", "acttms", ret)
end

local impl = actimpl.impl
local actopen = function(actid)
    local act = dbacttm[actid]
    if act.isopen then
        return
    end
    act.isopen = true

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
    if act.isopen then
        rpc.send_all("player", "actclose", actid, act)
        if impl[actid] then
            impl[actid].close(act)
        end
    end
    local cfg = __testactcfg[actid]
    if not cfg then
        return
    end
    local starttm, endtm = time.start_end_by_lastend(cfg, act.endtm)
    if not starttm then
        return
    end
    dbacttm[actid] = {
        id = actid,
        starttm = starttm,
        endtm = endtm,
        isopen = false
    }

    timer.add(starttm, enums.timer_activity, enums.open, actid)
    timer.add(endtm, enums.timer_activity, enums.close, actid)
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
