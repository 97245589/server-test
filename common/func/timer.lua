local ltimer = require "lgame.timer"
local skynet = require "skynet"

return function(cb)
    local core = ltimer.create()

    local M = {}

    M.add = function(id, tm, cmd, ...)
        core:add(id, tm, skynet.packstring(cmd, ...))
    end

    M.del_id = function(id)
        core:del_id(id)
    end

    M.del_mark = function(id, cmd, ...)
        core:del_mark(id, skynet.packstring(cmd, ...))
    end

    M.expire = function(tm)
        local arr = core:expire(tm)
        for i = 1, #arr, 2 do
            local id = arr[i]
            local mark = arr[i + 1]
            cb(id, skynet.unpack(mark))
        end
    end

    M.info = function()
        return core:info()
    end

    return M
end
