local require = require
local tonumber = tonumber
local skynet = require "skynet"
local start = require "common.service.start"
local fip = require "common.func.ip"
local cmds = require "common.service.cmds"

local watchdog
local game_host

start(function()
    local rpc = require "server.game.rpc"
    local gametype = tonumber(skynet.getenv("gametype"))
    if gametype == 1 then
        return
    end
    local ip
    if gametype == 2 then
        ip = fip.private()
    elseif gametype == 3 then
        ip = fip.public()
    end

    skynet.timeout(100, function()
        local addrs = rpc.get_addrs()
        watchdog = addrs.watchdog

        local gate_port = skynet.getenv("gate_port")
        game_host = ip .. ":" .. gate_port

        cmds.gameserver_info = function()
            return {
                watchdog = watchdog,
                host = game_host
            }
        end
        require "common.service.cluster"
    end)
end)
