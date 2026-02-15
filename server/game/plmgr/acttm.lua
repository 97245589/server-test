local print = print
local pairs = pairs
local mgrs = require "server.game.plmgr.mgrs"
local cfgf = require "common.func.cfg"
local time = require "server.game.plmgr.time"
local enums = require "server.game.plmgr.enums"
local rpc = require "server.game.rpc"
local timer = mgrs.timer

local actcfg = {
    [100] = {
        time = { year = 2026, month = 2, day = 13, hour = 6 },
        duration = { day = 3 },
        next = { day = 4 }
    },
    [200] = {
        server_start = { day = 3 },
        duration = { day = 3 },
        next = { day = 3 }
    },
}

local dbacttm
local M = {}
local impl = {}
M.impl = impl

M.init = function(dbdata)
    dbdata.acttm = dbdata.acttm or {}
    dbacttm = dbdata.acttm

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
            timer.add(act.endtm, enums.timer_activities, enums.activity_close, actid)
            return
        end

        -- print("actstartend", act.id, time.format(act.starttm), time.format(act.endtm))
        timer.add(act.starttm, enums.timer_activities, enums.activity_open, actid)
        timer.add(act.endtm, enums.timer_activities, enums.activity_close, actid)
    end
    for actid, cfg in pairs(actcfg) do
        init_one(actid, cfg)
    end

    local ret = {}
    for actid, act in pairs(dbacttm) do
        if act.isopen then
            ret[actid] = act
        end
    end
    rpc.send_all("player", "acts", ret)
end

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
    local cfg = actcfg[actid]
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

    timer.add(starttm, enums.timer_activities, enums.activity_open, actid)
    timer.add(endtm, enums.timer_activities, enums.activity_close, actid)
end

timer.handle[enums.timer_activities] = function(m, actid)
    if m == enums.activity_open then
        actopen(actid)
    elseif m == enums.activity_close then
        actclose(actid)
    else
        print("timer acttm mark err", m)
    end
end

mgrs.add_mgr(M, "acttm")
return M
