local skynet = require "skynet"
local mgrs = require "server.game.plmgr.mgrs"
local db = require "common.func.ldb"
local msgpack = require "common.func.msgpack"

local gameid = tonumber(skynet.getenv("server_id"))
local dbplayer
local M = {}

M.init = function(dbdata)
    -- print("=== player")
    dbdata.player = dbdata.player or {}
    dbplayer = dbdata.player
end

M.gen_id = function()
    local id = gameid << 25 | dbplayer.playeridx
    dbplayer.playeridx = dbplayer.playeridx + 1
    return id
end

M.create_player = function(acc)
    local acc_arr = db.call("hget", "acc", acc)
    if acc_arr then
        acc_arr = skynet.unpack(acc_arr)
    else
        acc_arr = {}
    end
    if #acc_arr > 3 then
        return
    end

    local newid = M.gen_id()
    table.insert(acc_arr, newid)
    local player = {
        role = {
            playerid = newid,
            acc = acc,
            name = "hello"
        }
    }
    -- db.send("hmset", "acc", acc, msgpack.encode(acc_arr))
    -- db.send("hmset", "player", newid, msgpack.encode(player))
end

mgrs.add_mgr(M, "player")
return M
