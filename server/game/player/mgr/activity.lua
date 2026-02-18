local pairs = pairs
local print = print
local mgrs = require "server.game.player.mgrs"
local actimpl = require "server.game.player.mgr.actimpl"
local players = require "server.game.player.player_mgr".players

local actopens
local M = {}

local actopen = function(player, pacttm, pactdata, actid, atm)
    print("actopen ===", actid)
    pacttm[actid] = {
        id = actid,
        starttm = atm.starttm,
        endtm = atm.endtm,
    }
    if actimpl[actid] then
        actimpl[actid].open(player, pactdata, atm)
    end
end

local actclose = function(player, pacttm, pactdata, actid, ptm)
    pacttm[actid] = nil
    if actimpl[actid] then
        actimpl[actid].close(player, pactdata, ptm)
    end
end

M.init = function(player)
    player.activity = player.activity or {}
    local pactivity = player.activity
    pactivity.acttm = pactivity.acttm or {}
    pactivity.actdata = pactivity.actdata or {}
    local pacttm = pactivity.acttm
    local pactdata = pactivity.actdata

    for actid, ptm in pairs(pacttm) do
        local atm = actopens[actid]
        if not atm or atm.starttm ~= ptm.starttm then
            actclose(player, pacttm, pactdata, actid, ptm)
        end
    end

    for actid, atm in pairs(actopens) do
        local ptm = pacttm[actid]
        if not ptm then
            actopen(player, pacttm, pactdata, actid, atm)
        end
    end
end

M.actopens = function(val)
    actopens = val
    -- print("rpc actopens", dump(acttm))
end

M.actopen = function(actid, act)
    actopens[actid] = act
    -- print("actopen", actid, dump(acttm))
    for playerid, player in pairs(players) do
        if not player.activity then
            goto cont
        end
        local pactivity = player.activity
        local pacttm = pactivity.acttm
        local pactdata = pactivity.actdata
        if pacttm[actid] then
            print("activity open err already cover", playerid, actid)
        end
        actopen(player, pacttm, pactdata, actid, act)
        ::cont::
    end
end

M.actclose = function(actid, ract)
    -- print("actclose", actid, dump(act))
    actopens[actid] = nil
    for playerid, player in pairs(players) do
        if not player.activity then
            goto cont
        end
        local pactivity = player.activity
        local pacttm = pactivity.acttm
        local pactdata = pactivity.actdata
        local ptm = pacttm[actid]
        if not ptm or ptm.starttm ~= ract.starttm then
            print("activity close err already cover", playerid, actid)
        end
        actclose(player, pacttm, pactdata, actid, ptm)
        ::cont::
    end
end

mgrs.add_mgr(M, "activity", 2)
return M
