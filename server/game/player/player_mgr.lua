local os = os
local print = print
local table = table
local pairs = pairs
local ipairs = ipairs
local next = next
local db = require "common.func.ldb"
local skynet = require "skynet"
local squeue = require "skynet.queue"

local savefields = { "role", "item" }
local fieldmark = {}
for idx, field in ipairs(savefields) do
    if fieldmark[field] then
        print("err fieldmark repeated", field)
    else
        fieldmark[field] = 1
    end
end
local field_mgrname = {}

local players = {}
local M = {}
M.players = players

local dbplayer = function(playerid, field)
    local player = players[playerid]
    if player then
        if not player.part then
            return player
        elseif field and player[field] then
            return player
        end
    end
    print("get db player", playerid, field)

    local selectfields
    if field then
        selectfields = { field }
    else
        if player then
            selectfields = {}
            for idx, sfield in ipairs(savefields) do
                if not player[sfield] then
                    table.insert(selectfields, sfield)
                end
            end
            if not next(selectfields) then
                player.part = nil
                return player
            end
        else
            selectfields = savefields
        end
    end

    local binarr = db("hmget", "pl" .. playerid, table.unpack(selectfields))

    if player then
        if not field then
            player.part = nil
        end
    else
        players[playerid] = { id = playerid, saves = {} }
        player = players[playerid]
        if field then
            player.part = 1
        end
    end

    for idx, sfield in ipairs(selectfields) do
        local vbin = binarr[idx]
        player[sfield] = vbin and skynet.unpack(vbin) or {}
        local ifunc = M.mgrs.inits[sfield]
        -- print("part player initfunc test", sfield)
        ifunc(player)
    end

    return player
end

local cses = {}
local CSNUM = 5
for i = 1, CSNUM do
    table.insert(cses, squeue())
end
M.get_player = function(playerid, field)
    if field and not fieldmark[field] then
        print("getplayer field err", playerid, field)
        return
    end
    local player = players[playerid]
    if player then
        player.gettm = os.time()
        if not player.part then
            return player
        elseif field and player[field] then
            return player
        end
    end
    local cs = cses[playerid % CSNUM + 1]
    player = cs(dbplayer, playerid, field)
    player.gettm = os.time()
    return player
end

M.save_player = function(player)
    local saves = player.saves
    if not next(saves) then
        return
    end
    local arr = { "pl" .. player.id }
    for k in pairs(saves) do
        if fieldmark[k] and player[k] then
            table.insert(arr, k, skynet.packstring(player[k]))
        else
            print("player saves key err", k)
        end
    end
    -- db("hmset", table.unpack(arr))
end

return M
