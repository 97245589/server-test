local require = require
local skynet = require "skynet"

local mode = ...

if mode == "child" then
    -- {compact,keys,del,hkeys,hget,hset,hdel}
    local ldb = require "lgame.leveldb"
    local zstd = require "lgame.zstd"
    local db = ldb.create("db/" .. skynet.getenv("server_mark"))

    local handle = {
        hset = function(key, field, val)
            local nval = zstd.compress(val)
            db:hset(key, field, nval)
            -- print("hset", key, field, nval)
        end,
        hget = function(key, field)
            local val = db:hget(key, field)
            if not val then
                return
            end
            local nval = zstd.decompress(val)
            -- print("hget", key, field, val)
            return nval
        end
    }

    skynet.start(function()
        skynet.dispatch("lua", function(_, _, cmd, ...)
            local ret
            local func = handle[cmd]
            if func then
                ret = func(...)
            else
                ret = db[cmd](db, ...)
            end
            skynet.retpack(ret)
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
