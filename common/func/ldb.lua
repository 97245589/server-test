local skynet = require "skynet"

local mode = ...

if mode == "child" then
    -- del keys hkeys hset hget hdel compact
    skynet.start(function()
        local leveldb = require "lgame.leveldb"
        local pdb

        skynet.dispatch("lua", function(_, _, cmd, ...)
            if not pdb then
                pdb = leveldb.create("db/" .. skynet.getenv("server_mark"))
            end
            skynet.retpack(leveldb[cmd](pdb, ...))
        end)
    end)
else
    local addr = skynet.uniqueservice("common/func/ldb", "child")

    return function(cmd, ...)
        return skynet.call(addr, "lua", cmd, ...)
    end
end
