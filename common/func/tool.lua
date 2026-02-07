local string = string
local table = table
local tconcat = table.concat
local tinsert = table.insert
local srep = string.rep
local type = type
local pairs = pairs
local tostring = tostring
local next = next
local skynet = require "skynet"

print = skynet.error

dump = function(root)
    local cache = {
        [root] = "."
    }
    local function _dump(t, space, name)
        local temp = {}
        for k, v in pairs(t) do
            local key = tostring(k)
            if cache[v] then
                tinsert(temp, "+" .. key .. " {" .. cache[v] .. "}")
            elseif type(v) == "table" then
                local new_key = name .. "." .. key
                cache[v] = new_key
                tinsert(temp, "+" .. key .. _dump(v, space .. (next(t, k) and "|" or " ") .. srep(" ", #key), new_key))
            else
                tinsert(temp, "+" .. key .. " [" .. tostring(v) .. "]")
            end
        end
        return tconcat(temp, "\n" .. space)
    end
    return _dump(root, "", "") .. "$ \n"
end

clone = function(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return new_table
        -- return setmetatable(new_table, getmetatable(object))
    end

    return _copy(object)
end

split = function(str, sp)
    sp = sp or " "
    if type(sp) == "number" then
        sp = string.char(sp)
    end

    local patt = string.format("[^%s]+", sp)
    local arr = {}
    for k in string.gmatch(str, patt) do
        table.insert(arr, k)
    end
    return arr
end
