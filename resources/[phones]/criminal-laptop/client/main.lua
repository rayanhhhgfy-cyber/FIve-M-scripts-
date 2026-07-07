local QBox = exports['qbx-core']:GetCoreObject()
local laptopOpen = false
local batteryLevel = Config.CriminalLaptop.BatteryMax

local function hasLaptop() return QBox.Functions.HasItem(Config.CriminalLaptop.ItemName) end

RegisterCommand('+laptop', function()
    if not hasLaptop() then Wrappers.Notify(Locale('phone.no_laptop'), 'error') return end
    if batteryLevel <= 0 then Wrappers.Notify(Locale('phone.battery_dead'), 'error') return end
    laptopOpen = not laptopOpen
    if laptopOpen then
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'openLaptop', config = Config.CriminalLaptop })
    else
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeLaptop' })
    end
end, false)
RegisterKeyMapping('+laptop', 'Toggle Criminal Laptop', 'keyboard', 'f3')

RegisterNUICallback('closeLaptop', function(_, cb)
    laptopOpen = false; SetNuiFocus(false, false); cb('ok')
end)

RegisterNUICallback('darkWebBrowse', function(data, cb)
    if data and data.category then
        TriggerServerEvent('criminal:server:browse', data.category)
    end
    cb('ok')
end)

RegisterNUICallback('purchaseItem', function(data, cb)
    if data and data.id then
        TriggerServerEvent('criminal:server:purchase', data.id)
    end
    cb('ok')
end)

RegisterNUICallback('sendEncrypted', function(data, cb)
    if data and data.message then TriggerServerEvent('criminal:server:encryptedMessage', data.message) end
    cb('ok')
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        if hasLaptop() then
            batteryLevel = math.max(0, batteryLevel - Config.CriminalLaptop.BatteryDrain)
            if batteryLevel <= 0 and laptopOpen then
                SetNuiFocus(false, false)
                SendNUIMessage({ action = 'closeLaptop' })
                Wrappers.Notify(Locale('phone.laptop_battery_dead'), 'error')
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if GetCurrentResourceName() == r and laptopOpen then SetNuiFocus(false, false) end
end)
