local require = require
local io = io
local string = string
local skynet = require "skynet"
local crypt = require "skynet.crypt"
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
    local acc = args.acc
    local playerid = args.playerid
    local serverid = args.serverid
    local gamehost = args.gamehost
    local loginhost = args.loginhost
    local login_server = function()
        print("conn login server")
        local fd = socket.open(loginhost)
        local cpri = crypt.randomkey()
        local cpub = crypt.dhexchange(cpri)
        request(fd, "exchange", {
            cpub = cpub
        })
        local _, _, res = recv_data(fd)
        local spub = res.spub
        local secret = crypt.dhsecret(spub, cpri)
        print("exchange succ get secret", secret)

        request(fd, "login_verify", {
            acc = acc,
            acctoken = crypt.desencode(secret, acc)
        })
        recv_data(fd)
        request(fd, "select_gameserver", {
            serverid = serverid
        })
        recv_data(fd)
        socket.close(fd)
        skynet.sleep(10)
        return secret
    end

    local secret = login_server()
    local game_server = function()
        print("conn game server")
        local fd = socket.open(gamehost)
        request(fd, "verify", {
            acc = acc,
            acctoken = crypt.desencode(secret, acc)
        })
        recv_data(fd)
        request(fd, "select_player", {
            playerid = playerid
        })
        recv_data(fd)
        skynet.sleep(2)
        return fd
    end
    local fd = game_server()
    return fd
end

return {
    request = request,
    recv_data = recv_data,
    login = login,
}
