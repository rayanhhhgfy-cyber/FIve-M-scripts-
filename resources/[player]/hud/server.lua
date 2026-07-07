local QBox = exports['qbx_core']:GetCoreObject()
local ResetStress = false

QBox.Commands.Add('cash', 'Check Cash Balance', {}, false, function(source)
    local Player = QBox.Functions.GetPlayer(source)
    if Player then
        local cash = (Player.PlayerData.money and Player.PlayerData.money.cash) or 0
        TriggerClientEvent('hud:client:ShowAccounts', source, 'cash', cash)
    end
end)

QBox.Commands.Add('bank', 'Check Bank Balance', {}, false, function(source)
    local Player = QBox.Functions.GetPlayer(source)
    if Player then
        local bank = (Player.PlayerData.money and Player.PlayerData.money.bank) or 0
        TriggerClientEvent('hud:client:ShowAccounts', source, 'bank', bank)
    end
end)

QBox.Commands.Add('dev', 'Toggle Developer Mode', {}, false, function(source)
    TriggerClientEvent('qb-admin:client:ToggleDevmode', source)
end, 'admin')

RegisterNetEvent('hud:server:GainStress', function(amount)
    if Config.DisableStress then return end
    local src = source
    local Player = QBox.Functions.GetPlayer(src)
    if not Player then return end
    local Job = Player.PlayerData.job.name
    local JobType = Player.PlayerData.job.type
    if Config.WhitelistedJobs[JobType] or Config.WhitelistedJobs[Job] then return end
    local newStress
    if not ResetStress then
        newStress = (Player.PlayerData.metadata['stress'] or 0) + amount
        if newStress <= 0 then newStress = 0 end
    else
        newStress = 0
    end
    if newStress > 100 then newStress = 100 end
    Player.SetMetaData('stress', newStress)
    TriggerClientEvent('hud:client:UpdateStress', src, newStress)
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Stress increased' })
end)

RegisterNetEvent('hud:server:RelieveStress', function(amount)
    if Config.DisableStress then return end
    local src = source
    local Player = QBox.Functions.GetPlayer(src)
    if not Player then return end
    local newStress
    if not ResetStress then
        newStress = (Player.PlayerData.metadata['stress'] or 0) - amount
        if newStress <= 0 then newStress = 0 end
    else
        newStress = 0
    end
    if newStress > 100 then newStress = 100 end
    Player.SetMetaData('stress', newStress)
    TriggerClientEvent('hud:client:UpdateStress', src, newStress)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Stress relieved' })
end)

lib.callback.register('hud:server:getMenu', function()
    return Config.Menu
end)