local require = require
local cmds = require "common.service.cmds"
local client = require "server.game.player.client"
local activity = require "server.game.player.mgr.activity"

cmds.player_enter = client.player_enter

cmds.actopens = activity.actopens
cmds.actopen = activity.actopen
cmds.actclose = activity.actclose
