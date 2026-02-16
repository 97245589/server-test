local cfgf = require "common.func.cfg"
local taskmgr = require "server.game.player.mgr.taskmgr"

local __testtaskcfg = { [100] = { event = { 1, 10 } } }
local tasktype_activity = { [100] = __testtaskcfg }
local impl = {}

for k, taskcfg in pairs(tasktype_activity) do
    impl[k] = {
        open = function(player, pactdata, tmobj)
            pactdata[k] = {}
            taskmgr.init_task(player, pactdata[k], taskcfg)
            player.saves.activity = 1
        end,
        close = function(player, pactdata)
            pactdata[k] = nil
            player.saves.activity = 1
        end
    }
end

taskmgr.add("activity", function(player, eventarr)
    local pactivity = player.activity
    local pacttm = pactivity.acttm
    local pactdata = pactivity.actdata

    for k, taskcfg in pairs(tasktype_activity) do
        if pacttm[k] and pactdata[k] then
            local changedtask = taskmgr.count_task(player, pactdata[k], taskcfg, eventarr)
        end
    end
end)

return impl
