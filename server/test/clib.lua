require "common.func.tool"
local random = math.random
local skynet = require "skynet"

local zstd = function()
    print("zstd test ===")
    local zstd = require "common.func.zstd"
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

    local sbin, bin
    local t = skynet.now()
    for i = 1, 1000 do
        sbin = sp:pencode("Obj", obj)
    end
    print("sproto", skynet.now() - t, #sbin)
    skynet.sleep(1)
    local t = skynet.now()
    for i = 1, 1000 do
        bin = zstd.encode(obj)
    end
    print("zstd", skynet.now() - t, #bin)
    -- print(dump(zstd.decode(bin)))
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
    local core = lrank.create(5)
    for i = 1, 10 do
        core:add(i, i * 10, 0)
    end
    print(dump(core:info(1, 3)))
    print(core:get_order(1), core:get_order(10))

    local core = lrank.create(1000)
    local t = skynet.now()
    for i = 1, 1000000 do
        core:add(random(2000), random(20000), i)
    end
    print(skynet.now() - t)

    local t = skynet.now()
    local arr
    for i = 1, 10000 do
        arr = core:info(1, 1000)
    end
    print(skynet.now() - t, #arr)

    local t = skynet.now()
    local order = 0
    for i = 1, 3000000 do
        order = core:get_order(1000)
    end
    print(skynet.now() - t, order)
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

skynet.start(function()
    -- crc()
    -- rank()
    -- lru()
    -- zstd()
    msgpack()
    -- trie()
end)
