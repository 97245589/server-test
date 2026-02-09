local require = require
require "common.func.tool"
local skynet = require "skynet"
local cmds = require "common.service.cmds"

local start = function(func)
    skynet.start(function()
        local SERVICE_NAME = SERVICE_NAME
        skynet.dispatch("lua", function(_, _, cmd, ...)
            local f = cmds[cmd]
            if f then
                skynet.retpack(f(...))
            else
                print("cmd err", SERVICE_NAME, cmd)
                skynet.response()(false)
            end
        end)

        func()
    end)
end

return start
