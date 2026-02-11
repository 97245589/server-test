local require = require
local os = os
local mgrs = require "server.game.player.mgrs"

local M = {}

local players = {}
M.players = players

local player_db = function(playerid)
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

M.save_player = function(player)
end

return M
