local io = io

local M = {}

M.private = function()
    local f = io.popen("ip route get 1 | awk '{print $7}'")
    local ip = f:read("*l")
    f:close()
    return ip
end

M.public = function()
    local f = io.popen("curl -s ifconfig.me")
    local ip = f:read("*l")
    f:close()
    return ip
end

return M
