require "common.func.tool"
local require = require
local tostring = tostring
local print = print
local dump = dump
local skynet = require "skynet"
local client = require "server.test.client.create"

local login = client.login
local recv_data = client.recv_data
local request = client.request

local conn = function(args)
    skynet.fork(function()
        local fd = login(args)
        request(fd, "get_data", {})

        skynet.fork(function()
            while true do
                print(fd, recv_data(fd))
            end
        end)
    end)
end

skynet.start(function()
    for i = 1, 1 do
        conn({
            acc = "acc" .. i,
            playerid = i,
            host = "127.0.0.1:10012"
        })
    end
end)
