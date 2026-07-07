local QBCore = exports['qbx_core']:GetCoreObject()
local bodyStorage = {}
local autopsyRecords = {}

lib.callback.register('morgue-extension:server:storeBody', function(source, bodyData)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'Not found' end
    if Config.Morgue.requireCID and player.PlayerData.job.name ~= Config.Morgue.cidJobName then
        return false, 'Not authorized'
    end
    local slot = nil
    for i = 1, Config.Morgue.coldStorageSlots do
        if not bodyStorage[i] then
            slot = i
            break
        end
    end
    if not slot then return false, 'Storage full' end
    bodyStorage[slot] = { data = bodyData, storedBy = player.PlayerData.citizenid, timestamp = os.time() }
    return true, 'Stored in slot ' .. slot
end)

lib.callback.register('morgue-extension:server:getStoredBodies', function(source)
    local results = {}
    for slot, body in pairs(bodyStorage) do
        table.insert(results, { slot = slot, data = body.data, timestamp = body.timestamp })
    end
    return results
end)

lib.callback.register('morgue-extension:server:removeBody', function(source, slot)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    if not bodyStorage[slot] then return false, 'No body in slot' end
    bodyStorage[slot] = nil
    return true
end)

lib.callback.register('morgue-extension:server:performAutopsy', function(source, slot)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'Not found' end
    if Config.Morgue.requireCID and player.PlayerData.job.name ~= Config.Morgue.cidJobName then
        return false, 'Not authorized'
    end
    local body = bodyStorage[slot]
    if not body then return false, 'No body in slot' end
    local results = {
        cause_of_death = 'Gunshot wounds',
        time_of_death = os.date('%Y-%m-%d %H:%M:%S', body.timestamp),
        weapon_type = 'Firearm',
        bullet_caliber = '9mm',
        toxicology = 'Clean',
        dna_evidence = 'Collected for analysis',
        fingerprint_evidence = 'Lifted from remains'
    }
    local recordId = 'AUTO-' .. string.format('%06d', math.random(999999))
    autopsyRecords[recordId] = { slot = slot, results = results, performedBy = player.PlayerData.citizenid, timestamp = os.time() }
    return results, recordId
end)

lib.callback.register('morgue-extension:server:getEvidence', function(source)
    return exports['ox_inventory']:GetStashItems('morgue_evidence')
end)

RegisterNetEvent('morgue-extension:server:storeEvidence', function(itemName, count)
    local source = source
    if not source then return end
    TriggerClientEvent('ox_inventory:openInventory', source, 'stash', 'morgue_evidence', { slots = 40, weight = 50000 })
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[morgue-extension] Morgue system active. %d storage slots, %d autopsy tables.^7',
        Config.Morgue.coldStorageSlots, Config.Morgue.autopsyTableCount)
end)

exports('GetStoredBodies', function() return bodyStorage end)
exports('GetAutopsyRecords', function() return autopsyRecords end)
