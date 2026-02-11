local skynet = require "skynet"
require "common.func.tool"

local printt = function(t)
    print(dump(t))
end
local test = function()
    local db = require "common.func.ldb"
    db("hset", 10, "hello10", "world10")
    db("hset", 1, "hello", "world")
    print("hget 1 hello", db("hget", 1, "hello"))
    db("hset", 1, 10, 11)
    db("hset", 1, 20, 21)

    print("hkeys", dump(db("hkeys", 1)))
    print("keys", dump(db("keys", "*")))

    db("hdel", 1, 10)
    print("hget 1 10 20", db("hget", 1, 10), db("hget", 1, 20))
    print("hkeys", dump(db("hkeys", 1)))
    db("del", 1)
    print("hkeys", dump(db("hkeys", 1)))
    print("keys", dump(db("keys", "*")))
    db("del", 10)
    db("compact")
end

local test1 = function()
    local db = require "common.func.ldb"
    local t = skynet.now()
    for i = 1, 100000 do
        db("hset", "test", "hello", "world")
    end
    print(skynet.now() - t)

    local t = skynet.now()
    local val
    for i = 1, 100000 do
        val = db("hget", "test", "hello")
    end
    print(skynet.now() - t, val)
    db("del", "test")
end

skynet.start(function()
    -- test()
    test1()
end)
