local skynet = require "skynet"
local ltool = require "lgame.tool"
print = skynet.error
dump = ltool.dump

return {
    clone = ltool.clone,
    tblen = ltool.tblen,
    split = function(str, sp)
        sp = sp or " "
        if type(sp) == "number" then
            sp = string.char(sp)
        end

        local patt = string.format("[^%s]+", sp)
        local arr = {}
        for k in string.gmatch(str, patt) do
            table.insert(arr, k)
        end
        return arr
    end
}
