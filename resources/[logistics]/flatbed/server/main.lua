local QBox = exports['qbx-core']:GetCoreObject()

RegisterNetEvent('flatbed:server:loaded', function(plate)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.insert('INSERT INTO flatbed_logs (citizenid, plate, action, timestamp) VALUES (?, ?, ?, ?)', { p.PlayerData.citizenid, plate, 'loaded', os.time() })
end)

RegisterNetEvent('flatbed:server:unloaded', function(plate)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.insert('INSERT INTO flatbed_logs (citizenid, plate, action, timestamp) VALUES (?, ?, ?, ?)', { p.PlayerData.citizenid, plate, 'unloaded', os.time() })
end)
