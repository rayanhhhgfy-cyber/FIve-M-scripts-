local QBCore = exports['qbx_core']:GetCoreObject()
local activeBoomboxes = {}

RegisterNetEvent('wasabi-boombox:server:placeBoombox', function(url, volume)
    local source = source
    if not source then return end
    local hasItem = exports['ox_inventory']:Search(source, 'count', Config.Boombox.itemName)
    if not hasItem or hasItem < 1 then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'No boombox' })
        return
    end
    exports['ox_inventory']:RemoveItem(source, Config.Boombox.itemName, 1)
    local coords = GetEntityCoords(GetPlayerPed(source))
    TriggerClientEvent('wasabi-boombox:client:spawnBoombox', -1, coords, url, volume)
end)

RegisterNetEvent('wasabi-boombox:server:removeBoombox', function(boomboxId)
    local source = source
    if not source then return end
    exports['ox_inventory']:AddItem(source, Config.Boombox.itemName, 1)
    TriggerClientEvent('wasabi-boombox:client:removeBoombox', -1, boomboxId)
    activeBoomboxes[boomboxId] = nil
end)

RegisterNetEvent('wasabi-boombox:server:registerBoombox', function(boomboxId, coords)
    local source = source
    if not source then return end
    activeBoomboxes[boomboxId] = { source = source, coords = coords, createdAt = GetGameTimer() }
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[wasabi-boombox] Boombox system active.^7')
end)

exports('GetActiveBoomboxes', function() return activeBoomboxes end)
