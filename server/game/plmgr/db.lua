local skynet = require "skynet"
local db = require "common.func.leveldb"
local zstd = require "common.func.zstd"

local gameid = tonumber(skynet.getenv("server_id"))
local dbkey = "game" .. gameid
local dbfkey = "plmgr"

local dbdata = {}
local load = function()
    local bin = db.call("hget", dbkey, dbfkey)
    if bin then
        return zstd.decode(bin)
    else
    end
end

local save = function()
    local bin = zstd.encode(dbdata)
    db.send("hset", dbkey, dbfkey, bin)
end


local M = {}

M.get_dbdata = function()
    return dbdata
end

M.start_tick = function()
    skynet.fork(function()
        while true do
            skynet.sleep(100)
            local t = os.time()
            -- if t % 20 == 0 then
            --     save()
            -- end
        end
    end)
end

return M
