local dbactdata

local impl = {}

impl[100] = {}
impl[100].open = function(act)
    -- print("impl activity", dump(act))
    if not dbactdata[act.id] then
        dbactdata[act.id] = {}
    end
    local aimpl = dbactdata[act.id]
end
impl[100].close = function(act)
end

return {
    impl = impl,
    setdb = function(val)
        dbactdata = val
    end
}
