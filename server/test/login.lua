require "common.func.tool"
local skynet = require "skynet"
local client = require "server.test.func.client"

local login = client.login
local get_res = client.get_res
local send_req = client.send_req

local conn = function(args)
    local fd = login(args)
    send_req(fd, "get_data", {})

    -- skynet.fork(function()
    --     while true do
    --         skynet.sleep(100)
    --         send_req(fd, "get_data", {})
    --     end
    -- end)

    skynet.fork(function()
        while true do
            print(fd, get_res(fd))
        end
    end)
end

skynet.start(function()
    for i = 1, 1 do
        skynet.fork(conn, {
            acc = "acc" .. i,
            playerid = i,
            gamehost = "127.0.0.1:10012",
            -- serverid = 1,
            -- loginhost = "127.0.0.1:10031"
        })
    end
end)
