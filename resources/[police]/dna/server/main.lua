local QBox = exports['qbx-core']:GetCoreObject()
local dnaSamples = {}

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

RegisterNetEvent('dna:server:collect', function(targetId)
    local src = source
    if not checkRateLimit(src, 'dnaCollect', 20) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then
        Wrappers.Notify(src, Locale('police.not_on_duty'), 'error')
        return
    end
    local target = QBox.Functions.GetPlayer(targetId)
    if not target then
        Wrappers.Notify(src, Locale('police.player_not_found'), 'error')
        return
    end
    local sampleId = 'DNA-' .. math.random(100000, 999999) .. '-' .. os.time()
    dnaSamples[sampleId] = {
        id = sampleId,
        citizenid = target.PlayerData.citizenid,
        collectedBy = player.PlayerData.citizenid,
        analyzed = false,
        data = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname,
        timestamp = os.time()
    }
    MySQL.insert('INSERT INTO dna_samples (sample_id, citizenid, collected_by, data, analyzed, timestamp) VALUES (?, ?, ?, ?, ?, ?)',
        { sampleId, target.PlayerData.citizenid, player.PlayerData.citizenid, dnaSamples[sampleId].data, false, os.time() })
    TriggerClientEvent('dna:client:collectResult', src, sampleId)
    exports['discord-logs']:LogCustom(src, 'DNA Collected', 'Sample ' .. sampleId .. ' from ' .. target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname)
end)

RegisterNetEvent('dna:server:analyze', function(sampleId)
    local src = source
    if not checkRateLimit(src, 'dnaAnalyze', 20) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if not dnaSamples[sampleId] then
        MySQL.query('SELECT * FROM dna_samples WHERE sample_id = ?', { sampleId }, function(result)
            if result and #result > 0 then
                local row = result[1]
                dnaSamples[sampleId] = row
                dnaSamples[sampleId].analyzed = true
                MySQL.update('UPDATE dna_samples SET analyzed = ? WHERE sample_id = ?', { true, sampleId })
                local matchResult = Locale('police.dna_match', dnaSamples[sampleId].data, sampleId)
                TriggerClientEvent('dna:client:analysisResult', src, matchResult)
                exports['discord-logs']:LogCustom(src, 'DNA Analyzed', 'Sample ' .. sampleId)
            else
                Wrappers.Notify(src, Locale('police.dna_sample_not_found'), 'error')
            end
        end)
        return
    end
    dnaSamples[sampleId].analyzed = true
    MySQL.update('UPDATE dna_samples SET analyzed = ? WHERE sample_id = ?', { true, sampleId })
    local matchResult = Locale('police.dna_match', dnaSamples[sampleId].data, sampleId)
    TriggerClientEvent('dna:client:analysisResult', src, matchResult)
    exports['discord-logs']:LogCustom(src, 'DNA Analyzed', 'Sample ' .. sampleId)
end)

RegisterNetEvent('dna:server:getDatabase', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    MySQL.query('SELECT * FROM dna_samples ORDER BY timestamp DESC LIMIT 100', {}, function(result)
        local samples = {}
        if result then
            for _, row in ipairs(result) do
                table.insert(samples, { id = row.sample_id, citizenid = row.citizenid, analyzed = row.analyzed })
            end
        end
        TriggerClientEvent('dna:client:showDatabase', src, samples)
    end)
end)
