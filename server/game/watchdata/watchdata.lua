local skynet = require "skynet"
local cmds = require "common.service.cmds"
local rpc = require "server.game.rpc"
local socket = require "skynet.socket"
local crypt = require "skynet.crypt"

local gametype = tonumber(skynet.getenv("gametype"))
local proto = require "common.func.proto"
local host = proto()

local close = function(fd)
    rpc.send("watchdog", "close_conn", fd)
end

local handle = {}

handle.verify = function(args, _, fd)
    local acc = args.acc
    if not acc then
        return
    end
    if gametype ~= 1 then
        local acctoken = args.acctoken
        if not acctoken then
            return
        end
        local secret = rpc.call("watchdog", "get_secret", acc)
        -- print(acc, acctoken, secret)
        if not secret then
            return
        end
        if acctoken ~= crypt.desencode(secret, acc) then
            return
        end
    end

    rpc.send("watchdog", "fd_acc", fd, acc)
    return {
        code = 0
    }
end

handle.select_player = function(args, acc, fd)
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

local req = function(fd, msg, acc)
    local t, name, args, res = host:dispatch(msg)
    if not name then
        return
    end
    -- print("watchdata req", name, dump(args))
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
