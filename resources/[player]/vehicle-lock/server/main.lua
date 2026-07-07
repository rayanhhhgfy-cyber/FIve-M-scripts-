local QBox = exports['qbx-core']:GetCoreObject()

--- Check if vehicle belongs to player
QBox.Functions.CreateCallback('vehiclelock:server:checkOwnership', function(source, cb, plate)
    local player = QBox.Functions.GetPlayer(source)
    if not player then cb(false) return end

    local cleanPlate = string.upper(plate:gsub('%s+', ''))
    if not cleanPlate or cleanPlate == '' then cb(false) return end

    MySQL.query('SELECT id FROM player_vehicles WHERE plate = ? AND citizenid = ?', { cleanPlate, player.PlayerData.citizenid }, function(rows)
        cb(rows and #rows > 0)
    end)
end)
