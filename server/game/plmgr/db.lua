local skynet = require "skynet"
local db = require "common.func.leveldb"
local mgrs = require "server.game.plmgr.mgrs"

local dbdata = {}
local load = function()
    local bin = db.call("hget", "game", "plmgr")
    if bin then
    else
    end
end

local save = function()
    db.send("hset", "game", "plmgr", bin)
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
