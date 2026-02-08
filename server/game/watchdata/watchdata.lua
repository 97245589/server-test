local skynet = require "skynet"
local cmds = require "common.service.cmds"
local rpc = require "server.game.rpc"
local socket = require "skynet.socket"

local gametype = tonumber(skynet.getenv("gametype"))
local proto = require "common.func.proto"
local host = proto()

local close = function(fd)
    rpc.send("watchdog", "close_conn", fd)
end

local handle = {
    verify = function(args, _, fd)
        local acc = args.acc
        if gametype ~= 1 then
            local key = rpc.call("watchdog", "get_key", acc)
            if not key then
                return
            end
        end

        rpc.send("watchdog", "fd_acc", fd, acc)
        return {
            code = 0
        }
    end,
    select_player = function(args, acc, fd)
        if not acc then
            return
        end
        local playerid = args.playerid
        if not playerid then
            return
        end
        rpc.send("watchdog", "select_player", fd, acc, playerid)
        return {
            code = 0
        }
    end
}

local req = function(fd, msg, acc)
    local t, name, args, res = host:dispatch(msg)
    if not name then
        return
    end
    local func = handle[name]
    if not func then
        return
    end
    local ret = func(args, acc, fd)
    if not ret then
        return
    end
    socket.write(fd, string.pack(">s2", res(ret)))
    return true
end


cmds.data = function(fd, msg, acc)
    local ret = req(fd, msg, acc)
    if not ret then
        close(fd)
    end
end
