local QBox = exports['qbx-core']:GetCoreObject()

RegisterNetEvent('drone:server:deployed', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    exports['discord-logs']:LogCustom(src, 'Drone Deployed', 'Surveillance drone deployed')
end)

RegisterNetEvent('drone:server:stored', function()
    local src = source
end)
