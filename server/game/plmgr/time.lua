-- duration = {day=0,min=0,sec=0}
-- time = {year=0,month=0,day=0,hour=0,min=0,sec=0} duration={day=3} next={day=7}
-- server_start = {day=3}
-- server_startweek = {1, 3}
-- everyweek = {2, 6}, start={hour=10},after_startday={day=5},duration={day=1}
local os, table, ipairs = os, table, ipairs
local time_min = 60
local time_hour = 60 * time_min
local time_day = time_hour * 24
local time_week = time_day * 7

local server_start_ts

local M = {}

M.set_server_start_ts = function(ts)
    server_start_ts = ts
end

M.day_start = function(ts)
    local tb = os.date("*t", ts)
    tb.hour, tb.min, tb.sec = 0, 0, 0
    tb.isdst = nil
    return os.time(tb)
end

M.week_start = function(ts)
    local tb = os.date("*t", ts)
    tb.hour, tb.min, tb.sec = 0, 0, 0
    local weekday = tb.wday - 1
    if 0 == weekday then
        weekday = 7
    end
    tb.day = tb.day - (weekday - 1)
    tb.isdst = nil
    return os.time(tb)
end

M.add_duration = function(ts, dtb)
    local tb = os.date("*t", ts)
    tb.day = tb.day + (dtb.day or 0)
    tb.hour = tb.hour + (dtb.hour or 0)
    tb.min = tb.min + (dtb.min or 0)
    tb.sec = tb.sec + (dtb.sec or 0)
    tb.isdst = nil
    return os.time(tb)
end

local get_start_end = function(cfg, startts, nowts)
    if not cfg.duration then
        return startts
    end

    local endts = M.add_duration(startts, cfg.duration)
    if nowts < startts then
        return startts, endts
    elseif nowts >= startts and nowts < endts then
        return startts, endts
    end

    if not cfg.next then
        return
    end

    while true do
        local next_start = M.add_duration(endts, cfg.next)
        local next_end = M.add_duration(next_start, cfg.duration)
        if nowts < next_start then
            return next_start, next_end
        elseif nowts >= next_start and nowts < endts then
            return next_start, next_end
        end
        endts = next_end
    end
end

local parse_tm = function(cfg, ts)
    local tm_tb = cfg.time
    tm_tb.hour = tm_tb.hour or 0

    local startts = os.time(tm_tb)
    return get_start_end(cfg, startts, ts)
end

local parse_server_start = function(cfg, ts)
    local startts = M.add_duration(server_start_ts, cfg.server_start)
    return get_start_end(cfg, startts, ts)
end

local parse_server_startweek = function(cfg, nowts)
    if not cfg.duration then
        return
    end
    local cserver_startweek = cfg.server_startweek
    local serverweekstart = M.week_start(server_start_ts)
    local cweek_th = cserver_startweek[1]
    local cweekday = cserver_startweek[2]

    local startts = M.add_duration(serverweekstart, {
        day = (cweek_th - 1) * 7 + (cweekday - 1)
    })
    if startts < server_start_ts then
        startts = M.add_duration(startts, {
            day = 7
        })
    end
    return get_start_end(cfg, startts, nowts)
end

local parse_every_week = function(cfg, nowts)
    if not cfg.duration then
        return
    end

    cfg.start = cfg.start or {}
    local cstart = cfg.start
    local tm_tb = os.date("*t", nowts)
    tm_tb.hour = cstart.hour or 0
    tm_tb.min = cstart.min or 0
    tm_tb.sec = cstart.sec or 0
    local todayts = os.time(tm_tb)

    local weekday = tm_tb.wday - 1
    if 0 == weekday then
        weekday = 7
    end

    local efftm = 0
    if cfg.after_startday then
        efftm = M.add_duration(server_start_ts, cfg.after_startday)
    end

    local arr = {}
    for _, cweekday in ipairs(cfg.everyweek) do
        local startts = M.add_duration(todayts, {
            day = cweekday - weekday
        })
        table.insert(arr, startts)
    end

    local lastweekstartts = M.add_duration(arr[#arr], {
        day = -7
    })
    local lastweekendts = M.add_duration(lastweekstartts, cfg.duration)
    if lastweekstartts >= efftm and nowts >= lastweekstartts and nowts < lastweekendts then
        return lastweekstartts, lastweekendts
    end

    while true do
        for i, ts in ipairs(arr) do
            local startts = ts
            local endts = M.add_duration(startts, cfg.duration)

            if startts < efftm then
                goto cont
            end
            if nowts < startts then
                return startts, endts
            elseif nowts >= startts and nowts < endts then
                return startts, endts
            end
            ::cont::
            arr[i] = M.add_duration(arr[i], {
                day = 7
            })
        end
    end
end

--[[
    get start end timestamp
]]
M.start_end = function(cfg, nowts)
    nowts = nowts or os.time()
    if cfg.time then
        return parse_tm(cfg, nowts)
    end
    if cfg.server_start then
        return parse_server_start(cfg, nowts)
    end
    if cfg.server_startweek then
        return parse_server_startweek(cfg, nowts)
    end
    if cfg.everyweek then
        return parse_every_week(cfg, nowts)
    end
end

M.start_end_by_lastend = function(cfg, endts, nowts)
    nowts = nowts or os.time()
    if cfg.everyweek then
        return parse_every_week(cfg, nowts)
    end
    if not cfg.duration or not cfg.next then
        return
    end
    while true do
        local startts = M.add_duration(endts, cfg.next)
        endts = M.add_duration(startts, cfg.duration)
        if nowts < startts then
            return startts, endts
        end
        if nowts >= startts and nowts < endts then
            return startts, endts
        end
    end
end

M.format = function(ts)
    return os.date("%Y-%m-%d %H:%M:%S", ts)
end

return M
