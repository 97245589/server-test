require "common.func.tool"
local skynet = require "skynet"

local cfg = function()
    local cfg = require "common.func.cfg"
    while true do
        skynet.sleep(100)
        print(dump(cfg.get("item")))
        cfg.reload("item")
    end
end

local cs = function()
    local queue = require "skynet.queue"
    local cs = queue()
    local v
    local func1 = function()
        v = 1
        print("func1", skynet.now())
        skynet.sleep(50)
        print("func1 after sleep", v)
    end
    local func2 = function()
        v = 2
        print("func2", skynet.now())
    end
    skynet.fork(func1)
    skynet.fork(func2)

    skynet.sleep(100)
    skynet.fork(cs, func1)
    skynet.fork(cs, func2)
end

local pb = function()
    local pbc = require "common.func.protoc"
    local pb = require "pb"
    pb.option("no_default_values")

    pbc:load [[
        syntax = "proto3";

        message Phone {
            string name = 1;
            int64 number = 2;
            int32 test = 3;
        }

        message Person {
            string name = 1;
            repeated Phone arr = 2;
            map<string, Phone> map = 3;
        }
    ]]

    local data = {
        name = "hello",
        arr = {
            { name = tostring(1), number = 1 },
            { name = tostring(2), number = 2 }
        },
        map = {
            [tostring(1)] = { number = 1 },
            [tostring(2)] = { number = 2 }
        }
    }
    local bin = pb.encode("Person", data)
    local data2 = pb.decode("Person", bin)
    print(dump(data2))
end

local leveldb = function()
    local printt = function(t)
        print(dump(t))
    end

    local test = function()
        local db = require "common.func.ldb"
        db("hmset", 10, "hello10", "world10")
        db("hmset", 1, "hello", "world", 10, 11, 20, 21)
        print(db("hget", 1, "hello"), db("hget", 1, 30))
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
end

skynet.start(function()
    -- leveldb()
    pb()
    -- cs()
    -- cfg()
end)
