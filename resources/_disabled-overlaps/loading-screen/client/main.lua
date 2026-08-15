CreateThread(function()
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    SetNuiFocus(false, false)
end)

RegisterNetEvent('loading-screen:client:show', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'show' })
end)

RegisterNetEvent('loading-screen:client:hide', function()
    SendNUIMessage({ action = 'hide' })
    SetNuiFocus(false, false)
end)

RegisterNUICallback('loadingComplete', function(_, cb)
    SetNuiFocus(false, false)
    cb({ status = 'ok' })
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    TriggerEvent('loading-screen:client:show')
end)
