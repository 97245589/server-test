local skynet = require "skynet"
require "common.func.tool"

local printt = function(t)
    print(dump(t))
end
local test = function()
    local db = require "common.func.leveldb"
    db.send("hset", 10, "hello10", "world10")
    db.send("hset", 1, "hello", "world")
    print("hget 1 hello", db.call("hget", 1, "hello"))
    db.send("hset", 1, 10, 11)
    db.send("hset", 1, 20, 21)

    print("hkeys", dump(db.call("hkeys", 1)))
    print("keys", dump(db.call("keys", "*")))

    db.send("hdel", 1, 10)
    print("hget 1 10 20", db.call("hget", 1, 10), db.call("hget", 1, 20))
    print("hkeys", dump(db.call("hkeys", 1)))
    db.send("del", 1)
    print("hkeys", dump(db.call("hkeys", 1)))
    print("keys", dump(db.call("keys", "*")))
    db.send("del", 10)
    db.call("compact")
end

local test1 = function()
    local db = require "common.func.leveldb"
    local t = skynet.now()
    for i = 1, 100000 do
        db.call("hset", "test", "hello", "world")
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
    test()
    -- test1()
end)
