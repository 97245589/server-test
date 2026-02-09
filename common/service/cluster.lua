local require = require
local pcall = pcall
local pairs = pairs
local next = next
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local fip = require "common.func.ip"

local sip = fip.private()
local port = skynet.getenv("cluster_port")
local shost = sip .. ":" .. port
local server_mark = skynet.getenv("server_mark")
local centerhost = skynet.getenv("center_host")

local server_host = {
    center        = centerhost,
    [server_mark] = shost
}
cluster.reload(server_host)
cluster.open(server_mark)
cluster.register(server_mark, skynet.self())

local diff_func
if server_mark ~= "center" then
    local diff = function(oobj, nobj)
        local ret = {}

        for ip, host in pairs(nobj) do
            local ohost = oobj[ip]
            oobj[ip] = nil
            if host ~= ohost then
                ret.upd = ret.upd or {}
                ret.upd[ip] = host
            end
        end
        for ip, host in pairs(oobj) do
            ret.del = ret.del or {}
            ret.del[ip] = host
        end

        return next(ret) and ret
    end

    local conn_center = function()
        local ok, ret = pcall(cluster.call, "center", "@center", "heartbeat", server_mark, shost)
        if not ok or not ret then
            return
        end

        server_host.center = nil
        server_host[server_mark] = nil
        local diffobj = diff(server_host, ret)
        server_host = ret

        if diffobj then
            print("cluster diff", dump(diffobj))
            server_host.center = centerhost
            server_host[server_mark] = shost
            cluster.reload(server_host)
            if diff_func then
                diff_func(diffobj)
            end
        end
    end

    skynet.fork(function()
        while true do
            conn_center()
            skynet.sleep(300)
        end
    end)
end

local M = {}

M.get_server_host = function()
    return server_host
end

M.set_diff_func = function(func)
    diff_func = func
end

return M
