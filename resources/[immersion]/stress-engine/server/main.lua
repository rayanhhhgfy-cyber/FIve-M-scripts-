local QBCore = exports['qbx_core']:GetCoreObject()

lib.callback.register('stress-engine:server:getStress', function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return 0 end
    return player.PlayerData.metadata.stress or 0
end)

RegisterNetEvent('stress-engine:server:addStress', function(amount)
    local source = source
    if not source then return end
    TriggerEvent('player-status:server:addStress', amount)
end)

RegisterNetEvent('stress-engine:server:removeStress', function(amount)
    local source = source
    if not source then return end
    TriggerEvent('player-status:server:removeStress', amount)
end)

RegisterNetEvent('stress-engine:server:relax', function(type)
    local source = source
    if not source then return end
    local relaxConfig = Config.Relaxation[type]
    if not relaxConfig then return end
    local amount = relaxConfig.amountPerInterval or 1.0
    TriggerEvent('player-status:server:removeStress', amount)
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[stress-engine] Stress management engine active.^7')
end)
