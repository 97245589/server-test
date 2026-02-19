return function(cmd)
    local f = io.popen(cmd)
    local result = f:read("*a") -- 读取全部输出
    f:close()
    return result
end
