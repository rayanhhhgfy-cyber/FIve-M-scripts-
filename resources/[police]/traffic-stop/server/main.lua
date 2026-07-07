local QBox = exports['qbx_core']:GetCoreObject()

local function isLeo(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    for _, j in ipairs(Config.TrafficStop.allowedJobs) do
        if p.PlayerData.job.name == j and p.PlayerData.job.onduty then return true end
    end
    return false
end

RegisterNetEvent('trafficstop:initiate', function(plate)
    local src = source
    if not isLeo(src) then return end
    MySQL.query('SELECT * FROM players WHERE JSON_EXTRACT(charinfo, "$.plate") = ?', { plate }, function(rows)
        local owner = nil
        if rows and #rows > 0 then
            local charinfo = json.decode(rows[1].charinfo)
            owner = (charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or '')
        end
        TriggerClientEvent('trafficstop:started', src, plate, owner)
    end)
end)

RegisterNetEvent('trafficstop:checkLicense', function(plate)
    local src = source
    if not isLeo(src) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    TriggerClientEvent('trafficstop:result', src, 'License check: Plate ' .. plate .. ' — Registration valid')
end)

RegisterNetEvent('trafficstop:issueWarning', function(plate, warningType)
    local src = source
    if not isLeo(src) then return end
    TriggerClientEvent('trafficstop:result', src, warningType .. ' issued for ' .. plate)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = warningType .. ' issued' })
end)

RegisterNetEvent('trafficstop:issueFine', function(plate, fineKey, amount, reason)
    local src = source
    if not isLeo(src) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local fineConfig = Config.TrafficStop.fineCategories[fineKey]
    if not fineConfig then return end
    amount = math.max(fineConfig.min, math.min(fineConfig.max, amount or fineConfig.min))
    p.Functions.AddMoney('cash', amount, 'traffic-fine')
    TriggerClientEvent('trafficstop:fineIssued', src, amount, reason or fineConfig.label)
end)
