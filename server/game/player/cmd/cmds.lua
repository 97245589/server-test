local require = require
local cmds = require "common.service.cmds"
local client = require "server.game.player.client"
local act = require "server.game.player.mgr.act"

cmds.player_enter = client.player_enter

cmds.acts = act.acts
cmds.actopen = act.actopen
cmds.actclose = act.actclose
