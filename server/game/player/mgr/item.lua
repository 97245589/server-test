local mgrs = require "server.game.player.mgrs"
local cfg = require "common.func.cfg"
local enums = require "server.game.player.enums"

local timer = mgrs.timer
timer.handle[enums.timer_item] = function(player, itemid)
end
local add_timer = function(player, tm, itemid)
    timer.add(player.id, tm, enums.timer_item, itemid)
end

local M = {}

M.init = function(player)
    player.item = player.item or {}
    local item = player.item
    item.items = item.items or {}
    item.gold = item.gold or 0
end

M.get_item = function(player, itemid)
    local items = player.item.items
    local item = items[itemid]
    return item and item.num or 0
end

M.add_item = function(player, itemid, num)
    local items = player.item.items
    items[itemid] = items[itemid] or {
        id = itemid,
        num = 0
    }
    local item = items[itemid]
    item.num = item.num + num
end

M.add_gold = function(player, num)
    local item = player.item
    item.gold = item.gold + num
    player.dirtys.item = 1
end


local use_handle = {
    [enums.itemuse_gold] = function(player, num, icfg)
        local add = icfg.params[1]
        M.add_gold(player, add * num)
    end
}
M.use_item = function(player, itemid, num)
    num = num or 1
    local item = player.item.items[itemid]
    if not item or num > item.num then
        return -1
    end

    local itemcfg = cfg.get("item")
    item.num = item.num - num
    local icfg = itemcfg[itemid]
    local usetype = icfg.usetype
    if not usetype then
        return -1
    end
    use_handle[usetype](player, num, icfg)
end

mgrs.add_mgr(M, "item")
return M
