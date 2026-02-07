local skynet = require "skynet"
local db     = require "common.func.leveldb"
local zstd   = require "common.func.zstd"

local gameid = skynet.getenv("server_id")
local dbkey  = "game" .. gameid
local dbfkey = "plmgr"

-- local dbdata = db.call("hget", dbkey, dbfkey)
local dbdata = {}
local ticks  = {}

local M      = {}
M.dbdata     = dbdata
M.ticks      = ticks

skynet.fork(function()
    while true do
        skynet.sleep(100)
        local tm = os.time()
        for _, func in pairs(ticks) do
            func(tm)
        end
        if tm % 20 == 0 then
            -- db.send("hmset", dbkey, dbfkey, zstd.encode(dbdata))
        end
    end
end)

return M
