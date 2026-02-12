local skynet = require "skynet"

local mode = ...

if mode == "child" then
    -- del keys hkeys hset hget hdel compact

    skynet.start(function()
        local db
        skynet.dispatch("lua", function(_, _, cmd, ...)
            if not db then
                local ldb = require "lgame.leveldb"
                db = ldb.create("db/" .. skynet.getenv("server_mark"))
            end
            skynet.retpack(db[cmd](db, ...))
        end)
    end)
else
    local addr = skynet.uniqueservice("common/func/ldb", "child")

    return function(...)
        return skynet.call(addr, "lua", ...)
    end
end
