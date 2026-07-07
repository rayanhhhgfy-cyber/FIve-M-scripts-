local QBox = exports['qbx_core']:GetCoreObject()
local activeAlerts = {}
local activeEvacuations = {}
local shelterOccupancy = {}
local alertCounter = 0

local function isAdmin(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    for _, g in ipairs(Config.AdvancedAlerts.adminGroups) do
        if p.PlayerData.group == g then return true end
    end
    return false
end

local function broadcastAlert(alertType, title, message, duration)
    TriggerClientEvent('advancedalerts:receive', -1, alertType, title, message, duration or 30000)
    alertCounter = alertCounter + 1
    MySQL.insert('INSERT INTO emergency_alerts (alert_type, title, message) VALUES (?, ?, ?)', { alertType, title, message })
end

RegisterNetEvent('advancedalerts:send', function(alertType, title, message, duration)
    local src = source
    if not isAdmin(src) then return end
    if not Config.AdvancedAlerts.alertTypes[alertType] then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Invalid alert type' })
        return
    end
    broadcastAlert(alertType, title, message, duration)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Alert sent: ' .. title })
end)

RegisterNetEvent('advancedalerts:evacuate', function(zoneId)
    local src = source
    if not isAdmin(src) then return end
    local zone = nil
    for _, z in ipairs(Config.AdvancedAlerts.evacuationZones) do
        if z.id == zoneId then zone = z; break end
    end
    if not zone then return end
    activeEvacuations[zoneId] = { active = true, started = os.time() }
    broadcastAlert('evacuation', 'Evacuation Order: ' .. zone.name, 'All residents in ' .. zone.name .. ' must evacuate immediately. Proceed to ' .. zone.shelter .. '.', 60000)
    TriggerClientEvent('advancedalerts:evacuationZone', -1, zone)
end)

RegisterNetEvent('advancedalerts:cancelEvacuation', function(zoneId)
    local src = source
    if not isAdmin(src) then return end
    activeEvacuations[zoneId] = nil
    broadcastAlert('shelter', 'All Clear: ' .. zoneId, 'Evacuation order lifted for ' .. zoneId .. '. Return to normal activities.', 30000)
end)

RegisterNetEvent('advancedalerts:enterShelter', function(shelterId)
    local src = source
    if not shelterOccupancy[shelterId] then shelterOccupancy[shelterId] = 0 end
    local shelter = nil
    for _, s in ipairs(Config.AdvancedAlerts.shelters) do
        if s.id == shelterId then shelter = s; break end
    end
    if not shelter then return end
    if shelterOccupancy[shelterId] >= shelter.capacity then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Shelter at capacity' })
        return
    end
    shelterOccupancy[shelterId] = shelterOccupancy[shelterId] + 1
    TriggerClientEvent('advancedalerts:insideShelter', src, shelterId)
    MySQL.insert('INSERT INTO shelter_assignments (shelter_id, citizenid) VALUES (?, ?)', { shelterId, QBox.Functions.GetPlayer(src).PlayerData.citizenid })
end)

RegisterNetEvent('advancedalerts:exitShelter', function(shelterId)
    local src = source
    shelterOccupancy[shelterId] = math.max(0, (shelterOccupancy[shelterId] or 1) - 1)
    TriggerClientEvent('advancedalerts:outsideShelter', src)
end)

--- FEMA coordination
RegisterNetEvent('advancedalerts:femaDeploy', function(resourceType, zoneId)
    local src = source
    if not isAdmin(src) then return end
    local zone = nil
    for _, z in ipairs(Config.AdvancedAlerts.evacuationZones) do
        if z.id == zoneId then zone = z; break end
    end
    if not zone then return end
    broadcastAlert('fema', 'FEMA Deployment', 'FEMA ' .. resourceType .. ' units deployed to ' .. zone.name .. '.', 45000)
end)

--- Weather alert presets
RegisterNetEvent('advancedalerts:weatherWarning', function(eventType)
    local src = source
    if not isAdmin(src) then return end
    local event = Config.AdvancedAlerts.weatherEvents[eventType]
    if not event then return end
    broadcastAlert('weather', eventType:gsub('^%l', string.upper) .. ' Warning', 'A ' .. eventType .. ' has been detected. Seek shelter immediately.', 60000)
    if eventType == 'tornado' then
        TriggerClientEvent('advancedalerts:tornadoWarning', -1, event)
    elseif eventType == 'hurricane' then
        TriggerClientEvent('advancedalerts:hurricaneWarning', -1, event)
    end
end)

--- AMBER alert
RegisterNetEvent('advancedalerts:amberAlert', function(childName, lastSeen, vehicleDesc)
    local src = source
    if not isAdmin(src) then return end
    broadcastAlert('amber', 'AMBER ALERT: ' .. childName, 'Last seen: ' .. lastSeen .. ' | Vehicle: ' .. (vehicleDesc or 'N/A') .. ' | If seen, contact 911 immediately.', 120000)
end)

QBox.Commands.Add('alertweather', 'Send weather alert', {}, false, function(source, args)
    local eventType = args[1] or 'tornado'
    TriggerEvent('advancedalerts:weatherWarning', eventType)
end)

QBox.Commands.Add('alertamber', 'Send AMBER alert', {}, false, function(source, args)
    local childName = args[1] or 'Unknown'
    local lastSeen = table.concat(args, ' ', 2)
    TriggerEvent('advancedalerts:amberAlert', childName, lastSeen)
end)

QBox.Commands.Add('evacuate', 'Order evacuation', {}, false, function(source, args)
    local zoneId = args[1]
    if zoneId then TriggerEvent('advancedalerts:evacuate', zoneId) end
end)

QBox.Commands.Add('femadeploy', 'Deploy FEMA resources', {}, false, function(source, args)
    local resourceType = args[1] or 'supply'
    local zoneId = args[2]
    if zoneId then TriggerEvent('advancedalerts:femaDeploy', resourceType, zoneId) end
end)
