local require = require
local mgrs = require "server.game.player.mgr.mgrs"
local cfg = require "common.func.cfg"

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
end

local itemuse_enums = {
    gold = 1,
}

local use_handle = {
    [itemuse_enums.gold] = function(player, num)
        local item = player.item
        local add = cfg.params[1]
        item.gold = item.gold + add * num
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
