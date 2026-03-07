require "common.func.tool"
local skynet = require "skynet"
local socket = require "skynet.socket"
require "skynet.manager"

local fd
local port = skynet.getenv("port")
local dtype = skynet.getenv("debug")
local send = function(cmd)
    fd = socket.open("127.0.0.1", port)
    socket.write(fd, cmd)
    return socket.readline(fd, ">\n")
end

local handle = {
    close = function()
        local ret = send("list\n")
        local addr = ret:match("(:%x+)%s+snlua%s+server/game/init")
        send(string.format("call %s exit\n", addr))
        skynet.abort()
    end
}

skynet.start(function()
    print("debug console type", dtype)
    local func = handle[dtype]
    if func then
        func()
    else
        print("debug type err", dtype)
    end
end)
