local skynet = require "skynet"
local start = require "common.service.start"

local require_files = function()
    require "server.game.plmgr.player"

    local mgrs = require "server.game.plmgr.mgrs"
    local db = require "server.game.plmgr.db"
    mgrs.all_init(db.get_dbdata())
end

start(function()
    require "server.game.rpc"
    skynet.timeout(50, require_files)
end)
