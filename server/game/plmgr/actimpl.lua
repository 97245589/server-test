local dbactdata

local impl = {}

impl[100] = {}
impl[100].open = function(act)
    -- print("impl activity", dump(act))
    local actid = act.id
    dbactdata[actid] = dbactdata[actid] or {}
    local data = dbactdata[actid]
end
impl[100].close = function(act)
    dbactdata[act.id] = nil
end

return {
    impl = impl,
    setdb = function(val)
        dbactdata = val
    end
}
