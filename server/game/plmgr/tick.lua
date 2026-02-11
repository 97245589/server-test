local skynet = require "skynet"
local mgrs = require "server.game.plmgr.mgrs"

local dbdata = {}
local load = function()
end

local save = function()
end

local M = {}

M.get_dbdata = function()
    return dbdata
end

M.start_tick = function()
    skynet.fork(function()
        while true do
            skynet.sleep(100)
            local tm = os.time()
            -- if t % 20 == 0 then
            --     save()
            -- end
            mgrs.all_tick(tm)
        end
    end)
end

return M
