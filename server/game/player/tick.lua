local require = require
local table = table
local next = next
local pairs = pairs
local os = os
local skynet = require "skynet"
local player_mgr = require "server.game.player.player_mgr"
local client = require "server.game.player.client"
local timer = require "server.game.player.timer"

local players = player_mgr.players
local playerids = {}
local save_kick = function(tm)
    if not next(playerids) then
        for playerid in pairs(players) do
            table.insert(playerids, playerid)
        end
    end

    for i = 1, 3 do
        if not next(playerids) then
            return
        end
        local playerid = table.remove(playerids)
        local player = players[playerid]
        player_mgr.save_player(player)
        if tm > player.role.gettm + 10 then
            players[playerid] = nil
            timer.timer.del_id(playerid)
            client.kick_player(playerid)
        end
    end
end

skynet.fork(function()
    while true do
        skynet.sleep(100)
        local tm = os.time()
        save_kick(tm)
        timer.timer.expire(tm)
    end
end)
