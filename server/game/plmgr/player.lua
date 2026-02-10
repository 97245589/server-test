local skynet = require "skynet"
local mgrs = require "server.game.plmgr.mgrs"
local db = require "common.func.leveldb"
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
    local acc_bin = db.call("hget", "acc", acc)
    local acc_arr
    if acc_bin then
    else
        acc_arr = {}
    end
    if #acc_arr > 3 then
        return
    end

    local newid = M.gen_id()
    local role = {
        playerid = newid,
        acc = acc,
        name = ""
    }
    local nplayer = {
        role = {
            playerid = newid,
            acc = acc,
            name = ""
        }
    }
    table.insert(acc_arr, newid)
end

mgrs.add_mgr(M, "player")
return M
