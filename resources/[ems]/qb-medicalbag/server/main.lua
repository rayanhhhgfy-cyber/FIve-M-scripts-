local QBCore = exports['qbx_core']:GetCoreObject()
local deployedBags = {}

RegisterNetEvent('qb-medicalbag:server:deployBag', function()
    local source = source
    if not source then return end
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    if Config.MedicalBag.jobRestricted and player.PlayerData.job.name ~= Config.MedicalBag.jobName then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Not authorized' })
        return
    end
    local bagCount = 0
    for _ in pairs(deployedBags) do bagCount = bagCount + 1 end
    if bagCount >= Config.MedicalBag.maxBags then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Max bags deployed' })
        return
    end
    local hasBag = exports['ox_inventory']:Search(source, 'count', Config.MedicalBag.itemName)
    if not hasBag or hasBag < 1 then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'No medical bag' })
        return
    end
    exports['ox_inventory']:RemoveItem(source, Config.MedicalBag.itemName, 1)
    local coords = GetEntityCoords(GetPlayerPed(source))
    local heading = GetEntityHeading(GetPlayerPed(source))
    local bagId = 'medbag_' .. source .. '_' .. GetGameTimer()
    deployedBags[bagId] = { source = source, coords = coords, createdAt = GetGameTimer() }
    TriggerClientEvent('qb-medicalbag:client:spawnBag', -1, coords, heading, bagId)
    SetTimeout(Config.MedicalBag.despawnTime, function()
        if deployedBags[bagId] then
            TriggerClientEvent('qb-medicalbag:client:removeBag', -1, bagId)
            deployedBags[bagId] = nil
        end
    end)
end)

RegisterNetEvent('qb-medicalbag:server:pickupBag', function(bagId)
    local source = source
    if not source or not deployedBags[bagId] then return end
    exports['ox_inventory']:AddItem(source, Config.MedicalBag.itemName, 1)
    TriggerClientEvent('qb-medicalbag:client:removeBag', -1, bagId)
    deployedBags[bagId] = nil
end)

RegisterNetEvent('qb-medicalbag:server:openBag', function(bagId)
    local source = source
    if not source then return end
    TriggerClientEvent('ox_inventory:openInventory', source, 'stash', 'medicalbag_' .. bagId, { slots = Config.MedicalBag.slots, weight = Config.MedicalBag.weight })
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[qb-medicalbag] Medical bag system active.^7')
end)
