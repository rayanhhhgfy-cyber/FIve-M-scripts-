local QBox = exports['qbx-core']:GetCoreObject()

RegisterNetEvent('jail:server:cutsceneComplete', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    exports['discord-logs']:LogCustom(src, 'Jail Cutscene', 'Booking completed for ' .. player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname)
end)
