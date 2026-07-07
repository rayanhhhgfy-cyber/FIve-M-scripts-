local QBox = exports['qbx-core']:GetCoreObject()
local mdtOpen = false

local function canUseMDT()
    local job = QBox.Functions.GetPlayerData().job
    if not job then return false end
    for _, j in ipairs(Config.MDT.allowedJobs) do
        if job.name == j and job.onduty then return true end
    end
    return false
end

RegisterCommand('+mdt', function()
    if not canUseMDT() then Wrappers.Notify('Not authorized', 'error') return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then Wrappers.Notify('Must be in a vehicle', 'error') return end
    mdtOpen = not mdtOpen
    if mdtOpen then
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'openMDT' })
    else
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeMDT' })
    end
end, false)
RegisterKeyMapping('+mdt', 'Toggle MDT', 'keyboard', 'f5')

RegisterNUICallback('closeMDT', function(_, cb)
    mdtOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('plateSearch', function(data, cb)
    if not data or not data.plate then cb({}) return end
    QBox.Functions.TriggerCallback('mdt:plateSearch', function(result)
        cb(result or { error = 'No results' })
    end, data.plate)
end)

RegisterNUICallback('warrantSearch', function(data, cb)
    if not data or not data.name then cb({}) return end
    QBox.Functions.TriggerCallback('mdt:warrantSearch', function(result)
        cb(result or { error = 'No results' })
    end, data.name)
end)

RegisterNUICallback('submitReport', function(data, cb)
    if data then
        TriggerServerEvent('mdt:submitReport', data)
    end
    cb('ok')
end)
