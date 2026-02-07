local require = require
local print = print
local dump = dump
local client = require "server.game.player.client"
local role = require "server.game.player.mgr.role"
local item = require "server.game.player.mgr.item"

local push = client.push
local req = client.req

req.get_data = function(player)
    local ret = {
        code = 0
    }
    push(player.id, "pushtest", {})
    return ret
end

return req
