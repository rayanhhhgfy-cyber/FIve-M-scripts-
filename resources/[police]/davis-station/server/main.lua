local QBox = exports['qbx-core']:GetCoreObject()
local evidenceItems = {}
local cellOccupants = {}
local RATE_LIMITS = {}

local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    RATE_LIMITS[key] = RATE_LIMITS[key] or {}
    table.insert(RATE_LIMITS[key], now)
    for i = #RATE_LIMITS[key], 1, -1 do
        if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
    end
    return #RATE_LIMITS[key] <= maxPerMin
end

RegisterNetEvent('davis:server:toggleDuty', function()
    local src = source
    if not checkRateLimit(src, 'davisToggleDuty', 10) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local job = player.PlayerData.job
    if job.type ~= 'leo' then return end
    local newDuty = not job.onduty
    player.Functions.SetJobDuty(newDuty)
    Wrappers.Notify(src, newDuty and Locale('police.now_on_duty') or Locale('police.now_off_duty'), 'success')
end)

RegisterNetEvent('davis:server:removeWeapon', function(weaponModel)
    local src = source
    if not checkRateLimit(src, 'davisRemoveWeapon', 20) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then return end
    local rank = player.PlayerData.job.grade.level or 0
    for _, weapon in ipairs(Config.DavisStation.Zones.Armory.weapons) do
        if weapon.model == weaponModel and rank >= weapon.rank then
            local serial = exports['resources']:GenerateSerial()
            MySQL.insert('INSERT INTO weapon_serials (citizenid, serial, weapon_model, issued_by) VALUES (?, ?, ?, ?)',
                { player.PlayerData.citizenid, serial, weaponModel, player.PlayerData.citizenid })
            player.Functions.AddItem(weaponModel, 1, nil, serial)
            Wrappers.Notify(src, Locale('police.weapon_issued', weapon.label), 'success')
            return
        end
    end
    Wrappers.Notify(src, Locale('police.weapon_unavailable'), 'error')
end)

RegisterNetEvent('davis:server:storeEvidence', function(label, description)
    local src = source
    if not checkRateLimit(src, 'davisStoreEvidence', 30) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then return end
    local id = #evidenceItems + 1
    evidenceItems[id] = { id = id, label = label, description = description or '', storedBy = player.PlayerData.citizenid, timestamp = os.time() }
    MySQL.insert('INSERT INTO evidence_items (citizenid, label, description, stored_by, timestamp) VALUES (?, ?, ?, ?, ?)',
        { player.PlayerData.citizenid, label, description or '', player.PlayerData.citizenid, os.time() })
    Wrappers.Notify(src, Locale('police.evidence_stored'), 'success')
end)

RegisterNetEvent('davis:server:retrieveEvidence', function(id)
    local src = source
    if not checkRateLimit(src, 'davisRetrieveEvidence', 20) then return end
    if evidenceItems[id] then
        local item = evidenceItems[id]
        Wrappers.Notify(src, Locale('police.evidence_retrieved', item.label), 'success')
        table.remove(evidenceItems, id)
    end
end)

QBox.Functions.CreateCallback('davis:server:getEvidenceItems', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player or not player.PlayerData.job.onduty then cb({}) return end
    cb(evidenceItems)
end)

RegisterNetEvent('davis:server:getCellStatus', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local statusText = Locale('police.cell_status_header')
    for i = 1, Config.DavisStation.Zones.Cells.cellCount do
        local occupant = cellOccupants[i]
        if occupant then
            statusText = statusText .. '\n' .. Locale('police.cell_occupied', i, occupant.name, occupant.time .. 'm')
        else
            statusText = statusText .. '\n' .. Locale('police.cell_empty', i)
        end
    end
    Wrappers.Notify(src, statusText, 'info')
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        for i, occupant in pairs(cellOccupants) do
            occupant.time = occupant.time - 1
            if occupant.time <= 0 then
                local target = QBox.Functions.GetPlayerByCitizenId(occupant.citizenid)
                if target then
                    TriggerClientEvent('police:client:releasePrisoner', target.PlayerData.source)
                end
                cellOccupants[i] = nil
            end
        end
    end
end)
