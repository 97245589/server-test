local impl = {}

impl[100] = {}
impl[100].open = function(player, actdata)
    -- print("player actdata open", 100)
    actdata[100] = actdata[100] or {}
end
impl[100].close = function(player, actdata)
    actdata[100] = nil
end

return impl
