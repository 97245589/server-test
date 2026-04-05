local ltimer = require "lgame.timer"
local skynet = require "skynet"

return function(cb)
    local core = ltimer.create()

    local M = {}

    M.add = function(id, tm, cmd, ...)
        -- print("=== timer add", id, tm, cmd, ...)
        core:add(id, tm, skynet.packstring(cmd, ...))
    end

    M.delid = function(id)
        core:delid(id)
    end

    M.del = function(id, cmd, ...)
        core:del(id, skynet.packstring(cmd, ...))
    end

    M.expire = function(tm)
        local arr = core:expire(tm)
        for i = 1, #arr, 2 do
            local id = arr[i]
            local mark = arr[i + 1]
            cb(id, skynet.unpack(mark))
        end
    end

    M.dump = function()
        return core:dump()
    end

    return M
end
