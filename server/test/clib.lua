require "common.func.tool"
local random = math.random
local skynet = require "skynet"

local encode_press = function()
    print("encode test ===")
    local msgpack = require "lgame.msgpack"
    local sproto = require "sproto"

    local sp = sproto.parse [[
        .Map {
            id 1 : integer
            level 2 : integer
            num 3 : integer
            hello 4 : integer
            world 5 : integer
        }

        .Obj {
            map 1 : *Map(id)
        }
    ]]

    local obj = {
        map = {}
    }
    for i = 1, 5000 do
        obj.map[i * 10] = {
            id    = i * 10,
            level = random(1000),
            num   = random(10000),
            hello = random(100000),
            world = random(1000000)
        }
    end

    local n = 1000
    local bin
    skynet.sleep(1)
    local t = skynet.now()
    for i = 1, n do
        bin = sp:pencode("Obj", obj)
    end
    print("sproto", skynet.now() - t, #bin)

    skynet.sleep(1)
    local t = skynet.now()
    for i = 1, n do
        bin = skynet.packstring(obj)
    end
    print("skynetpack", skynet.now() - t, #bin)

    skynet.sleep(1)
    local t = skynet.now()
    for i = 1, n do
        bin = msgpack.encode(obj)
    end
    print("msgpack", skynet.now() - t, #bin)
end

local lru = function()
    print("lru test ===")
    local lru = require "common.func.lru"

    local obj = lru(5)
    for i = 1, 5 do
        obj[i] = i
    end
    local v = obj[2]
    obj[2] = nil

    for i = 6, 9 do
        obj[i] = i
    end

    print(dump(obj))

    local t = skynet.now()
    for i = 1, 1000000 do
        obj[i] = i
    end
    print(skynet.now() - t, dump(obj))
end

local rank = function()
    print("rank test ===")
    local lrank = require "lgame.rank"
    local test = function()
        local core = lrank.create(5)
        for i = 1, 10 do
            core:add(i, i * 10, 0)
        end
        print(dump(core:info(3, 5)))
        print(dump(core:info(1, 10)))
        print(core:order(1), core:order(8))
    end
    test()

    local press = function()
        local core = lrank.create(1000)
        local t = skynet.now()
        for i = 1, 1000000 do
            core:add(random(2000), random(20000), i)
        end
        print(skynet.now() - t)

        local t = skynet.now()
        for i = 1, 10000 do
            local arr = core:info(1, 1000)
        end
        print(skynet.now() - t, #core:info(1, 1000))

        local t = skynet.now()
        local order = 0
        for i = 1, 3000000 do
            order = core:order(1000)
        end
        print(skynet.now() - t, order)
    end
    press()
end

local msgpack = function()
    print("msgpack test")
    local msgpack = require "lgame.msgpack"

    local obj = {
        obj = {
            id = 10,
            level = 10,
            name = "hello"
        },
        arr = { 1, 2, 3 },
        arr_obj = { { val = 10 }, { val = 20 } },
        map_test = { 1, 2, [100] = 200 },
        map = {
            [100] = {
                id = 100,
                num = 100,
                arr = { 10, 30, { hello = "world" } }
            },
            [200] = {
                id = 200,
                obj = { val = 200 },
                map = { [200] = 200 }
            }
        }
    }
    print(dump(skynet.unpack(skynet.packstring(obj))))
    local bin = msgpack.encode(obj)
    local nobj = msgpack.decode(bin)
    print(dump(nobj))
end

local trie = function()
    print("trie test")
    local trie = require "lgame.trie"
    local core = trie.create()

    for i = 1, 10 do
        core:insert(i, i)
    end
    core:erase(5)
    print(core:val(5), core:val(10))

    local bin = core:seri()
    print(#bin)
    local ncore = trie.create()
    ncore:deseri(bin)
    for i = 1, 10 do
        print(i, ncore:val(i))
    end
end

local crc = function()
    print("crc test")
    local luacrc = require "skynet.db.redis.crc16"
    local ccrc = require "lgame.tool".crc16

    local str = "watchdata" .. 100
    local val = luacrc(str)
    print(val, val == ccrc(str))

    local t = skynet.now()
    for i = 1, 1000000 do
        val = luacrc(str)
    end
    print(skynet.now() - t)

    local t = skynet.now()
    for i = 1, 1000000 do
        val = ccrc(str)
    end
    print(skynet.now() - t)
end

local timer = function()
    local func = require "common.func.timer"
    local timer = func(function(id, ...)
        print("expire", id, ...)
    end)
    timer.add(1, 1, "test1")
    timer.add(1, 10, "test1")
    timer.add(2, 3, "test2")
    timer.add(3, 5, 3)
    -- timer.del_id(2)
    -- timer.del_mark(1, "test1")
    timer.expire(5)
    print(dump(timer.info()))
end

skynet.start(function()
    -- timer()
    -- crc()
    -- rank()
    -- lru()
    -- msgpack()
    -- trie()
    encode_press()
end)
