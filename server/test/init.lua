local skynet = require "skynet"

skynet.start(function()
    local test = skynet.getenv("test")
    if not test or #test == 0 then
        test = "test"
    end
    skynet.newservice("server/test/" .. test)
    skynet.exit()
end)
