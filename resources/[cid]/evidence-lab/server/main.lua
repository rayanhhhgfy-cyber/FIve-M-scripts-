local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, a, m)
    local k = src .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

local results = { 'Positive', 'Negative', 'Inconclusive', 'Contaminated' }

RegisterNetEvent('evidence:server:analyze', function(typeId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not p.PlayerData.job.onduty then return end
    local tData = Config.EvidenceLab.AnalysisTypes[typeId]
    if not tData then return end
    local r = results[math.random(#results)]
    local detail = tData.label .. ': ' .. Config.EvidenceLab.ResultCategories[r].label
    MySQL.insert('INSERT INTO evidence_analysis (citizenid, type, result, timestamp) VALUES (?, ?, ?, ?)',
        { p.PlayerData.citizenid, typeId, r, os.time() })
    TriggerClientEvent('evidence:client:analysisResult', src, detail, r)
    exports['discord-logs']:LogCustom(src, 'Evidence Analysis', typeId .. ' -> ' .. r)
end)

RegisterNetEvent('evidence:server:takeEquipment', function(item)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not p.PlayerData.job.onduty then return end
    p.Functions.AddItem(item, 1)
    Wrappers.Notify(src, Locale('cid.equipment_taken'), 'success')
end)
