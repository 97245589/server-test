local enums = require "server.game.player.enums"
local print = print

--[[
local __cfgtest = {
    [100] = { event = { enums.task_level, 10 } },
    [200] = { event = { enums.task_hero_levelnum, 3, 5 } },
    [300] = { event = { enums.task_test_add, 10 } }
}
taskmgr.trigger(player, {enums.task_level, 10})
]]

local taskcbs = {}
local handle

local M = {}

M.sethandle = function(v)
    handle = v
end

local count_task = function(player, task, tevent, add_num)
    local change
    local te1 = tevent[1]
    if handle[te1] then
        local bnum = task.num
        task.num = handle[te1](player, tevent, task)
        if bnum ~= task.num then
            change = true
        end
    else
        task.num = task.num + add_num
        if add_num ~= 0 then
            change = true
        end
    end

    local num = tevent[#tevent]
    if task.num >= num then
        task.num = num
        task.status = enums.finish
    end
    return change
end

M.init_task = function(player, task_obj, task_cfg)
    task_obj.marks = task_obj.marks or {}
    task_obj.tasks = task_obj.tasks or {}

    local tasks = task_obj.tasks
    local marks = task_obj.marks
    for taskid, tcfg in pairs(task_cfg) do
        local tevent = tcfg.event
        if tasks[taskid] then
            goto cont
        end
        local task = {
            id = taskid,
            num = 0,
            status = enums.task_unfinish
        }
        count_task(player, task, tevent, 0)
        if task.status == enums.task_unfinish then
            local emark = tevent[1]
            marks[emark] = marks[emark] or {}
            marks[emark][taskid] = 1
        end
        tasks[taskid] = task
        ::cont::
    end
end

M.count_task = function(player, task_obj, task_cfg, eventarr)
    local emark = eventarr[1]
    local marks = task_obj.marks
    local taskids = marks[emark]
    if not taskids or not next(taskids) then
        return
    end

    local changedtask = {}
    local add_num = eventarr[#eventarr]
    local tasks = task_obj.tasks
    for taskid, _ in pairs(taskids) do
        local cfg = task_cfg[taskid]
        if not cfg then
            print("count task error no cfg", taskid)
            goto cont
        end
        local tevent = cfg.event
        local task = tasks[taskid]
        local change = count_task(player, task, tevent, add_num)
        if change then
            changedtask[taskid] = task
        end
        if task.status ~= enums.task_unfinish then
            marks[emark][taskid] = nil
        end
        ::cont::
    end
    if not next(marks[emark]) then
        marks[emark] = nil
    end
    return changedtask
end

M.trigger = function(player, eventarr)
    for name, triggercb in pairs(taskcbs) do
        triggercb(player, eventarr)
    end
end

M.add = function(name, triggercb)
    if type(triggercb) ~= "function" then
        print("tasktriggercb err", name, triggercb)
        return
    end
    if taskcbs[name] then
        print("player taskmgr add err already cover", name)
    end
    taskcbs[name] = triggercb
end

return M
