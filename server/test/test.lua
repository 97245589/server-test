require "common.func.tool"
local require = require
local print = print
local dump = dump
local skynet = require "skynet"
require "skynet.manager"

local zstd = function()
    local zstd = require "common.func.zstd"
    local bin = zstd.encode({
        hello = "world"
    })
    print(dump(zstd.decode(bin)))
end

local leveldb = function()
    local db = require "common.func.leveldb"
    db.call("hmset", "test", 1, 10, 2, 20, 3, 30)
    print(dump(db.call("hgetall", "test")))
    print("keys", dump(db.call("keys", "*")))
    db.call("hdel", "test", 2)
    print(dump(db.call("hgetall", "test")))
    db.call("del", "test")
    print(dump(db.call("keys", "*")))
end

local cfg = function()
    local cfg = require "common.func.cfg"
    while true do
        skynet.sleep(100)
        print(dump(cfg.get("item")))
        cfg.reload("item")
    end
end

local ip = function()
    local ip = require "common.func.ip"
    print(ip.private())
    print(ip.public())
end

skynet.start(function()
    -- skynet.abort()
end)
