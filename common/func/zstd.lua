local skynet = require "skynet"
local zstd = require "lgame.zstd"

local pack = skynet.packstring
local unpack = skynet.unpack
local compress = zstd.compress
local decompress = zstd.decompress

local M = {}

M.compress = compress
M.decompress = decompress

M.encode = function(val)
    return compress(pack(val))
end

M.decode = function(bin)
    return unpack(decompress(bin))
end

return M
