local tostring   = tostring
local tonumber   = tonumber
local skynet     = require "skynet"
local mgrs       = require "server.game.plmgr.mgrs"
local db         = require "common.func.leveldb"
local zstd       = require "common.func.zstd"

local gameid     = tonumber(skynet.getenv("server_id"))

local dbdata     = mgrs.dbdata
dbdata.playeridx = dbdata.playeridx or 1

local M          = {}

M.gen_playerid   = function()
    local id = gameid << 25 | dbdata.playeridx
    dbdata.playeridx = dbdata.playeridx + 1
    return id
end

M.create_player  = function(acc)
    local newplayerid = M.gen_playerid()
    local player = {
        role = { playerid = newplayerid, acc = acc }
    }
    -- db.call("hmset", "pl" .. newplayerid, "data", zstd.encode(player))
    return newplayerid
end

return M
