local require = require
local mgrs = require "server.game.player.mgr.mgrs"

local M = {}

M.init = function(player)
    player.role = player.role or {}
    local role = player.role
    -- role.playerid
    -- role.acc
    role.level = role.level or 0
end

-- M.tick = function(player)
--     print("role test tick", dump(player))
-- end

mgrs.add_mgr(M, "role")
return M
