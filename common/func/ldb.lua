local skynet = require "skynet"
local leveldb = require "lgame.leveldb"

local mode = ...

if mode == "write" then
    skynet.start(function()
        local print = skynet.error
        -- print("ldb write create")
        local pdb = leveldb.create("db/" .. skynet.getenv("server_mark"))
        local raddr = skynet.newservice("common/func/ldb", "read")
        skynet.send(raddr, "lua", "pdb", pdb)

        skynet.dispatch("lua", function(_, _, cmd, ...)
            if cmd == "raddr" then
                skynet.retpack(raddr)
            else
                -- print("write", cmd, ...)
                skynet.retpack(leveldb[cmd](pdb, ...))
            end
        end)
    end)
elseif mode == "read" then
    skynet.start(function()
        local print = skynet.error
        -- print("ldb read create")
        local pdb
        skynet.dispatch("lua", function(_, _, cmd, ...)
            if cmd == "pdb" then
                pdb = ...
                skynet.retpack()
            else
                -- print("read", cmd, ...)
                skynet.retpack(leveldb[cmd](pdb, ...))
            end
        end)
    end)
else
    local waddr = skynet.uniqueservice("common/func/ldb", "write")
    local raddr = skynet.call(waddr, "lua", "raddr")
    -- del keys hkeys hmset hget hmget hdel compact
    local wcmds = { del = 1, hdel = 1, hmset = 1, compact = 1 }

    return function(cmd, ...)
        if wcmds[cmd] then
            skynet.send(waddr, "lua", cmd, ...)
            -- skynet.call(waddr, "lua", cmd, ...)
        else
            return skynet.call(raddr, "lua", cmd, ...)
        end
    end
end
