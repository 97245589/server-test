local os = os
local print = print
local table = table
local pairs = pairs
local db = require "common.func.ldb"
local squeue = require "skynet.queue"
local skynet = require "skynet"
local seri = require "lgame.seri"

local players = {}
local M = {}
M.players = players

local dbplayer = function(playerid, field)
    local player = players[playerid]
    if player then
        return player
    end
    local bin = db("hget", "player", playerid)
    player = {}
    player.id = playerid
    player.online = nil
    M.mgrs.init_player(player)
    players[playerid] = player
    return player
end

local cses = {}
local CSNUM = 5
for i = 1, CSNUM do
    table.insert(cses, squeue())
end
M.get_player = function(playerid, field)
    local player = players[playerid]
    if player then
        return player
    end
    local cs = cses[playerid % CSNUM + 1]
    player = cs(dbplayer, playerid)
    if not player then
        return
    end
    player.gettm = os.time()
    return player
end

M.save_player = function(player)
    local id = player.id
    -- db("hmset", "player", id, seri.pack(player))
end

return M
