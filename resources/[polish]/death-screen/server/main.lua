local QBox = exports['qbx-core']:GetCoreObject()

RegisterNetEvent('death:respawn', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local cash = player.PlayerData.money.cash
    local cost = Config.Death.respawnPrice
    if cash < cost then
        Wrappers.Notify(src, 'Not enough cash — you need $' .. cost, 'error')
        return
    end
    player.Functions.RemoveMoney('cash', cost, 'respawn')
    local hospital = Config.Death.hospitals[math.random(#Config.Death.hospitals)]
    TriggerClientEvent('death:doRespawn', src, hospital)
end)

RegisterNetEvent('death:callEMS', function()
    local src = source
    local players = QBox.Functions.GetPlayers()
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    for _, p in ipairs(players) do
        local pPlayer = QBox.Functions.GetPlayer(p)
        if pPlayer and pPlayer.PlayerData.job.name == 'ems' then
            TriggerClientEvent('death:emsAlert', p, src, coords)
        end
    end
    Wrappers.Notify(src, 'EMS has been notified.', 'success')
end)
