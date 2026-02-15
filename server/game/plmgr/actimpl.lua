local mgrs = require "server.game.plmgr.mgrs"
local acts = require "server.game.plmgr.acttm"

local M = {}

local dbactimpl
M.init = function(dbdata)
    dbdata.dbactimpl = dbdata.dbactimpl or {}
    dbactimpl = dbdata.dbactimpl
end

local impl = acts.impl

impl[100] = {}
impl[100].open = function(act)
    print("impl activity", dump(act))
    if not dbactimpl[act.id] then
        dbactimpl[act.id] = {}
    end
    local aimpl = dbactimpl[act.id]
end
impl[100].close = function(act)
end

mgrs.add_mgr(M, "actimpl")
return M
