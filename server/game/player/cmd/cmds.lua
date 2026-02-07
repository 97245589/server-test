local require = require
local cmds = require "common.service.cmds"
local client = require "server.game.player.client"
local zstd = require "common.func.zstd"
local db = require "common.func.leveldb"
local player_mgr = require "server.game.player.player_mgr"

cmds.player_enter = client.player_enter

cmds.get_brief_info = function(playerid)
    local players = player_mgr.players
    local player = players[playerid]
    if player then
        return player.role
    end
end
