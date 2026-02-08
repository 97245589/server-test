local skynet = require "skynet"
local mgrs = require "server.game.plmgr.mgrs"
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

skynet.fork(function()
    while true do
        skynet.sleep(100)
        local t = os.time()
        mgrs.all_tick(t)
        -- if t % 20 == 0 then
        --     save()
        -- end
    end
end)

return {
    get_dbdata = function()
        return dbdata
    end
}
