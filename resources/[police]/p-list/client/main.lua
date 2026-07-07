local QBox = exports['qbx-core']:GetCoreObject()
local isOpen = false

RegisterNetEvent('p-list:client:open', function()
    if isOpen then
        SetNuiFocus(false, false)
        isOpen = false
        return
    end
    TriggerServerEvent('p-list:server:requestList')
    SetNuiFocus(true, true)
    isOpen = true
    SendNUIMessage({ action = 'open' })
end)

RegisterNetEvent('p-list:client:receiveList', function(list)
    SendNUIMessage({ action = 'updateList', officers = list or {} })
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    isOpen = false
    cb('ok')
end)

RegisterCommand('+plist', function()
    TriggerEvent('p-list:client:open')
end, false)

RegisterKeyMapping('+plist', 'Open Personnel List', 'keyboard', Config.PList.keybind)
