local skynet = require "skynet"

local mode = ...

if mode == "child" then
    local print = skynet.error
    -- del keys hkeys hmset hget hmget hdel compact
    skynet.start(function()
        local leveldb = require "lgame.leveldb"
        local pdb = leveldb.create("db/" .. skynet.getenv("server_mark"))
        local raddr = skynet.newservice("common/func/ldbr")
        skynet.send(raddr, "lua", "pdb", pdb)

        skynet.dispatch("lua", function(_, _, cmd, ...)
            if cmd == "raddr" then
                skynet.retpack(raddr)
            elseif cmd == "exit" then
                skynet.send(raddr, "lua", "exit")
                leveldb.release(pdb)
                pdb = nil
                skynet.retpack(true)
                print("ldb exit")
            else
                -- print("write", cmd, ...)
                skynet.retpack(leveldb[cmd](pdb, ...))
            end
        end)
    end)
else
    local waddr = skynet.uniqueservice("common/func/ldb", "child")
    local raddr = skynet.call(waddr, "lua", "raddr")
    local wcmds = { del = 1, hdel = 1, hmset = 1, compact = 1, exit = 1 }

    return function(cmd, ...)
        if wcmds[cmd] then
            skynet.send(waddr, "lua", cmd, ...)
            -- skynet.call(waddr, "lua", cmd, ...)
        else
            return skynet.call(raddr, "lua", cmd, ...)
        end
    end
end
