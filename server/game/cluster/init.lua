local require = require
local tonumber = tonumber
local skynet = require "skynet"
local start = require "common.service.start"
local fip = require "common.func.ip"
local cmds = require "common.service.cmds"

start(function()
    require "server.game.rpc"
    local gametype = tonumber(skynet.getenv("gametype"))
    if gametype == 1 then
        return
    end
    skynet.timeout(0, function()
        local ip
        require "common.service.cluster"
        if gametype == 2 then
            ip = fip.private()
        elseif gametype == 3 then
            ip = fip.public()
        end

        local host = ip .. ":" .. skynet.getenv("gate_port")
        cmds.public_host = function()
            return host
        end
    end)
end)
