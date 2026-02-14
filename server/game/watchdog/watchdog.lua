local require = require
local print = print
local skynet = require "skynet"
require "skynet.manager"
local cmds = require "common.service.cmds"
local rpc = require "server.game.rpc"

skynet.register("watchdog")
local gate = skynet.newservice("gate")
skynet.call(gate, "lua", "open", {
    port = skynet.getenv("gate_port"),
    maxclient = 8888,
    nodelay = true
})
rpc.send_all("watchdata", "gate", gate)

local acc_secret = {}
local acc_fd = {}
local fd_acc = {}
local close_conn = function(fd)
    local acc = fd_acc[fd]
    if acc then
        acc_secret[acc] = nil
        acc_fd[acc] = nil
        fd_acc[fd] = nil
    end
    print("closeconn", fd, acc)
    skynet.send(gate, "lua", "kick", fd)
end

cmds.acc_secret = function(acc, secret)
    -- print("set acc secret", acc, secret)
    acc_secret[acc] = secret
end

cmds.kick_acc = function(acc)
    local fd = acc_fd[acc]
    if fd then
        close_conn(fd)
    end
end

cmds.get_secret = function(acc)
    -- print("get acc secret", acc, acc_secret[acc])
    return acc_secret[acc]
end

cmds.fd_acc = function(fd, acc)
    -- print("verify success", fd, acc)
    local bfd = acc_fd[acc]
    if bfd then
        fd_acc[bfd] = nil
        skynet.send(gate, "lua", "kick", fd)
    end
    acc_fd[acc] = fd
    fd_acc[fd] = acc
end

-- cmds.select_player = function(fd, acc, playerid)
--     rpc.send_id("player", "player_enter", playerid, fd, acc, gate)
-- end

cmds.close_conn = close_conn

local socket_cmds = {
    open = function(fd, addr)
        skynet.send(gate, "lua", "accept", fd)
    end,
    close = function(fd)
        close_conn(fd)
    end,
    error = function(fd, msg)
        print("socket error", fd, msg)
        close_conn(fd)
    end,
    warning = function(fd, size)
        print("socket warning", fd, size)
    end,
    data = function(fd, msg)
        local acc = fd_acc[fd]
        rpc.send_id("watchdata", "data", fd, msg, acc)
    end
}
cmds.socket = function(cmd, ...)
    local func = socket_cmds[cmd]
    if func then
        func(...)
    end
end
