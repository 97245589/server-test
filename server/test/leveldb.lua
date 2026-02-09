local skynet = require "skynet"
require "common.func.tool"

local printt = function(t)
    print(dump(t))
end
local test = function()
    local db = require "common.func.leveldb"
    db.send("hset", 1, "hello", "world")
    db.send("hset", 10, "hello10", "world10")
    print(db.call("hget", 1, "hello"))
    db.send("hmset", 1, 10, 11, 30, 31, 20, 21, 50, 51)
    printt(db.call("hgetall", 1))
    printt(db.call("hkeys", 1))
    printt(db.call("hmget", 1, 10, 40, 50))
    printt(db.call("keys", "*"))

    db.send("hdel", 1, 20, 30, 60)
    printt(db.call("hgetall", 1))
    db.send("del", 1)
    printt(db.call("hgetall", 1))
    printt(db.call("keys", "*"))
    db.send("del", 10)
    db.call("compact")
end

local test1 = function()
    local db = require "common.func.leveldb"
    local t = skynet.now()
    for i = 1, 100000 do
        db.call("hmset", "test", "hello", "world")
    end
    print(skynet.now() - t)

    local t = skynet.now()
    local val
    for i = 1, 100000 do
        val = db.call("hget", "test", "hello")
    end
    print(skynet.now() - t, val)
end

skynet.start(function()
    -- test()
    test1()
end)
