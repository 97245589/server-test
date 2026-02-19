require "common.func.tool"
local skynet = require "skynet"
local socket = require "skynet.socket"
require "skynet.manager"

skynet.start(function()
    local fd, ret
    local port = skynet.getenv("port")
    local send = function(cmd)
        fd = socket.open("127.0.0.1", port)
        socket.write(fd, cmd)
        return socket.readall(fd)
    end

    skynet.fork(function()
        while true do
            skynet.sleep(10)
            if fd then
                socket.close(fd)
                fd = nil
            end
        end
    end)
    ret = send("list\n")
    local addr = ret:match("(:%x+)%s+snlua%s+server/center/init")
    if not addr then
        addr = ret:match("(:%x+)%s+snlua%s+server/game/init")
    end
    if not addr then
        print("no matchable addr")
        skynet.sleep(50)
        skynet.abort()
    end
    print("service addr", addr)
    send(string.format('call %s exit\n', addr))
    skynet.sleep(50)
    skynet.abort()
end)
