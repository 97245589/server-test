local require = require
local io = io
local pcall = pcall
local pairs = pairs
local next = next
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local fip = require "common.func.ip"

local ip = fip.private()
local port = skynet.getenv("cluster_port")
local host = ip .. ":" .. port
local server_mark = skynet.getenv("server_mark")

local server_host = {
    center = "172.27.158.158:10020"
}
server_host[server_mark] = host
cluster.reload(server_host)
cluster.open(server_mark)
cluster.register(server_mark, skynet.self())

local diff_func
if server_mark ~= "center" then
    local same = function(oobj, nobj)
        for ip, host in pairs(nobj) do
            local ohost = oobj[ip]
            if host ~= ohost then
                return
            end
            oobj[ip] = nil
        end
        if next(oobj) then
            return
        end
        return true
    end

    local conn_center = function()
        local ok, ret = pcall(cluster.call, "center", "@center", "heartbeat", server_mark, host)
        if not ok then
            return
        end

        local b = same(server_host, ret)
        server_host = ret
        if not b then
            cluster.reload(server_host)
            if diff_func then
                diff_func(server_host)
            end
            -- print("server_host change", dump(server_host))
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
