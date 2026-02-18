local require = require
local cmds = require "common.service.cmds"
local client = require "server.game.player.client"
local activity = require "server.game.player.mgr.activity"
local player_mgr = require "server.game.player.player_mgr"

cmds.player_enter = client.player_enter

cmds.actopens = activity.actopens
cmds.actopen = activity.actopen
cmds.actclose = activity.actclose

cmds.player_role = function(playerid)
    return player_mgr.get_player(playerid, "role")
end
