local ftool = require "common.func.tool"
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
    pb.option("encode_default_values")

    pbc:load [[
        syntax = "proto3";
        enum Cmd {
            Test_req = 0;
            Test_res = 1;
        }

        message req {
            Cmd cmd = 1;
            uint32 session = 2;
            bytes bin = 3;
        }

        message res {
            uint32 session = 1;
            bytes bin = 2;
        }

        message push {
            Cmd cmd = 1;
            bytes bin = 2;
        }

        message test_req {
            int32 test = 1;
            int32 add = 2;
        }
        message test_res {
            int32 code = 1;
            int32 test = 2;
        }
    ]]

    -- print(pb.enum("Cmd", 0), pb.enum("Cmd", "Test_req"))
    local session = 0
    local packreq = function(name, args)
        session = session + 1
        if session <= 0 or session > 100 then
            session = 1
        end
        return pb.encode("req", {
            cmd = name,
            session = session,
            bin = pb.encode(string.lower(name), args)
        })
    end

    local packpush = function(name, args)
        return pb.encode("push", {
            cmd = name,
            bin = pb.encode(string.lower(name), args)
        })
    end

    local packres = function(reqcmd, reqsess, args)
        local rescmd = pb.enum("Cmd", reqcmd) + 1
        local name = pb.enum("Cmd", rescmd)
        -- print("packres", string.lower(name))
        return pb.encode("res", {
            session = reqsess,
            bin = pb.encode(string.lower(name), args)
        })
    end

    local bin = packreq("Test_req", { test = 100 })
    local req = pb.decode("req", bin)
    local treq = pb.decode(string.lower(req.cmd), req.bin)
    print("getreq", req.cmd, dump(treq))
    bin = packres(req.cmd, req.session, {
        code = 0
    })

    local res = pb.decode("res", bin)
    print("getres", dump(pb.decode("test_res", res.bin)))
end

local leveldb = function()
    local printt = function(t)
        print(dump(t))
    end

    local test = function()
        local db = require "common.func.ldb"
        local call = db.call
        call("hmset", 10, "hello10", "world10")
        call("hmset", 1, "hello", "world", 10, 11, 20, 21)
        print(call("hget", 1, "hello"), call("hget", 1, 30))
        printt(call("hgetall", 1))
        printt(call("hmget", 1, 10, 30, "hello"))

        print("keys", dump(call("keys", "*")))

        call("hdel", 1, 10)
        printt(call("hgetall", 1))
        call("del", 1)
        printt(call("hgetall", 1))
        print("keys", dump(call("keys", "*")))
        call("del", 10)
        call("compact")
    end

    local test1 = function()
        local db = require "common.func.ldb"
        local call = db.call
        local t = skynet.now()
        for i = 1, 1000000 do
            call("hmset", "test", "hello" .. i, "world" .. i)
        end
        print(skynet.now() - t)

        local t = skynet.now()
        local val
        for i = 1, 1000000 do
            val = call("hmget", "test", "hello" .. i)
        end
        print(skynet.now() - t, val[1])
        call("del", "test")
        call("compact")
    end
    test1()
end

local tool = function()
    local clone = ftool.clone
    local split = ftool.split
    local tb = {
        int = 10,
        float = 10.10,
        bool = true,
        arr = { 2, "hello", { [100] = 30 } },
        map = { [100] = { id = 100 }, [200] = { id = 200, arr = { 10, 20, 30 } } }
    }
    print(dump(tb))
    local ntb = clone(tb)
    print(tb, ntb, dump(ntb))

    local str = "hello world 1  2 3"
    print(dump(split(str)))
    str = "/a/s/d/f//g"
    print(dump(split(str, '/')))
end

skynet.start(function()
    tool()
    -- leveldb()
    -- pb()
    -- cs()
    -- cfg()
end)
