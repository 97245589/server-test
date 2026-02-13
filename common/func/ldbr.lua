local skynet = require "skynet"
local leveldb = require "lgame.leveldb"
local pdb

skynet.start(function()
    local print = skynet.error
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
