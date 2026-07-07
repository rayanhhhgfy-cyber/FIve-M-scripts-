local QBox = exports['qbx-core']:GetCoreObject()

--- Open target player's inventory for search
RegisterNetEvent('personsearch:server:openInventory', function(targetSrc)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    TriggerClientEvent('ox_inventory:openInventory', src, 'otherplayer', targetSrc)
end)

--- Impound vehicle
RegisterNetEvent('personsearch:server:impoundVehicle', function(plate, reason, fee, vehicleProps)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local cleanPlate = string.upper(plate:gsub('%s+', ''))
    local citizenid = nil
    local ownerName = 'Unknown'

    local owners = MySQL.query.await('SELECT citizenid, charinfo FROM players WHERE JSON_EXTRACT(charinfo, "$.firstname") IS NOT NULL LIMIT 0')
    local vehicles = MySQL.query.await('SELECT citizenid FROM player_vehicles WHERE plate = ?', { cleanPlate })
    if vehicles and #vehicles > 0 then
        citizenid = vehicles[1].citizenid
        local ownerData = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', { citizenid })
        if ownerData and #ownerData > 0 then
            local ci = json.decode(ownerData[1].charinfo) or {}
            ownerName = (ci.firstname or '') .. ' ' .. (ci.lastname or '')
        end
    end

    local impoundTime = os.time()
    MySQL.insert('INSERT INTO impounded_vehicles (vehicle_plate, citizenid, impound_time, fee, reason) VALUES (?, ?, ?, ?, ?)', {
        cleanPlate, citizenid or 'unknown', impoundTime, fee, reason
    })

    if vehicleProps then
        for _, vehicle in ipairs(GetAllVehicles()) do
            if GetVehicleNumberPlateText(vehicle) == vehicleProps.plate then
                DeleteEntity(vehicle)
                break
            end
        end
    end

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Vehicle ' .. cleanPlate .. ' impounded - $' .. fee .. ' fee' })
end)

--- Vehicle DMV search (kept for Search Vehicle)
QBox.Functions.CreateCallback('personsearch:server:searchVehicle', function(source, cb, plate)
    local player = QBox.Functions.GetPlayer(source)
    if not player then cb(nil) return end

    local cleanPlate = string.upper(plate:gsub('%s+', ''))
    MySQL.query('SELECT * FROM player_vehicles WHERE plate = ?', { cleanPlate }, function(vehicles)
        if not vehicles or #vehicles == 0 then
            cb({
                plate = cleanPlate,
                model = 'Unknown',
                color = 'Unknown',
                ownerName = 'Unknown',
                ownerPhone = 'N/A',
                stolen = false,
                bolo = false,
            })
            return
        end

        local v = vehicles[1]
        local ownerName = 'Unknown'
        local ownerPhone = 'N/A'

        if v.citizenid then
            MySQL.query('SELECT * FROM players WHERE citizenid = ?', { v.citizenid }, function(owners)
                if owners and #owners > 0 then
                    local charinfo = json.decode(owners[1].charinfo) or {}
                    ownerName = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')
                    ownerPhone = charinfo.phone or 'N/A'
                end
                cb({
                    plate = cleanPlate,
                    model = v.vehicle or 'Unknown',
                    color = v.color or 'Unknown',
                    ownerName = ownerName,
                    ownerPhone = ownerPhone,
                    stolen = v.stolen or false,
                    bolo = v.bolo or false,
                })
            end)
        else
            cb({
                plate = cleanPlate,
                model = v.vehicle or 'Unknown',
                color = v.color or 'Unknown',
                ownerName = ownerName,
                ownerPhone = ownerPhone,
                stolen = v.stolen or false,
                bolo = v.bolo or false,
            })
        end
    end)
end)
