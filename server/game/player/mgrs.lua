local require = require
local table = table
local pairs = pairs
local print = print
local skynet = require "skynet"
local cfg = require "common.func.cfg"
local timerf = require "common.func.timer"
local client = require "server.game.player.client"
local player_mgr = require "server.game.player.player_mgr"
local players = player_mgr.players

local M = {}
player_mgr.mgrs = M
local cfgs = {}
local inits = {}
local mgrs = {}
M.mgrs = mgrs
M.inits = inits

M.reload_cfg = function(cfgname)
    cfg.reload(cfgname, function(mnames)
        for name in pairs(mnames) do
            cfgs[name]()
        end
    end)
end

M.add_mgr = function(mgr, name, initlevel)
    initlevel = initlevel or 1
    if mgrs[name] then
        print("err mgrname repeated", name)
        return
    end
    mgrs[name] = mgr
    if mgr.init then
        table.insert(inits, mgr.init)
    end

    if mgr.cfg then
        cfgs[name] = mgr.cfg
        cfg.cfg_func(name, mgr.cfg)
    end
end

M.init_player = function(player)
    for idx, func in ipairs(inits) do
        func(player)
    end
end

local timerhandle = {}
local timer = timerf(function(id, cmd, ...)
    local player = players[id]
    if not player then
        print("timer no player", id)
        return
    end
    local func = timerhandle[cmd]
    if not func then
        print("timer no handle func", cmd)
        return
    end
    func(player, ...)
end)
M.timer = {
    add = timer.add,
    handle = timerhandle
}

local playerids = {}
local save_kick = function(tm)
    if not next(playerids) then
        for playerid in pairs(players) do
            table.insert(playerids, playerid)
        end
    end

    for i = 1, 5 do
        if not next(playerids) then
            return
        end
        local playerid = table.remove(playerids)
        local player = players[playerid]
        player_mgr.save_player(player)
        if tm > player.gettm + 10 then
            players[playerid] = nil
            timer.del_id(playerid)
            client.kick_player(playerid)
        end
    end
end

skynet.fork(function()
    while true do
        skynet.sleep(100)
        local tm = os.time()
        timer.expire(tm)
        save_kick(tm)
    end
end)

return M
