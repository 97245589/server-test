local skynet = require "skynet"
local zstd = require "lgame.zstd"

local compress = zstd.compress
local decompress = zstd.decompress

local M = {}

M.compress = compress
M.decompress = decompress

M.encode = function(val)
    return compress(skynet.packstring(val))
end

M.decode = function(bin)
    return skynet.unpack(decompress(bin))
end

return M
