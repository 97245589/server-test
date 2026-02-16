local print = print
local os = os
local skynet = require "skynet"
local mgrs = require "server.game.plmgr.mgrs"
local db = require "common.func.ldb"
local cfgf = require "common.func.cfg"
local lrank = require "lgame.rank"

local M = {}
local ranks = {}

local dbbin = db("hmget", "plmgr", "rank")[1]
if dbbin then
    local dbrank = skynet.unpack(dbbin)
    for ranktid, rbin in pairs(dbrank) do
        M.create(ranktid, rbin)
    end
end

M.create = function(ranktid, rbin)
    if ranks[ranktid] then
        print("createrank err exist", ranktid)
    end

    local core = lrank.create(1000)
    if rbin then
        core:deseri(rbin)
    end
    ranks[ranktid] = core
end

M.del = function(ranktid)
    ranks[ranktid] = nil
end

M.ticksave = function()
    print("rank tick save ===")
    local allinfo = {}
    for ranktid, core in pairs(ranks) do
        allinfo[ranktid] = core:seri()
    end
    -- db("hmset", "plmgr", "rank", skynet.packstring(allinfo))
end

M.add = function(ranktid, id, score)
    local core = ranks[ranktid]
    if not core then
        return
    end
    core:add(id, score, os.time())
end

M.info = function(ranktid, lb, ub, id)
    local core = ranks[ranktid]
    local arr = core:info(lb, ub)
    local order, score = core:order(id)
    return {
        arr = arr,
        id = id,
        order = order,
        score = score
    }
end

mgrs.add_mgr(M, mgrs)
return M
