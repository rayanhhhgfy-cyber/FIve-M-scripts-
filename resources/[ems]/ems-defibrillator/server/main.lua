local QBCore = exports['qbx_core']:GetCoreObject()

lib.callback.register('ems-defibrillator:server:useDefibrillator', function(source, target)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'No player' end
    if Config.Defibrillator.requireMedicJob and player.PlayerData.job.name ~= Config.Defibrillator.medicJobName then
        return false, 'Not authorized'
    end
    local hasItem = exports['ox_inventory']:Search(source, 'count', Config.Defibrillator.itemName)
    if not hasItem or hasItem < 1 then
        return false, 'No defibrillator'
    end
    local downState = exports['wasabi-ambulance']:GetDownState(target)
    if not downState then
        return false, 'Player is not down'
    end
    local success = exports['wasabi-ambulance']:RevivePlayer(target, 'defibrillator')
    if success then
        exports['ox_inventory']:RemoveItem(source, Config.Defibrillator.itemName, 1)
        return true, 'Revived!'
    else
        return false, 'Defibrillation failed'
    end
end)

lib.callback.register('ems-defibrillator:server:useCPR', function(source, target)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'No player' end
    local downState = exports['wasabi-ambulance']:GetDownState(target)
    if not downState then
        return false, 'Player is not down'
    end
    local success = exports['wasabi-ambulance']:RevivePlayer(target, 'cpr')
    return success, success and 'CPR successful!' or 'CPR failed'
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[ems-defibrillator] Defibrillator & CPR system active.^7')
end)
