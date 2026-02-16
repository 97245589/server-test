local enums = require "server.game.player.enums"
local taskmgr = require "server.game.player.mgr.taskmgr"

local handle = {
    [enums.task_level] = function(player)
        return player.role.level
    end,
    [enums.task_hero_levelnum] = function(player, tevent)
        local herolevel = tevent[2]
    end
}

taskmgr.sethandle(handle)
