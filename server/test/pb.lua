local skynet = require "skynet"
require "common.func.tool"

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

local sp = function()
    local sproto = require "sproto"
    local sp = sproto.parse [[
        .Phone {
            name 1 : string
            number 2 : integer
            test 3 : integer
        }

        .Person {
            name 1 : string
            arr 2 : *Phone
            map 3 : *Phone(name)
        }
    ]]
    local data = {
        name = "hello",
        arr = {
            { name = tostring(1), number = 1 },
            { name = tostring(2), number = 2 }
        },
        map = {
            [tostring(1)] = { name = tostring(1), number = 1 },
            [tostring(2)] = { name = tostring(2), number = 2 }
        }
    }
    local bin = sp:pencode("Person", data)
    local data2 = sp:pdecode("Person", bin)
    print(dump(data2))
end

skynet.start(function()
    pb()
    sp()
end)
