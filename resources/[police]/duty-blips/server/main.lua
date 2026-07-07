local QBox = exports['qbx-core']:GetCoreObject()

CreateThread(function()
    while true do
        Wait(Config.DutyBlips.updateInterval)
        local players = QBox.Functions.GetPlayers()
        local dutyData = {}
        for _, src in ipairs(players) do
            local player = QBox.Functions.GetPlayer(src)
            if player and player.PlayerData.job and player.PlayerData.job.type == 'leo' and player.PlayerData.job.onduty then
                local ped = GetPlayerPed(src)
                local coords = GetEntityCoords(ped)
                local name = (player.PlayerData.charinfo.firstname or '') .. ' ' .. (player.PlayerData.charinfo.lastname or '')
                dutyData[src] = {
                    name = name,
                    job = player.PlayerData.job.name,
                    coords = { x = coords.x, y = coords.y, z = coords.z },
                    onduty = true,
                }
            end
        end
        for _, src in ipairs(players) do
            local player = QBox.Functions.GetPlayer(src)
            if player and player.PlayerData.job and player.PlayerData.job.type == 'leo' then
                TriggerClientEvent('duty-blips:client:update', src, dutyData)
            end
        end
    end
end)
