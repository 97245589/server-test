local skynet = require "skynet"

local mode = ...

if mode == "child" then
    -- del keys hkeys hset hget hdel compact
    local ldb = require "lgame.leveldb"
    local db = ldb.create("db/" .. skynet.getenv("server_mark"))

    skynet.start(function()
        skynet.dispatch("lua", function(_, _, cmd, ...)
            skynet.retpack(db[cmd](db, ...))
        end)
    end)
else
    local addr = skynet.uniqueservice("common/func/ldb", "child")

    return function(...)
        return skynet.call(addr, "lua", ...)
    end
end
