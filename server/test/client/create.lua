local require = require
local io = io
local string = string
local skynet = require "skynet"
local socket = require "skynet.socket"

local load_proto = function()
    local sproto = require "sproto"
    local s2c_f = io.open("config/s2c.sproto")
    local c2s_f = io.open("config/c2s.sproto")
    local s2c_str = s2c_f:read("*a")
    local c2s_str = c2s_f:read("*a")
    s2c_f:close()
    c2s_f:close()
    local host = sproto.parse(s2c_str):host("package")
    local req = host:attach(sproto.parse(c2s_str))
    return host, req
end
local host, req_pack = load_proto()

local session = 0
local request = function(fd, name, args)
    session = session + 1
    if session < 1 or session > 120 then
        session = 1
    end
    local str = req_pack(name, args, session)
    socket.write(fd, string.pack(">s2", str))
    return name, session
end

local recv_data = function(fd)
    local lendata = socket.read(fd, 2)
    local len = lendata:byte(1) * 256 + lendata:byte(2)
    local msg = socket.read(fd, len)
    return host:dispatch(msg)
end

local login = function(args)
    local login_server = function()
    end

    local acc = args.acc or "acc"
    local playerid = args.playerid or 100
    local ipport = args.host or "127.0.0.1:10012"

    local fd = socket.open(ipport)
    request(fd, "verify", {
        acc = acc
    })
    recv_data(fd)
    request(fd, "select_player", {
        playerid = playerid
    })
    recv_data(fd)
    skynet.sleep(2)
    return fd
end

return {
    request = request,
    recv_data = recv_data,
    login = login,
}
