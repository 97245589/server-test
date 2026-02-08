local skynet = require "skynet"
local mgrs = require "server.game.plmgr.mgrs"
local db = require "common.func.leveldb"
local zstd = require "common.func.zstd"
local M = {}

local gameid = tonumber(skynet.getenv("server_id"))
local data
M.init = function(dbdata)
    data = dbdata
    data.playeridx = data.playeridx or 1
end

M.gen_id = function()
    local id = gameid << 25 | data.playeridx
    data.playeridx = data.playeridx + 1
    return id
end

M.create_acc = function(acc)
    local acckey = "acc" .. gameid
    local acc_bin = db.call("hget", acckey, acc)
    local acc_info = zstd.decode(acc_bin)

    local newid = M.gen_id()
    local role = {
        playerid = newid,
        acc = acc,
        name = ""
    }
    acc_info[newid] = role
    local nplayer = {
        role = {
            playerid = newid,
            acc = acc,
            name = ""
        }
    }
    db.send("hset", acckey, acc, zstd.encode(acc_info))
    db.send("hset", "pl" .. newid, "data", zstd.encode(nplayer))
end

mgrs.add_mgr(M, "player")
return M
