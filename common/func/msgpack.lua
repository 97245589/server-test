local msgpack = require "lgame.msgpack"
local core = msgpack.create()
return {
    decode = msgpack.decode,
    encode = function(v)
        return core:encode(v)
    end
}
