local setmetatable = setmetatable
local require = require
local llru = require "lgame.lru"

return function(num)
    local lru = llru.create(num)

    local obj = {
        __INFO = {}
    }
    setmetatable(obj, {
        __index = function(tb, k)
            local v = tb.__INFO[k]
            if v then
                lru:update(k)
            end
            return v
        end,
        __newindex = function(tb, k, v)
            if v ~= nil then
                local evict = lru:update(k)
                if evict then
                    tb.__INFO[evict] = nil
                end
            else
                lru:del(k)
            end
            tb.__INFO[k] = v
        end,
    })
    return obj
end
