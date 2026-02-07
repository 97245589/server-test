local require = require
local os = os
local db = require "common.func.leveldb"
local mgrs = require "server.game.player.mgr.mgrs"
local zstd = require "common.func.zstd"
local rpc = require "server.game.rpc"

local M = {}

local players = {}
M.players = players

local player_db = function(playerid)
    -- local bin = db.call("hget", "pl" .. playerid, "data")
    if players[playerid] then
        return players[playerid]
    end
    -- local player = zstd.decode(bin)
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
    local bin = db.call("hget", "pl" .. playerid, "role")
    if bin then
        return zstd.decode(bin)
    end
end

M.save_player = function(player)
    local attrs = player.attrs
    player.attrs = nil
    -- db.send("hmset", "pl"..playerid, "data", zstd.encode(player), "role", zstd.encode(player.role))
    player.attrs = attrs
end

return M
