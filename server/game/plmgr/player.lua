local skynet = require "skynet"
local mgrs = require "server.game.plmgr.mgrs"
local db = require "common.func.ldb"
local enums = require "server.game.plmgr.enums"

local timer = mgrs.timer
timer.handle[enums.timer_test] = function(...)
end
local add_timer = function(tm, cmd, ...)
    timer.add(tm, cmd, ...)
end

local gameid = tonumber(skynet.getenv("server_id"))
local player
local M = {}

M.init = function(dbdata)
    -- print("=== player")
    dbdata.player = dbdata.player or {}
    player = dbdata.player
end

M.gen_id = function()
    local id = gameid << 25 | player.playeridx
    player.playeridx = player.playeridx + 1
    return id
end

M.create_player = function(acc)
    local acc_bin = db("hmget", "acc", acc)[1]
    local acc_arr
    if acc_bin then
        acc_arr = skynet.unpack(acc_bin)
    else
        acc_arr = {}
    end
    if #acc_arr > 3 then
        return
    end

    local newid = M.gen_id()
    table.insert(acc_arr, newid)
    local role = {
        playerid = newid,
        acc = acc,
        name = ""
    }
    db("hmset", "pl" .. newid, "role", skynet.packstring(role))
    db("hmset", "acc", acc, skynet.packstring(acc_arr))
end

mgrs.add_mgr(M, "player")
return M
