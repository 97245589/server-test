local require = require
local mgrs = require "server.game.player.mgrs"

local M = {}

M.init = function(player)
    player.role = player.role or {}
    local role = player.role
    -- role.playerid
    -- role.acc
    -- role.online
    role.level = role.level or 1
end

mgrs.add_mgr(M, "role")
return M
