local QBCore = exports['qbx_core']:GetCoreObject()
local activeRadios = {}

RegisterNetEvent('rcore-radiocar:server:startRadio', function(netId, url, volume)
    local source = source
    if not source then return end
    if Config.RadioCar.requireItem then
        local hasItem = exports['ox_inventory']:Search(source, 'count', Config.RadioCar.radioItem)
        if not hasItem or hasItem < 1 then
            TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'No car radio item' })
            return
        end
    end
    activeRadios[netId] = { source = source, url = url, volume = volume or Config.RadioCar.defaultVolume }
    TriggerClientEvent('rcore-radiocar:client:startRadio', -1, netId, url, volume)
end)

RegisterNetEvent('rcore-radiocar:server:stopRadio', function(netId)
    local source = source
    if not source then return end
    activeRadios[netId] = nil
    TriggerClientEvent('rcore-radiocar:client:stopRadio', -1, netId)
end)

RegisterNetEvent('rcore-radiocar:server:setVolume', function(netId, volume)
    activeRadios[netId] = activeRadios[netId] or {}
    activeRadios[netId].volume = volume
    TriggerClientEvent('rcore-radiocar:client:setVolume', -1, netId, volume)
end)

RegisterNetEvent('rcore-radiocar:server:setUrl', function(netId, url)
    local source = source
    if not source then return end
    activeRadios[netId] = activeRadios[netId] or {}
    activeRadios[netId].url = url
    TriggerClientEvent('rcore-radiocar:client:setUrl', -1, netId, url)
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[rcore-radiocar] Vehicle radio system active.^7')
end)

exports('GetActiveRadio', function(netId) return activeRadios[netId] end)
