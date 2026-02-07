return function()
    local sproto  = require "sproto"

    local c2s_f   = io.open("config/c2s.sproto")
    local s2c_f   = io.open("config/s2c.sproto")
    local c2s_str = c2s_f:read("*a")
    local s2c_str = s2c_f:read("*a")
    c2s_f:close()
    s2c_f:close()
    local host = sproto.parse(c2s_str):host("package")
    local req = host:attach(sproto.parse(s2c_str))
    return host, req
end
