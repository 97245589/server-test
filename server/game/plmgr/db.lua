local skynet = require "skynet"
local db = require "common.func.leveldb"
local zstd = require "common.func.zstd"
local mgrs = require "server.game.plmgr.mgrs"

local dbdata = {}
local load = function()
    local bin = db.call("hget", "game", "plmgr")
    if bin then
        return zstd.decode(bin)
    else
    end
end

local save = function()
    local bin = zstd.encode(dbdata)
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
