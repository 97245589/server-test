local print = print
local os = os
local table = table
local pairs = pairs
local skynet = require "skynet"
local mgrs = require "server.game.plmgr.mgrs"
local enums = require "server.game.plmgr.enums"
local db = require "common.func.ldb"
local cfgf = require "common.func.cfg"
local lrank = require "lgame.rank"
local time = require "server.game.plmgr.time"

local __testrankcfg = {
    [1] = { type = 1, num = 100, permanent = 1 },
    [2] = { type = 2, num = 10, manual = 1 },
    [3] = { type = 3, num = 1000, everyweek = { weekday = 1 }, duration = { day = 7 } }
}

local timer = mgrs.timer

local M = {}
local pres = {}
local ranks = {}

timer.handle[enums.timer_rank] = function(mark, id)
    local cfg = __testrankcfg[id]
    if not cfg.everyweek then
        print("rank timer err", mark, id)
        return
    end
    if mark == enums.close then
        pres[id] = pres[id] or {}
        local prearr = pres[id]
        local idscorearr, id_order = M.snapshot(id)
        table.insert(prearr, 1, { idscorearr, id_order })
        if #prearr > 2 then
            table.remove(prearr)
        end
        ranks[id] = nil
        local starttm = time.startendtm(cfg)
        if starttm then
            timer.add(starttm, enums.timer_rank, enums.open, id)
        end
    elseif mark == enums.open then
        local starttm, endtm = time.startendtm(cfg)
        local nowtm = os.time()
        if not starttm then
            return
        end
        if nowtm < starttm then
            timer.add(starttm, enums.timer_rank, enums.open, id)
            return
        end
        if nowtm >= starttm and nowtm < endtm then
            M.create(id, starttm, endtm)
        end
    end
end

M.create = function(id, starttm, endtm, bin)
    local cfg = __testrankcfg[id]
    if not cfg or not cfg.num then
        -- db("hdel", "rank", id, "p" .. id)
        print("rank cfg err no num", id)
        return
    end
    if ranks[id] then
        print("createrank err exist", id)
        return
    end
    print("create rank", id, starttm, endtm)

    local nrank = {
        id = id,
        starttm = starttm,
        endtm = endtm,
        core = lrank.create(cfg.num)
    }
    if bin then
        nrank.core:deseri(bin)
    end
    if endtm then
        timer.add(endtm, enums.timer_rank, enums.close, id)
    end
    ranks[id] = nrank
end

M.del = function(ranktid)
    ranks[ranktid] = nil
end

M.add = function(ranktid, id, score)
    local rank = ranks[ranktid]
    if not rank then
        print("rank add err", ranktid, id, score)
        return
    end
    rank.core:add(id, score, os.time())
end

M.info = function(ranktid, lb, ub, id)
    local rank = ranks[ranktid]
    if not rank then
        print("rank info err", ranktid)
        return
    end
    if not lb or not ub then
        print("shortage of lb or ub", ranktid)
        return
    end
    local core = rank.core
    local arr = core:info(lb, ub)
    local order, score = core:order(id)
    return {
        arr = arr,
        id = id,
        order = order,
        score = score
    }
end

M.pre = function(ranktid)
    return pres[ranktid]
end

M.snapshot = function(ranktid, lb, ub)
    local rank = ranks[ranktid]
    if not rank then
        return
    end
    local cfg = __testrankcfg[ranktid]
    local core = rank.core
    lb = lb or 1
    ub = ub or cfg.num
    local idscorearr = core:info(lb, ub)
    local id_order = {}
    for i = 1, #idscorearr, 2 do
        local eid = idscorearr[1]
        id_order[eid] = (i + 1) // 2
    end
    return idscorearr, id_order
end

M.save = function()
    -- print("=== rank save")
    local dbinfo = {
        pres = pres,
        ranks = {},
    }
    local dbranks = dbinfo.ranks
    for rankid, rank in pairs(ranks) do
        dbranks[rankid] = {
            id = rankid,
            starttm = rank.starttm,
            endtm = rank.endtm,
            bin = rank.core:seri()
        }
    end
    -- db("hset", "plmgr", "rank", skynet.packstring(dbinfo))
end

local init = function()
    local dbinfo = db("hget", "plmgr", "rank")
    if dbinfo then
    else
        dbinfo = {}
    end
    pres = dbinfo.pres or {}
    local dbranks = dbinfo.ranks or {}
    for id, dbrank in pairs(dbranks) do
        M.create(id, dbrank.starttm, dbrank.endtm, dbrank.bin)
    end

    for id, cfg in pairs(__testrankcfg) do
        if ranks[id] then
            goto cont
        end
        if cfg.permanent then
            M.create(id)
        elseif cfg.everyweek then
            local starttm = time.startendtm(cfg)
            if not starttm then
                goto cont
            end
            timer.add(starttm, enums.timer_rank, enums.open, id)
        end
        ::cont::
    end
end
init()

mgrs.add_mgr(M, "rank")
return M
