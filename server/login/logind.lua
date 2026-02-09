local mode, loginaddr = ...
local require = require
require "common.func.tool"
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local socket = require "skynet.socket"

if mode == "child" then
    local proto = require "common.func.proto"
    local crypt = require "skynet.crypt"

    local host = proto()
    local spack = string.pack

    local send_package = function(fd, pack)
        local package = spack(">s2", pack)
        socket.write(fd, package)
    end

    local get_req = function(fd)
        local len = socket.read(fd, 2)
        len = len:byte(1) * 256 + len:byte(2)
        local msg = socket.read(fd, len)
        return host:dispatch(msg)
    end

    local exchange = function(fd, spub)
        local _, name, args, res = get_req(fd)

        local cpub = args.cpub
        if name ~= "exchange" or not cpub then
            return
        end
        send_package(fd, res({
            code = 0,
            spub = spub
        }))
        return cpub
    end

    local verify = function(fd, secret)
        local _, name, args, res = get_req(fd)
        local acc, acctoken = args.acc, args.acctoken
        if name ~= "login_verify" or not acc or not acctoken then
            return
        end

        if crypt.desencode(secret, acc) ~= acctoken then
            print("login verity err", acc)
            return
        end

        send_package(fd, res({
            code = 0
        }))
        return acc
    end

    local select_gameserver = function(fd, secret, acc)
        local _, name, args, res = get_req(fd)
        local serverid = args.serverid
        if name ~= "select_gameserver" or not serverid then
            return
        end

        local server = "game" .. serverid
        skynet.send(loginaddr, "lua", "acc_gameserver", acc, server)
        cluster.send(server, "watchdog", "acc_secret", acc, secret)
        send_package(fd, res({
            code = 0,
        }))
        return true
    end

    local login = function(fd, addr)
        local spri = crypt.randomkey()
        local spub = crypt.dhexchange(spri)

        local cpub = exchange(fd, spub)
        if not cpub then
            return
        end

        local secret = crypt.dhsecret(cpub, spri)
        local acc = verify(fd, secret)
        if not acc then
            return
        end

        if not select_gameserver(fd, secret, acc) then
            return
        end
    end

    skynet.start(function()
        skynet.dispatch("lua", function(_, _, fd, addr)
            socket.start(fd)
            socket.limit(fd, 4096)
            pcall(login, fd, addr)
            socket.close(fd)
            skynet.response()(false)
        end)
    end)
else
    local table = table
    local addrs = {}
    local childnum = 10

    local lattr = skynet.self()
    for i = 1, childnum do
        local addr = skynet.newservice("server/login/logind", "child", lattr)
        table.insert(addrs, addr)
    end

    local gate_port = skynet.getenv("gate_port")
    local id = socket.listen("0.0.0.0", gate_port)
    socket.start(id, function(fd, addr)
        local s = addrs[fd % childnum + 1]
        skynet.send(s, "lua", fd, addr)
    end)
end
