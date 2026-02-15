local mgrs = require "server.game.player.mgrs"
local players = require "server.game.player.player_mgr".players

local acts
local M = {}

M.acts = function(val)
    acts = val
    -- print("rpc acts", dump(acts))
end

M.actopen = function(actid, act)
    print("actopen", actid, dump(act))
    acts[actid] = act
end

M.actclose = function(actid, ract)
    -- print("actclose", actid, dump(act))
    acts[actid] = nil
end

mgrs.add_mgr(M, "act")
return M
