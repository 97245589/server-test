local require = require
local os = os
local db = require "common.func.leveldb"
local mgrs = require "server.game.player.mgr.mgrs"
local enums = require "server.game.player.enums"
local rpc = require "server.game.rpc"

local M = {}

local players = {}
M.players = players

local player_db = function(playerid)
    -- local bin = db.call("hget", enums.dbkey_player, playerid)
    if players[playerid] then
        return players[playerid]
    end
    local player = {}
    mgrs.all_init(player)
    player.role.online = nil
    players[playerid] = player
    return player
end

M.get_player = function(playerid)
    local player = players[playerid] or player_db(playerid)
    if not player then
        return
    end
    player.id = playerid
    player.role.gettm = os.time()
    return player
end

M.get_brief_info = function(playerid)
    local player = players[playerid]
    if player then
        return player.role
    end
    local info = rpc.call_id("player", "get_brief_info", playerid)
    if info then
        return info
    end
end

M.save_player = function(player)
end

return M
