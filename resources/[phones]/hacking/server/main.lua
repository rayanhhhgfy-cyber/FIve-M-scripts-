local QBox = exports['qbx-core']:GetCoreObject()

RegisterNetEvent('hacking:server:logAttempt', function(hackType, success)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.insert('INSERT INTO hacking_logs (citizenid, hack_type, success, timestamp) VALUES (?, ?, ?, ?)', { p.PlayerData.citizenid, hackType, success and 1 or 0, os.time() })
    exports['discord-logs']:LogCustom(src, 'Hack Attempt', hackType .. ' | ' .. (success and 'SUCCESS' or 'FAILED'))
end)
