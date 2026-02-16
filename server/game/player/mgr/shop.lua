local mgrs = require "server.game.player.mgrs"
local cfgf = require "common.func.cfg"

local M = {}

M.init = function(player)
    player.shop = player.shop or {}
    local pshop = player.shop
    pshop.idx = pshop.idx or 1
    pshop.shops = {}
end

M.create_shop = function(player, shoptid, starttm)
    local pshops = player.shop.shops
    pshops[shoptid] = {
        id = shoptid,
        items = {
            [100] = { num = 100 }
        }
    }
end

M.buy = function(player, shoptid, itemid)
    local shops = player.shop.shops
    local shop = shops[shoptid]
    if not shop then
        return
    end
    local items = shop.items
    local item = items[itemid]
    if not item then
        return
    end
end

mgrs.add_mgr(M, "shop")
return M
