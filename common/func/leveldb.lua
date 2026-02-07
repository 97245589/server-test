local require = require
local skynet = require "skynet"

local mode = ...

if mode == "child" then
    -- {compact,keys,del,hgetall,hmget,hmset,hdel}
    skynet.start(function()
        local server = skynet.getenv("server_mark")
        local db
        skynet.dispatch("lua", function(_, _, cmd, ...)
            if not db then
                local ldb = require "lgame.leveldb"
                db = ldb.create("db/" .. server)
            end
            skynet.retpack(db[cmd](db, ...))
        end)
    end)
else
    local addr = skynet.uniqueservice("common/func/leveldb", "child")

    local M = {}

    M.send = function(...)
        skynet.send(addr, "lua", ...)
    end

    M.call = function(...)
        return skynet.call(addr, "lua", ...)
    end

    return M
end
