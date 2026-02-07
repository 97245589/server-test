local require = require
local print = print
local skynet = require "skynet"
local socket = require "skynet.socket"
local proto = require "common.func.proto"
local rpc = require "server.game.rpc"
local player_mgr = require "server.game.player.player_mgr"

local spack = string.pack
local fd_playerid = {}
local playerid_fd = {}
local proto_host, proto_push = proto()

local M = {}
local req = {}
M.req = req

local close_conn = function(fd)
    local playerid = fd_playerid[fd]
    if playerid then
        playerid_fd[playerid] = nil
    end
    fd_playerid[fd] = nil
    rpc.send("watchdog", "close_conn", fd)
end

local send_package = function(fd, pack)
    socket.write(fd, spack(">s2", pack))
end

M.kick_player = function(playerid)
    local fd = playerid_fd[playerid]
    if fd then
        close_conn(fd)
    end
    playerid_fd[playerid] = nil
end

M.push = function(playerid, name, args)
    local fd = playerid_fd[playerid]
    if not fd then
        return
    end
    local str = proto_push(name, args, 0)
    send_package(fd, str)
end

M.player_enter = function(playerid, fd, acc, gate)
    print("player_enter", playerid, fd, acc)
    local bfd = playerid_fd[playerid]
    if bfd then
        close_conn(bfd)
    end

    skynet.send(gate, "lua", "forward", fd)
    fd_playerid[fd] = playerid
    playerid_fd[playerid] = fd
    local player = player_mgr.get_player(playerid)
    if not player then
        close_conn(fd)
        return
    end
    local prole = player.role
    prole.online = 1
    prole.playerid = playerid
    prole.acc = acc
end

local handle_req = function(fd, cmd, args, res)
    local playerid = fd_playerid[fd]
    if not playerid then
        close_conn(fd)
        return
    end
    local player = player_mgr.get_player(playerid)

    local func = req[cmd]
    local ret = func(player, args) or {
        code = -1
    }
    return res(ret)
end
skynet.register_protocol({
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = function(msg, sz)
        return proto_host:dispatch(msg, sz)
    end,
    dispatch = function(fd, _, type, cmd, ...)
        skynet.ignoreret()
        send_package(fd, handle_req(fd, cmd, ...))
    end
})

return M
