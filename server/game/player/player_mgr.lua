local os = os
local table = table
local pairs = pairs
local next = next
local setmetatable = setmetatable
local rawget = rawget
local rawset = rawset
local db = require "common.func.ldb"
local skynet = require "skynet"

local M = {}
local savefields = {
    item = 1,
    role = 1
}

local __meta = {
    __index = function(player, k)
        local init_func = M.init_func
        local ifunc = init_func[k]
        if not ifunc then
            return
        end

        local vbin = player.__BIN[k]
        local val
        if vbin then
            val = skynet.unpack(vbin)
            player.__BIN[k] = nil
        else
            val = {}
        end
        rawset(player, k, val)
        -- print("__metainit", player.id, k)
        ifunc(player)
        return rawget(player, k)
    end
}

local players = {}
M.players = players

local player_db = function(playerid)
    -- local arr = db("hgetall", "pl" .. playerid)
    if players[playerid] then
        return players[playerid]
    end
    --[[
    local bin_player = {}
    if not next(arr) then
        return
    end
    for i = 1, #arr do
        local k = arr[i]
        local vbin = arr[i+1]
        bin_player[k] = vbin
    end
    ]]
    local player = setmetatable({
        __BIN = {},
    }, __meta)
    player.dirtys = {}
    players[playerid] = player
    return player
end

M.get_player = function(playerid)
    local player = players[playerid] or player_db(playerid)
    if not player then
        return
    end
    player.id = playerid
    player.gettm = os.time()
    return player
end

M.save_player = function(player)
    local dirtys = player.dirtys
    if not next(dirtys) then
        return
    end
    local arr = { "pl" .. player.id }
    for k in pairs(dirtys) do
        if savefields[k] and player[k] then
            table.insert(arr, k, skynet.packstring(player[k]))
        end
    end
    -- db("hmset", table.unpack(arr))
end

return M
