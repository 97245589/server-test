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
    [3] = { type = 3, num = 1000, everyweek = { 1 }, duration = { day = 7 } }
}

local timer = mgrs.timer

local M = {}
local preinfo
local ranks = {}

timer.handle[enums.timer_rank] = function(mark, id)
    if mark == enums.close then
        local rank = ranks[id]
        if not rank then
            return
        end
        local cfg = __testrankcfg[id]
        preinfo[id] = preinfo[id] or {}
        local prearr = preinfo[id]
        local idscorearr = rank.core:info(1, cfg.num)
        local id_order = {}
        for i = 1, #idscorearr, 2 do
            local eid = idscorearr[1]
            id_order[eid] = (i + 1) // 2
        end

        table.insert(preinfo[id], 1, { idscorearr, id_order })
        if #prearr > 3 then
            table.remove(prearr)
        end
    end
end

local init = function()
    local initdb = function()
        local dbdata = db("hmget", "plmgr", "rank")[1]
        if not dbdata then
            return
        end
        dbdata = skynet.unpack(dbdata)
        preinfo = dbdata.preinfo or {}
        local dbranks = dbdata.dbranks
        local nowtm = os.time()
        for id, drank in pairs(dbranks) do
            local cfg = __testrankcfg[id]
            if not cfg or not cfg.num then
                print("rank cfg err", id)
                goto cont
            end
            local core = lrank.create(cfg.num)
            core:deseri(drank.bin)
            local nrank = {
                id = id,
                starttm = drank.starttm,
                endtm = drank.endtm,
                core = core,
            }
            if nowtm >= nrank.endtm then
                timer.add(nrank.endtm, enums.timer_rank, enums.close, id)
            end
            ranks[id] = nrank
            ::cont::
        end
    end
    initdb()
    for id, cfg in pairs(__testrankcfg) do
        if cfg.manual then
            goto cont
        end
        if not ranks[id] then
            M.create(id)
        end
        ::cont::
    end
end

M.create = function(id)
    local cfg = __testrankcfg[id]
    if not cfg or not cfg.num then
        print("rank cfg err no num", id)
        return
    end
    if cfg.manual and cfg.everyweek then
        print("rank cfg err manual everyweek exclu", id)
        return
    end
    if ranks[id] then
        print("createrank err exist", id)
        return
    end
    print("create rank", id)

    local nrank = {
        id = id,
        core = lrank.create(cfg.num)
    }
    if cfg.everyweek then
        local starttm, endtm = time.start_end(cfg)
        nrank.starttm = starttm
        nrank.endtm = endtm
        timer.add(nrank.endtm, enums.timer_rank, enums.close, id)
    end

    ranks[id] = nrank
end

M.del = function(ranktid)
    ranks[ranktid] = nil
end

M.ticksave = function()
    print("rank tick save ===")
    local dbdata = {
        preinfo = preinfo,
        ranks = ranks
    }

    local dbranks = dbdata.ranks
    for ranktid, rank in pairs(ranks) do
        dbranks[ranktid] = {
            id = rank.id,
            starttm = rank.starttm,
            endtm = rank.endtm,
            bin = rank.core:seri()
        }
    end
    -- db("hmset", "plmgr", "rank", skynet.packstring(dbdata))
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
    local cfg = __testrankcfg[ranktid]
    lb = lb or 1
    ub = ub or cfg.num
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

init()
mgrs.add_mgr(M, mgrs)
return M
