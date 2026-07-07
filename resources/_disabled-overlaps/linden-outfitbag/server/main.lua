local QBCore = exports['qbx_core']:GetCoreObject()

RegisterNetEvent('linden-outfitbag:server:placeBag', function()
    local source = source
    if not source then return end
    local hasBag = exports['ox_inventory']:Search(source, 'count', Config.OutfitBag.itemName)
    if not hasBag or hasBag < 1 then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'No outfit bag' })
        return
    end
    exports['ox_inventory']:RemoveItem(source, Config.OutfitBag.itemName, 1)
    TriggerClientEvent('linden-outfitbag:client:spawnBag', source)
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[linden-outfitbag] Outfit bag system active.^7')
end)
