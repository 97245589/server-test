local mode, loginaddr, cluster_addr = ...
local require = require
require "common.func.tool"
local skynet = require "skynet"
local socket = require "skynet.socket"

if mode == "child" then
    local pcall = pcall
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
        local acc, token = args.acc, args.token
        if name ~= "login_verify" or not acc or not token then
            return
        end

        acc = crypt.desdecode(secret, acc)
        token = crypt.desdecode(secret, token)

        send_package(fd, res({
            code = 0
        }))
        return acc
    end

    local choose_gameserver = function(fd, secret, acc)
        local _, name, args, res = get_req(fd)
        local server = args.server
        if name ~= "choose_gameserver" or not server then
            return
        end

        local host = skynet.call(cluster_addr, "lua", "acc_key", server, acc, secret)
        if not host then
            return
        end
        skynet.send(loginaddr, "lua", "acc_gameserver", acc, server)
        send_package(fd, res({
            code = 0,
            host = host
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

        if not choose_gameserver(fd, secret, acc) then
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

    local start = function(cluster_addr)
        local lattr = skynet.self()
        for i = 1, childnum do
            local addr = skynet.newservice("server/login/logind", "child", lattr, cluster_addr)
            table.insert(addrs, addr)
        end

        local gate_port = skynet.getenv("gate_port")
        local id = socket.listen("0.0.0.0", gate_port)
        socket.start(id, function(fd, addr)
            local s = addrs[fd % childnum + 1]
            skynet.send(s, "lua", fd, addr)
        end)
    end
    return start
end
