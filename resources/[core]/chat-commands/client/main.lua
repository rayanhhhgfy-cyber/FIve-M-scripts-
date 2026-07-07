RegisterCommand('me', function(source, args)
    local msg = table.concat(args, ' ')
    if msg and msg ~= '' then TriggerServerEvent('chat:server:sendMe', msg) end
end)

RegisterCommand('do', function(source, args)
    local msg = table.concat(args, ' ')
    if msg and msg ~= '' then TriggerServerEvent('chat:server:sendDo', msg) end
end)

RegisterCommand('try', function(source, args)
    local msg = table.concat(args, ' ')
    if msg and msg ~= '' then TriggerServerEvent('chat:server:sendTry', msg) end
end)

RegisterCommand('ooc', function(source, args)
    local msg = table.concat(args, ' ')
    if msg and msg ~= '' then TriggerServerEvent('chat:server:sendOOC', msg) end
end)

RegisterCommand('b', function(source, args)
    local msg = table.concat(args, ' ')
    if msg and msg ~= '' then TriggerServerEvent('chat:server:sendB', msg) end
end)

--- Animation commands
local function clearAnim()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
    DetachEntity(ped, true, false)
end

local sitScenarios = {
    { name = 'Chair', dict = 'anim@heists@flecca_banker@', anim = 'idles', flag = 1, offset = 0.0 },
    { name = 'Ground', dict = 'anim@amb@business@bgen@bgen_no_work_@', anim = 'sit_phone_phonepickup', flag = 1, offset = 0.0 },
    { name = 'Lean Wall', dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@idle_a', anim = 'idle_a', flag = 1, offset = 0.0 },
    { name = 'Bench', dict = 'amb@world_human_seat_bench@male@idle_a', anim = 'idle_a', flag = 1, offset = 0.0 },
    { name = 'Steps', dict = 'amb@world_human_seat_steps@male@idle_a', anim = 'idle_a', flag = 1, offset = 0.0 },
}

RegisterCommand('sit', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        Wrappers.Notify('You are already in a vehicle', 'error')
        return
    end
    if IsPedSittingInAnyVehicle(ped) then return end
    local items = {}
    for i, s in ipairs(sitScenarios) do
        table.insert(items, { title = s.name, onSelect = function()
            clearAnim()
            local dict = s.dict
            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do Citizen.Wait(100) end
            TaskPlayAnim(ped, dict, s.anim, 8.0, -8.0, -1, s.flag, 0, false, false, false)
            RemoveAnimDict(dict)
        end})
    end
    table.insert(items, { title = 'Cancel', icon = 'fas fa-times', onSelect = function() clearAnim() end })
    Wrappers.ContextMenu({ id = 'sit_menu', title = 'Sit Options', menuItems = items })
end)

RegisterCommand('laydown', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        Wrappers.Notify('Cannot lay down in a vehicle', 'error')
        return
    end
    clearAnim()
    local dict = 'amb@world_human_sunbathe@male@back@idle_a'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Citizen.Wait(100) end
    TaskPlayAnim(ped, dict, 'idle_a', 8.0, -8.0, -1, 1, 0, false, false, false)
    Wrappers.Notify('Press X to get up', 'info')
end)

RegisterCommand('wave', function()
    local ped = PlayerPedId()
    clearAnim()
    local dict = 'random@action@drinking@'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Citizen.Wait(100) end
    TaskPlayAnim(ped, dict, 'idle_a', 8.0, -8.0, 3000, 0, 0, false, false, false)
    RemoveAnimDict(dict)
end)
