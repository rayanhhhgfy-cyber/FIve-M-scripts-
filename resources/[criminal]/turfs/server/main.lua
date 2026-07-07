local QBox = exports['qbx-core']:GetCoreObject()
local activeCaptures = {}
local turfOwners = {}
local turfCooldowns = {}
local rateLimits = {}

local function isRateLimited(src, key, limit, window)
    if not rateLimits[src] then rateLimits[src] = {} end
    local now = os.time()
    if not rateLimits[src][key] then rateLimits[src][key] = 0 end
    if now - rateLimits[src][key] < window then return true end
    rateLimits[src][key] = now
    return false
end

local function getPlayerGang(citizenid)
    local result = MySQL.single.await('SELECT gang, gang_grade FROM players WHERE citizenid = ?', { citizenid })
    return result
end

local function loadTurfOwners()
    local results = MySQL.query.await('SELECT * FROM turf_owners')
    for _, row in ipairs(results) do
        turfOwners[row.turf_id] = { gang = row.gang_name, influence = row.influence }
    end
end

local function saveTurfOwner(turfId, gangName, influence)
    MySQL.execute('INSERT INTO turf_owners (turf_id, gang_name, influence) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE gang_name = VALUES(gang_name), influence = VALUES(influence)', {
        turfId, gangName, influence
    })
end

local function getCaptureCount(turfId)
    if not activeCaptures[turfId] then return 0 end
    local count = 0
    for _, player in pairs(GetPlayers()) do
        if activeCaptures[turfId][player] then
            count = count + 1
        end
    end
    return count
end

RegisterNetEvent('turfs:server:startCapture', function(turfId)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'capture_start', 1, 5) then return end
    local gang = getPlayerGang(player.PlayerData.citizenid)
    if not gang or not gang.gang then
        return TriggerClientEvent('turfs:client:captureFailed', src, 'You are not in a gang')
    end
    local turf = nil
    for _, t in ipairs(Config.Turfs) do
        if t.id == turfId then turf = t end
    end
    if not turf then return end
    if turfCooldowns[turfId] and turfCooldowns[turfId] > os.time() then
        local remaining = turfCooldowns[turfId] - os.time()
        return TriggerClientEvent('turfs:client:captureFailed', src, 'Turf is on cooldown: ' .. math.ceil(remaining / 60) .. 'm')
    end
    if turfOwners[turfId] and turfOwners[turfId].gang == gang.gang then
        return TriggerClientEvent('turfs:client:captureFailed', src, 'Your gang already owns this turf')
    end
    if not activeCaptures[turfId] then
        activeCaptures[turfId] = {}
    end
    activeCaptures[turfId][src] = { progress = 0, gang = gang.gang }
    local count = getCaptureCount(turfId)
    if count >= Config.Capture.requiredPlayers then
        local policePlayers = QBox:GetPlayers()
        local policeCount = 0
        for _, pId in ipairs(policePlayers) do
            local p = QBox.Functions.GetPlayer(pId)
            if p and p.PlayerData.job.name == 'police' and p.PlayerData.job.onduty then
                policeCount = policeCount + 1
            end
        end
        if Config.Police.minPolice > policeCount then
            for pId, _ in pairs(activeCaptures[turfId]) do
                TriggerClientEvent('turfs:client:captureFailed', pId, 'Not enough police online')
            end
            activeCaptures[turfId] = nil
            return
        end
        if math.random() < Config.Police.alertChance then
            for _, pId in ipairs(policePlayers) do
                local p = QBox.Functions.GetPlayer(pId)
                if p and p.PlayerData.job.name == 'police' and p.PlayerData.job.onduty then
                    TriggerClientEvent('turfs:client:policeAlert', pId, turf.label)
                end
            end
        end
        Wrappers.Notify(src, 'Capturing ' .. turf.label, 'inform')
        Citizen.CreateThread(function()
            local totalTime = Config.Capture.duration * 1000
            local startTime = GetGameTimer()
            while activeCaptures[turfId] do
                local elapsed = GetGameTimer() - startTime
                local progress = (elapsed / totalTime) * 100
                if progress >= 100 then
                    local winningGang = nil
                    local gangProgress = {}
                    for pId, data in pairs(activeCaptures[turfId]) do
                        if not gangProgress[data.gang] then
                            gangProgress[data.gang] = 0
                        end
                        gangProgress[data.gang] = gangProgress[data.gang] + 1
                    end
                    local maxCount = 0
                    for g, c in pairs(gangProgress) do
                        if c > maxCount then
                            maxCount = c
                            winningGang = g
                        end
                    end
                    if winningGang then
                        local currentInfluence = 0
                        if turfOwners[turfId] then
                            currentInfluence = turfOwners[turfId].influence or 0
                        end
                        turfOwners[turfId] = { gang = winningGang, influence = Config.Capture.influencePerCapture + currentInfluence }
                        saveTurfOwner(turfId, winningGang, turfOwners[turfId].influence)
                        turfCooldowns[turfId] = os.time() + Config.Capture.cooldown
                        for pId, _ in pairs(activeCaptures[turfId]) do
                            TriggerClientEvent('turfs:client:captureProgress', pId, turfId, 100, 100)
                        end
                        exports['discord-logs']:sendLog('turf_captured', {
                            message = winningGang .. ' captured ' .. turf.label,
                            color = 'purple'
                        })
                    end
                    activeCaptures[turfId] = nil
                    return
                end
                for pId, data in pairs(activeCaptures[turfId]) do
                    local ped = GetPlayerPed(pId)
                    if not DoesEntityExist(ped) or #(GetEntityCoords(ped) - turf.coords) > Config.Capture.range then
                        TriggerClientEvent('turfs:client:captureFailed', pId, 'You left the capture zone')
                        activeCaptures[turfId][pId] = nil
                    else
                        TriggerClientEvent('turfs:client:captureProgress', pId, turfId, progress, 100)
                    end
                end
                if next(activeCaptures[turfId]) == nil then
                    activeCaptures[turfId] = nil
                    return
                end
                Citizen.Wait(1000)
            end
        end)
    else
        Wrappers.Notify(src, 'Need ' .. Config.Capture.requiredPlayers .. ' members to capture', 'inform')
    end
end)

RegisterNetEvent('turfs:server:stopCapture', function()
    local src = source
    for turfId, players in pairs(activeCaptures) do
        if players[src] then
            players[src] = nil
            if next(players) == nil then
                activeCaptures[turfId] = nil
            end
            break
        end
    end
end)

RegisterNetEvent('turfs:server:getTurfInfo', function(turfId)
    local src = source
    local turf = nil
    for _, t in ipairs(Config.Turfs) do
        if t.id == turfId then turf = t end
    end
    if not turf then return end
    local info = 'Turf: ' .. turf.label .. '\n'
    if turfOwners[turfId] then
        info = info .. 'Owner: ' .. turfOwners[turfId].gang .. '\nInfluence: ' .. turfOwners[turfId].influence
    else
        info = info .. 'Owner: None\nInfluence: 0'
    end
    TriggerClientEvent('turfs:client:turfInfo', src, info)
end)

QBox:CreateCallback('turfs:server:getTurfData', function(source, cb)
    cb(turfOwners)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        loadTurfOwners()
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    rateLimits[src] = nil
    for turfId, players in pairs(activeCaptures) do
        if players[src] then
            players[src] = nil
            if next(players) == nil then
                activeCaptures[turfId] = nil
            end
        end
    end
end)
