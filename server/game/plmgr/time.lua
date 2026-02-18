--[[
duration = {day,min,sec}
=====
time = {year,month,day,hour,min,sec}, duration={day=3}
afterstart = {day=3, hour=10}, duration={day=3}
week = {startweek=1,weekday=3,hour=10}, duration = {}
everyweek = {startweek=1,weekday=3,hour=10},duration={}
]]
local os = os

local startts

local M = {}

M.format = function(ts)
    return os.date("%Y-%m-%d %H:%M:%S", ts)
end

M.set_startts = function(ts)
    startts = ts
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

M.last_weekstart = function(ts)
    local tb = os.date("*t", ts)
    tb.hour, tb.min, tb.sec = 0, 0, 0
    local weekday = tb.wday - 1
    if 0 == weekday then
        weekday = 7
    end
    tb.day = tb.day - (weekday - 1) - 7
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

local parse_time = function(cinfo)
    local tmtb = cinfo.time
    tmtb.hour = tmtb.hour or 0
    tmtb.min = tmtb.min or 0
    tmtb.sec = tmtb.sec or 0
    local stm = os.time(tmtb)
    local etm = M.add_duration(stm, cinfo.duration)
    if os.time() < etm then
        return stm, etm
    end
end

local parse_afterstart = function(cinfo)
    local stm = M.add_duration(startts, cinfo.afterstart)
    local etm = M.add_duration(stm, cinfo.duration)
    if os.time() < etm then
        return stm, etm
    end
end

local parse_week = function(cinfo)
    local cweek = cinfo.week
    local sweekstart = M.week_start(startts)
    local fstm = M.add_duration(sweekstart, {
        day = cweek.weekday - 1,
        hour = cweek.hour,
        min = cweek.min,
        sec = cweek.sec
    })
    if fstm < startts then
        fstm = M.add_duration(fstm, { day = 7 })
    end
    fstm = M.add_duration(fstm, {
        day = (cweek.startweek - 1) * 7
    })
    local fetm = M.add_duration(fstm, cinfo.duration)
    if os.time() < fetm then
        return fstm, fetm
    end
end

local parse_everyweek = function(cinfo)
    local nowts = os.time()
    local cweek = cinfo.everyweek
    local lastweekstart = M.last_weekstart()
    local stm = M.add_duration(lastweekstart, {
        day  = cweek.weekday - 1,
        hour = cweek.hour,
        min  = cweek.min,
        sec  = cweek.sec
    })
    local etm = M.add_duration(stm, cinfo.duration)

    for i = 1, 5 do
        if nowts < etm then
            break
        end
        stm = M.add_duration(stm, {
            day = 7
        })
        etm = M.add_duration(etm, {
            day = 7
        })
    end

    if not cweek.startweek then
        return stm, etm
    else
        local sweekstart = M.week_start(startts)
        local fstm = M.add_duration(sweekstart, {
            day = cweek.weekday - 1,
            hour = cweek.hour,
            min = cweek.min,
            sec = cweek.sec
        })
        if fstm < startts then
            fstm = M.add_duration(fstm, { day = 7 })
        end
        fstm = M.add_duration(fstm, {
            day = (cweek.startweek - 1) * 7
        })
        local fetm = M.add_duration(fstm, cinfo.duration)
        if stm >= fstm then
            return stm, etm
        else
            return fstm, fetm
        end
    end
end

local parse = function(cinfo)
    if cinfo.time then
        return parse_time(cinfo)
    elseif cinfo.afterstart then
        return parse_afterstart(cinfo)
    elseif cinfo.week then
        return parse_week(cinfo)
    elseif cinfo.everyweek then
        return parse_everyweek(cinfo)
    else
        print("time parse type err")
        return
    end
end

M.startendtm = function(ctime)
    if #ctime == 0 then
        ctime = { ctime }
    end

    local arr = {}
    for i = 1, #ctime do
        local cinfo = ctime[i]
        if not cinfo.duration then
            print("parse time err no duration")
            return
        end
        local stm, etm = parse(cinfo)
        if stm then
            table.insert(arr, stm)
            table.insert(arr, etm)
        end
    end

    local minstm = math.maxinteger
    local stm, etm
    for i = 1, #arr, 2 do
        local astm = arr[i]
        local aetm = arr[i + 1]
        if astm < minstm then
            minstm = astm
            stm = astm
            etm = aetm
        end
    end
    return stm, etm
end

return M
