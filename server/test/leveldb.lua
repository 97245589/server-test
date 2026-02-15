local skynet = require "skynet"
require "common.func.tool"

local printt = function(t)
    print(dump(t))
end
local test = function()
    local db = require "common.func.ldb"
    db("hmset", 10, "hello10", "world10")
    db("hmset", 1, "hello", "world", 10, 11, 20, 21)
    printt(db("hgetall", 1))
    printt(db("hmget", 1, 10, 30, "hello"))

    print("keys", dump(db("keys", "*")))

    db("hdel", 1, 10)
    printt(db("hgetall", 1))
    db("del", 1)
    printt(db("hgetall", 1))
    print("keys", dump(db("keys", "*")))
    db("del", 10)
    db("compact")
end

local test1 = function()
    local db = require "common.func.ldb"
    local t = skynet.now()
    for i = 1, 1000000 do
        db("hmset", "test", "hello" .. i, "world" .. i)
    end
    print(skynet.now() - t)

    local t = skynet.now()
    local val
    for i = 1, 1000000 do
        val = db("hmget", "test", "hello" .. i)
    end
    print(skynet.now() - t, val[1])
    db("del", "test")
    db("compact")
end

skynet.start(function()
    -- test()
    test1()
end)
